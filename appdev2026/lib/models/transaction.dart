import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category; // Manual tag
  final String aiCategory; // AI tag
  final String note;
  final Timestamp timestamp;
  final String monthKey;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.aiCategory,
    required this.note,
    required this.timestamp,
    required this.monthKey,
  });

  // Section divider
  // ADDED FOR AI HACKATHON INTEGRATION
  // Converts the Gemini JSON output into this model
  // Section divider
  factory TransactionModel.fromJson(
    Map<String, dynamic> json,
    String generatedId,
  ) {
    // 1. Grab the category the AI predicted
    final String predictedCategory = json['aiCategory'] as String? ?? 'General';

    return TransactionModel(
      id: generatedId,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      type: json['type']?.toString().toLowerCase() == 'income'
          ? 'income'
          : 'expense',

      // 2. Assign the AI's prediction to BOTH fields so it is never blank in Firebase
      category: predictedCategory,
      aiCategory: predictedCategory,

      note: json['note'] as String? ?? 'Quick Log',
      timestamp: Timestamp.now(),
      monthKey: _monthKeyFromTimestamp(Timestamp.now()),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'aiCategory': aiCategory,
      'note': note,
      'timestamp': timestamp,
      'monthKey': monthKey,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num? ?? 0).toDouble(),
      type: data['type'] as String? ?? 'expense',
      category: data['category'] as String? ?? '',
      aiCategory: data['aiCategory'] as String? ?? '',
      note: data['note'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      monthKey:
          data['monthKey'] as String? ??
          _monthKeyFromTimestamp(
            data['timestamp'] as Timestamp? ?? Timestamp.now(),
          ),
    );
  }

  static String _monthKeyFromTimestamp(Timestamp timestamp) {
    final DateTime value = timestamp.toDate();
    final String month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }
}
