import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final Timestamp deadline;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline,
    };
  }

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return GoalModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      targetAmount: (data['targetAmount'] as num? ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0).toDouble(),
      deadline: data['deadline'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
