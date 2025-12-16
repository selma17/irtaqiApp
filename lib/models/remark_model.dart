// lib/models/remark_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RemarkModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // "etudiant" ou "prof"
  final String message;
  final String status; // "new" | "open" | "closed"
  final DateTime createdAt;
  final List<String> readBy;
  final String? adminResponse;
  final DateTime? respondedAt;

  RemarkModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.status = 'new',
    required this.createdAt,
    this.readBy = const [],
    this.adminResponse,
    this.respondedAt,
  });

  factory RemarkModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RemarkModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'etudiant',
      message: data['message'] ?? '',
      status: data['status'] ?? 'new',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
      adminResponse: data['adminResponse'],
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // Getters utiles
  bool get isNew => status == 'new';
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;
}