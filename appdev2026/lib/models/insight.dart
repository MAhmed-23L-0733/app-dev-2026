import 'package:cloud_firestore/cloud_firestore.dart';

class InsightModel {
  final String id;
  final String content;
  final Timestamp generatedAt;

  InsightModel({
    required this.id,
    required this.content,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {'content': content, 'generatedAt': generatedAt};
  }

  factory InsightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsightModel(
      id: doc.id,
      content: data['content'] ?? '',
      generatedAt: data['generatedAt'] as Timestamp,
    );
  }
}
