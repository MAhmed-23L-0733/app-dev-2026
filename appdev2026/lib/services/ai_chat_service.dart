import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import 'budget_firestore_service.dart';
import '../controllers/currency_controllers.dart'; // To get the right currency symbol!

class AiChatService {
  static bool _isSendingMessage = false;
  Future<void>? _initializeChatFuture;
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const List<String> _fallbackModels = [
    'openrouter/free',
    'nvidia/nemotron-super-49b-v1:free',
    'google/gemma-3-27b-it:free',
    'google/gemma-3-12b-it:free',
    'meta-llama/llama-3.3-70b-instruct:free',
  ];
  static const int _maxConversationMessages = 20;

  static const Set<String> _spendingStopWords = <String>{
    'a',
    'about',
    'all',
    'am',
    'an',
    'and',
    'can',
    'cost',
    'current',
    'did',
    'do',
    'does',
    'expense',
    'expenses',
    'for',
    'have',
    'how',
    'i',
    'in',
    'is',
    'it',
    'month',
    'much',
    'my',
    'now',
    'of',
    'on',
    'paid',
    'pay',
    'right',
    'show',
    'so',
    'spend',
    'spending',
    'spent',
    'tell',
    'that',
    'the',
    'this',
    'til',
    'to',
    'today',
    'total',
    'until',
    'up',
    'what',
  };

  String get _openRouterApiKey {
    final String? key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Missing OPENROUTER_API_KEY in .env');
    }
    return key;
  }

  String get _openRouterModel {
    final String? model = dotenv.env['OPENROUTER_MODEL'];
    if (model == null || model.trim().isEmpty) {
      return 'deepseek/deepseek-v3:free';
    }

    return model.trim();
  }

  String? _systemInstruction;
  final List<Map<String, String>> _conversation = <Map<String, String>>[];
  List<TransactionModel> _allTransactions = <TransactionModel>[];

  // 1. Initialize the chat with the user's live financial context
  Future<void> initializeChat({bool forceRefresh = false}) async {
    if (!forceRefresh && _systemInstruction != null) {
      return;
    }

    if (!forceRefresh && _initializeChatFuture != null) {
      return _initializeChatFuture!;
    }

    if (forceRefresh) {
      _initializeChatFuture = null;
    }

    late final Future<void> initialization;
    initialization = _initializeChat().catchError((Object error) {
      if (!forceRefresh) {
        _initializeChatFuture = null;
      }
      throw error;
    });
    if (!forceRefresh) {
      _initializeChatFuture = initialization;
    }

    return initialization;
  }

  Future<void> _initializeChat() async {
    await _refreshTransactionCache();

    final DateTime now = DateTime.now();

    final String activeCurrencyCode =
        CurrencyPreferenceController.instance.currentCode;
    final String symbol =
        CurrencyPreferenceController.instance.currentOption.symbol;

    final double totalIncomeAllTimeBase = _allTransactions
        .where((TransactionModel tx) => tx.type == 'income')
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );
    final double totalExpenseAllTimeBase = _allTransactions
        .where((TransactionModel tx) => tx.type != 'income')
        .fold<double>(
          0,
          (double total, TransactionModel tx) => total + tx.amount,
        );

    final double incomeThisMonthBase = _allTransactions
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
    final double expenseThisMonthBase = _allTransactions
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
    final double totalIncomeAllTime = CurrencyPreferenceController.instance
        .fromBaseAmount(totalIncomeAllTimeBase, activeCurrencyCode);
    final double totalExpenseAllTime = CurrencyPreferenceController.instance
        .fromBaseAmount(totalExpenseAllTimeBase, activeCurrencyCode);
    final double incomeThisMonth = CurrencyPreferenceController.instance
        .fromBaseAmount(incomeThisMonthBase, activeCurrencyCode);
    final double expenseThisMonth = CurrencyPreferenceController.instance
        .fromBaseAmount(expenseThisMonthBase, activeCurrencyCode);
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
          final double convertedAmount = CurrencyPreferenceController.instance
              .fromBaseAmount(tx.amount, activeCurrencyCode);
          return '- ${date.toIso8601String().split('T').first} | ${tx.type} | $symbol${convertedAmount.toStringAsFixed(2)} | $category | ${tx.note.trim()}';
        })
        .join('\n');

    // Inject the live data into the AI's brain
    final String systemInstruction =
        '''
      You are a witty, highly intelligent, and slightly sassy financial advisor. 
      You must answer using this user's REAL transaction history below.
      All listed amounts are already converted to the user's currently selected currency: $activeCurrencyCode.

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

    _systemInstruction = systemInstruction;
    _conversation
      ..clear()
      ..add(<String, String>{'role': 'system', 'content': systemInstruction});
  }

  // 2. Send a message to Gemini and return the string
  Future<String> sendMessage(String message) async {
    if (_isSendingMessage) {
      return 'Hold up, I’m still answering the last question.';
    }

    _isSendingMessage = true;

    try {
      await initializeChat();
      await _refreshTransactionCache();

      final String? deterministicAnswer = _buildDeterministicSpendAnswer(
        message,
      );
      if (deterministicAnswer != null) {
        _appendConversation('user', message);
        _appendConversation('assistant', deterministicAnswer);
        return deterministicAnswer;
      }

      final List<Map<String, String>> requestMessages = <Map<String, String>>[
        ..._conversation,
        <String, String>{'role': 'user', 'content': message},
      ];

      final String assistantText = await _callOpenRouter(requestMessages);

      _appendConversation('user', message);
      _appendConversation('assistant', assistantText);
      return assistantText;
    } catch (e) {
      print('🔥 Chat Error: $e');
      return 'Sorry, my brain is taking a break right now. Try again in a second!';
    } finally {
      _isSendingMessage = false;
    }
  }

  // Temporary diagnostic helper to verify OpenRouter connectivity.
  Future<void> testConnection() async {
    print('🧪 Testing OpenRouter connection...');
    final String key = _openRouterApiKey;
    final int previewLength = key.length < 15 ? key.length : 15;
    print('🔑 Key: ${key.substring(0, previewLength)}...');
    print('🤖 Model: $_openRouterModel');

    try {
      final http.Response response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://localhost',
          'X-Title': 'ExpenseTracker',
        },
        body: jsonEncode(<String, dynamic>{
          'model': 'openrouter/free',
          'messages': <Map<String, String>>[
            <String, String>{'role': 'user', 'content': 'Say hi in one word.'},
          ],
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<String> _callOpenRouter(
    List<Map<String, String>> requestMessages,
  ) async {
    final List<String> modelsToTry = <String>[
      _openRouterModel,
      ..._fallbackModels.where((String model) => model != _openRouterModel),
    ];

    for (final String model in modelsToTry) {
      try {
        final http.Response response = await http.post(
          Uri.parse(_openRouterUrl),
          headers: <String, String>{
            'Authorization': 'Bearer $_openRouterApiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://localhost',
            'X-Title': 'ExpenseTracker',
          },
          body: jsonEncode(<String, dynamic>{
            'model': model,
            'messages': requestMessages,
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 503 || response.statusCode == 429) {
          print(
            'WARN: Model $model failed (${response.statusCode}), trying next...',
          );
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'OpenRouter error ${response.statusCode}: ${response.body}',
          );
        }

        final Map<String, dynamic> decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> choices =
            (decoded['choices'] as List<dynamic>? ?? <dynamic>[]);

        if (choices.isEmpty) {
          continue;
        }

        final Map<String, dynamic> firstChoice =
            choices.first as Map<String, dynamic>;
        final Map<String, dynamic> assistantMessage =
            firstChoice['message'] as Map<String, dynamic>? ??
            <String, dynamic>{};

        final String text = _extractAssistantText(assistantMessage['content']);
        if (text.trim().isEmpty) {
          continue;
        }

        print('INFO: Got response from model: $model');
        return text;
      } catch (e) {
        print('WARN: Model $model threw: $e');
        continue;
      }
    }

    throw Exception('All models failed or returned empty responses.');
  }

  String? _buildDeterministicSpendAnswer(String question) {
    final String input = question.toLowerCase();

    final bool asksSpending =
        input.contains('how much') ||
        input.contains('spent') ||
        input.contains('spend') ||
        input.contains('expense') ||
        input.contains('expenses') ||
        input.contains('cost') ||
        input.contains('total');

    if (!asksSpending) {
      return null;
    }

    final bool thisMonth =
        input.contains('this month') || input.contains('current month');

    final String? topic = _extractSpendingTopic(input);

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

    final Iterable<TransactionModel> filtered = topic == null
        ? expenseTransactions
        : expenseTransactions.where((TransactionModel tx) {
            final String category = tx.category.toLowerCase();
            final String aiCategory = tx.aiCategory.toLowerCase();
            final String note = tx.note.toLowerCase();
            final String target = topic;
            return category.contains(target) ||
                aiCategory.contains(target) ||
                note.contains(target);
          });

    final double totalBase = filtered.fold<double>(
      0,
      (double value, TransactionModel tx) => value + tx.amount,
    );
    final String activeCurrencyCode =
        CurrencyPreferenceController.instance.currentCode;
    final double total = CurrencyPreferenceController.instance.fromBaseAmount(
      totalBase,
      activeCurrencyCode,
    );

    final String symbol =
        CurrencyPreferenceController.instance.currentOption.symbol;
    final String periodLabel = thisMonth ? 'this month' : 'until now';

    if (topic != null) {
      return 'You spent $symbol${total.toStringAsFixed(2)} on $topic $periodLabel.';
    }

    return 'You spent $symbol${total.toStringAsFixed(2)} in total $periodLabel.';
  }

  String? _extractSpendingTopic(String input) {
    final List<String> tokens = input
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String token) => token.length >= 3)
        .where((String token) => !_spendingStopWords.contains(token))
        .toList();

    if (tokens.isEmpty) {
      return null;
    }

    if (tokens.contains('fuel') ||
        tokens.contains('gas') ||
        tokens.contains('petrol') ||
        tokens.contains('diesel')) {
      return 'fuel';
    }

    for (final String token in tokens) {
      final bool found = _allTransactions.any((TransactionModel tx) {
        final String category = tx.category.toLowerCase();
        final String aiCategory = tx.aiCategory.toLowerCase();
        final String note = tx.note.toLowerCase();
        return category.contains(token) ||
            aiCategory.contains(token) ||
            note.contains(token);
      });

      if (found) {
        return token;
      }
    }

    return null;
  }

  Future<void> _refreshTransactionCache() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    _allTransactions = await BudgetFirestoreService.instance
        .watchAllTransactions(user)
        .first;
  }

  void _appendConversation(String role, String content) {
    _conversation.add(<String, String>{'role': role, 'content': content});

    // Keep the system message and trim older user/assistant turns.
    if (_conversation.length > _maxConversationMessages + 1) {
      _conversation.removeRange(
        1,
        _conversation.length - _maxConversationMessages,
      );
    }
  }

  String _extractAssistantText(dynamic content) {
    if (content is String) {
      return content;
    }

    if (content is List<dynamic>) {
      final StringBuffer buffer = StringBuffer();
      for (final dynamic item in content) {
        if (item is Map<String, dynamic>) {
          final dynamic text = item['text'];
          if (text is String && text.isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.write('\n');
            }
            buffer.write(text);
          }
        }
      }
      return buffer.toString();
    }

    return '';
  }
}
