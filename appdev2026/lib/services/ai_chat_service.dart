import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/transaction.dart';
import 'budget_firestore_service.dart';
import '../controllers/currency_controllers.dart'; // To get the right currency symbol!

class AiChatService {
  String get _apiKey {
    final String? key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }
    return key;
  }

  ChatSession? _chatSession;
  List<TransactionModel> _allTransactions = <TransactionModel>[];

  // 1. Initialize the chat with the user's live financial context
  Future<void> initializeChat({bool forceRefresh = false}) async {
    if (!forceRefresh && _chatSession != null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');

    final DateTime now = DateTime.now();

    // Load full transaction history for the current logged-in user.
    _allTransactions = await BudgetFirestoreService.instance
        .watchAllTransactions(user)
        .first;

    final double totalIncomeAllTime = _allTransactions
        .where((TransactionModel tx) => tx.type == 'income')
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );
    final double totalExpenseAllTime = _allTransactions
        .where((TransactionModel tx) => tx.type != 'income')
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );

    final double incomeThisMonth = _allTransactions
        .where(
          (TransactionModel tx) =>
              tx.type == 'income' &&
              tx.timestamp.toDate().year == now.year &&
              tx.timestamp.toDate().month == now.month,
        )
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );
    final double expenseThisMonth = _allTransactions
        .where(
          (TransactionModel tx) =>
              tx.type != 'income' &&
              tx.timestamp.toDate().year == now.year &&
              tx.timestamp.toDate().month == now.month,
        )
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );
    final double netThisMonth = incomeThisMonth - expenseThisMonth;

    final List<TransactionModel> recentTransactions = _allTransactions
        .take(120)
        .toList();
    final String transactionContext = recentTransactions
        .map((TransactionModel tx) {
          final DateTime date = tx.timestamp.toDate();
          final String category = tx.category.trim().isEmpty
              ? (tx.aiCategory.trim().isEmpty
                    ? 'General'
                    : tx.aiCategory.trim())
              : tx.category.trim();
          return '- ${date.toIso8601String().split('T').first} | ${tx.type} | ${tx.amount.toStringAsFixed(2)} | $category | ${tx.note.trim()}';
        })
        .join('\n');

    // Get the user's active currency symbol (e.g., Rs, $, €)
    final String symbol =
        CurrencyPreferenceController.instance.currentOption.symbol;

    // Inject the live data into the AI's brain
    final String systemInstruction =
        '''
      You are a witty, highly intelligent, and slightly sassy financial advisor. 
      You must answer using this user's REAL transaction history below.
      The amounts are already normalized to one base currency.

      Key totals:
      - All-time Income: $symbol${totalIncomeAllTime.toStringAsFixed(2)}
      - All-time Expenses: $symbol${totalExpenseAllTime.toStringAsFixed(2)}
      - This Month Income: $symbol${incomeThisMonth.toStringAsFixed(2)}
      - This Month Expenses: $symbol${expenseThisMonth.toStringAsFixed(2)}
      - This Month Net: $symbol${netThisMonth.toStringAsFixed(2)}

      Recent transactions (latest first, up to 120):
      $transactionContext
      
      If the user asks about "until now", "so far", "all time", or "overall", treat that as all-time history.
      If they ask "this month", use only current month transactions.
      Answer their questions based on this exact data. Keep your answers concise, practical, and conversational. 
      If they want to buy something they can't afford, playfully roast them. Do not use markdown tables.
    ''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    // Start the session (this keeps history in-memory automatically!)
    _chatSession = model.startChat();
  }

  // 2. Send a message to Gemini and return the string
  Future<String> sendMessage(String message) async {
    await initializeChat(forceRefresh: true);

    final String? deterministicAnswer = _buildDeterministicSpendAnswer(message);
    if (deterministicAnswer != null) {
      return deterministicAnswer;
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'I have no words.';
    } catch (e) {
      print('🔥 Chat Error: $e');
      return 'Sorry, my brain is taking a break right now. Try again in a second!';
    }
  }

  String? _buildDeterministicSpendAnswer(String question) {
    final String input = question.toLowerCase();

    final bool asksSpending =
        input.contains('how much') &&
        (input.contains('spend') ||
            input.contains('spent') ||
            input.contains('expense') ||
            input.contains('pay') ||
            input.contains('paid'));

    if (!asksSpending) {
      return null;
    }

    final bool thisMonth =
        input.contains('this month') || input.contains('current month');

    final DateTime now = DateTime.now();
    final Iterable<TransactionModel> expenseTransactions = _allTransactions
        .where((TransactionModel tx) => tx.type != 'income')
        .where((TransactionModel tx) {
          if (!thisMonth) {
            return true;
          }

          final DateTime date = tx.timestamp.toDate();
          return date.year == now.year && date.month == now.month;
        });

    String? matchedCategory;
    for (final TransactionModel tx in _allTransactions) {
      final List<String> candidates = <String>[
        tx.category.trim(),
        tx.aiCategory.trim(),
      ].where((String value) => value.isNotEmpty).toList();

      for (final String category in candidates) {
        final String normalized = category.toLowerCase();
        if (input.contains(normalized)) {
          matchedCategory = category;
          break;
        }
      }

      if (matchedCategory != null) {
        break;
      }
    }

    final Iterable<TransactionModel> filtered = matchedCategory == null
        ? expenseTransactions
        : expenseTransactions.where((TransactionModel tx) {
            final String category = tx.category.toLowerCase();
            final String aiCategory = tx.aiCategory.toLowerCase();
            final String note = tx.note.toLowerCase();
            final String target = matchedCategory!.toLowerCase();
            return category.contains(target) ||
                aiCategory.contains(target) ||
                note.contains(target);
          });

    final double total = filtered.fold<double>(
      0,
      (double value, TransactionModel tx) => value + tx.amount,
    );

    final String symbol =
        CurrencyPreferenceController.instance.currentOption.symbol;
    final String periodLabel = thisMonth ? 'this month' : 'until now';

    if (matchedCategory != null) {
      return 'You spent $symbol${total.toStringAsFixed(2)} on ${matchedCategory.toLowerCase()} $periodLabel.';
    }

    return 'You spent $symbol${total.toStringAsFixed(2)} in total $periodLabel.';
  }
}
