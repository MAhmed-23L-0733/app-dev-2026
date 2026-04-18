import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category; // Manual tag
  final String aiCategory; // AI tag
  final String note;
  final Timestamp timestamp;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.aiCategory,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'aiCategory': aiCategory,
      'note': note,
      'timestamp': timestamp,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'expense',
      category: data['category'] ?? '',
      aiCategory: data['aiCategory'] ?? '',
      note: data['note'] ?? '',
      timestamp: data['timestamp'] as Timestamp,
    );
  }
}
