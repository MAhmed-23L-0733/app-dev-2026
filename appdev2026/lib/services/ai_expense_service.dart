import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for Uint8List
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'budget_firestore_service.dart';

// ⚠️ IMPORTANT: Make sure this path points to where you saved your CurrencyPreferenceController!
import '../controllers/currency_controllers.dart';

class AiExpenseService {
  static bool _isLoggingTransaction = false;
  static bool _isParsingReceipt = false;

  String get _apiKey {
    final String? key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }
    return key;
  }

  // Centralized prompt for BOTH text and images
  final String _systemPrompt = '''
    You are an AI for a smart expense tracker. Analyze the provided input (either text or an image of a document).
    Extract the transaction details and return ONLY a valid JSON object with these exact keys:
    - "note" (String: merchant name or a short description. If it is a refund, prefix with "Refund: ")
    - "amount" (Number: the total cost or income, strictly as a positive number)
    - "aiCategory" (String: Categorize this logically, e.g., Food, Transport, Utilities, Entertainment, Salary, Shopping, Refunds)
    - "type" (String: strictly either "expense" or "income")
    - "sourceCurrencyCode" (String: one of USD, EUR, GBP, INR, PKR, AED. This is the currency in which the amount appears in the user text/receipt. If not explicit, infer from symbols/keywords. If still unknown, use the provided selected currency.)

    CRITICAL CLASSIFICATION RULES:
    1. EXPENSE: Standard store receipts, restaurant bills, utility invoices, ride-shares, or anytime the user pays money.
    2. INCOME: Pay stubs, bank deposits, salary, or anytime the user is receiving money.
    3. REFUNDS & RETURNS: If the document is a return receipt or explicitly shows a refunded amount, classify it as "income" (because money is returning to the user's pocket) and set the aiCategory to "Refunds".
    ''';

  // ==========================================
  // 1. Text Logging Method (Used on Home Screen)
  // ==========================================
  Future<void> logExpenseFromText(String userInput) async {
    final String selectedCurrency =
        CurrencyPreferenceController.instance.currentCode;
    final content = [
      Content.text(
        '$_systemPrompt\n\nSelected Currency: "$selectedCurrency"\n\nUser Input: "$userInput"',
      ),
    ];
    await _processAndSave(content, rawText: userInput);
  }

  // ==========================================
  // 2. Image Logging Method (Used on Home Screen)
  // ==========================================
  Future<void> logExpenseFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final String selectedCurrency =
        CurrencyPreferenceController.instance.currentCode;
    final content = [
      Content.multi([
        TextPart('$_systemPrompt\n\nSelected Currency: "$selectedCurrency"'),
        DataPart(mimeType, imageBytes),
      ]),
    ];
    await _processAndSave(content);
  }

  // ==========================================
  // 3. Shared Logic for Gemini & Firestore
  // ==========================================
  Future<void> _processAndSave(List<Content> content, {String? rawText}) async {
    if (_isLoggingTransaction) {
      throw Exception('Please wait for the current AI request to finish.');
    }

    _isLoggingTransaction = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be signed in.');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent(content);
      String? responseText = response.text;

      if (responseText != null) {
        // Clean markdown formatting if Gemini adds it
        responseText = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> jsonMap = jsonDecode(responseText);

        final double amount = (jsonMap['amount'] as num? ?? 0).toDouble();
        final String type =
            jsonMap['type']?.toString().toLowerCase() == 'income'
            ? 'income'
            : 'expense';
        final String category = jsonMap['aiCategory'] as String? ?? 'General';
        final String note = jsonMap['note'] as String? ?? 'Quick Log';

        // 🟢 Fetch the globally selected currency code from your controller
        final String activeCurrency =
            CurrencyPreferenceController.instance.currentCode;
        final String sourceCurrencyFromAi =
            (jsonMap['sourceCurrencyCode'] as String? ?? '')
                .trim()
                .toUpperCase();
        final String? sourceCurrencyFromText = rawText == null
            ? null
            : _detectCurrencyCodeFromText(rawText);
        final String saveCurrency = _isSupportedCurrency(sourceCurrencyFromAi)
            ? sourceCurrencyFromAi
            : sourceCurrencyFromText ?? activeCurrency;

        // Save through Budget service to update the dashboard totals!
        await BudgetFirestoreService.instance.addTransaction(
          user: user,
          amount: amount,
          type: type,
          category: category,
          note: note,
          currencyCode: saveCurrency,
        );
      } else {
        throw Exception('AI returned an empty response.');
      }
    } catch (e) {
      print('🔥 FATAL AI ERROR: $e');
      throw Exception(e.toString());
    } finally {
      _isLoggingTransaction = false;
    }
  }

  // ==========================================
  // 4. Parse Data Method (Used on Add Transaction Screen)
  // ==========================================
  Future<Map<String, dynamic>> parseReceiptData(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    if (_isParsingReceipt) {
      throw Exception('Please wait for the current receipt scan to finish.');
    }

    _isParsingReceipt = true;

    try {
      final String selectedCurrency =
          CurrencyPreferenceController.instance.currentCode;
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([
        Content.multi([
          TextPart(
            '$_systemPrompt\n\nSelected Currency: "$selectedCurrency"\n\nFor this parsing call, make "note" a detailed but concise description (about 1-2 sentences) including merchant, likely purchased items/services, and useful context for transaction history.',
          ),
          DataPart(mimeType, imageBytes),
        ]),
      ]);

      String? responseText = response.text;
      if (responseText != null) {
        responseText = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(responseText);
      }
      throw Exception('AI returned an empty response.');
    } finally {
      _isParsingReceipt = false;
    }
  }

  bool _isSupportedCurrency(String code) {
    return CurrencyPreferenceController.options.any(
      (CurrencyOption option) => option.code == code,
    );
  }

  String? _detectCurrencyCodeFromText(String text) {
    final String value = text.toLowerCase();

    if (value.contains('usd') ||
        value.contains('dollar') ||
        value.contains(r'$')) {
      return 'USD';
    }
    if (value.contains('eur') ||
        value.contains('euro') ||
        value.contains('€')) {
      return 'EUR';
    }
    if (value.contains('gbp') ||
        value.contains('pound') ||
        value.contains('£')) {
      return 'GBP';
    }
    if (value.contains('aed') ||
        value.contains('dirham') ||
        value.contains('د.إ')) {
      return 'AED';
    }
    if (value.contains('inr') ||
        value.contains('rupee') ||
        value.contains('₹')) {
      return 'INR';
    }
    if (value.contains('pkr') ||
        value.contains('rs ') ||
        value.endsWith(' rs')) {
      return 'PKR';
    }

    return null;
  }
}
