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
    final Map<String, dynamic> data =
        (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return InsightModel(
      id: doc.id,
      content: data['content'] as String? ?? '',
      generatedAt: data['generatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
