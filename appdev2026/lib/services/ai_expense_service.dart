import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added for Uint8List
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'budget_firestore_service.dart'; // Added to update the dashboard totals

class AiExpenseService {
  // ⚠️ Your API Key
  static const String _apiKey = 'AIzaSyD8_oG-TDtWx6AdDE0xshx6sqdOEi0wdQw';

  // Centralized prompt for BOTH text and images
  final String _systemPrompt = '''
    You are an AI for a smart expense tracker. Analyze the provided input (either text or an image of a receipt).
    Extract the transaction details and return ONLY a valid JSON object with these exact keys:
    - "note" (String: merchant name or a short description of what was bought/earned)
    - "amount" (Number: the total cost or income, positive number)
    - "aiCategory" (String: Categorize this logically, e.g., Food, Transport, Utilities, Entertainment, Salary, Shopping)
    - "type" (String: strictly either "expense" or "income")
    ''';

  // 1. Text Logging Method
  Future<void> logExpenseFromText(String userInput) async {
    final content = [
      Content.text('$_systemPrompt\n\nUser Input: "$userInput"'),
    ];
    await _processAndSave(content);
  }

  // 2. NEW: Receipt Scanning (Image) Method
  Future<void> logExpenseFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final content = [
      Content.multi([TextPart(_systemPrompt), DataPart(mimeType, imageBytes)]),
    ];
    await _processAndSave(content);
  }

  // 3. Shared Logic for Gemini & Firestore
  Future<void> _processAndSave(List<Content> content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be signed in.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    try {
      // Ask Gemini to parse the content
      final response = await model.generateContent(content);
      String? responseText = response.text;

      if (responseText != null) {
        // Clean markdown formatting if Gemini adds it
        responseText = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // Convert the string into a Dart Map
        final Map<String, dynamic> jsonMap = jsonDecode(responseText);

        final double amount = (jsonMap['amount'] as num? ?? 0).toDouble();
        final String type =
            jsonMap['type']?.toString().toLowerCase() == 'income'
            ? 'income'
            : 'expense';
        final String category = jsonMap['aiCategory'] as String? ?? 'General';
        final String note = jsonMap['note'] as String? ?? 'Quick Log';

        // 🔥 CRITICAL FIX: Use your Budget service so the dashboard totals update instantly!
        await BudgetFirestoreService.instance.addTransaction(
          user: user,
          amount: amount,
          type: type,
          category: category,
          note: note,
        );
      } else {
        throw Exception('AI returned an empty response.');
      }
    } catch (e) {
      print('🔥 FATAL AI ERROR: $e');
      throw Exception(e.toString());
    }
  }

  // NEW: Parses an image and returns the raw data for auto-filling forms
  Future<Map<String, dynamic>> parseReceiptData(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final response = await model.generateContent([
      Content.multi([TextPart(_systemPrompt), DataPart(mimeType, imageBytes)]),
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
  }
}
