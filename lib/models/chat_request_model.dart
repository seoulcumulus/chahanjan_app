import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRequest {
  final String id;
  final String fromId;
  final String toId;
  final String type; // 'poke' or 'chat'
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  ChatRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory ChatRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRequest(
      id: doc.id,
      fromId: data['fromId'] ?? '',
      toId: data['toId'] ?? '',
      type: data['type'] ?? 'poke',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
