// lib/models/remark_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RemarkModel {
  final String id;
  final String senderId; // Prof ID
  final String senderName;
  final String senderRole; // 'prof' ou 'etudiant' (pour futur)
  final String subject; // Titre/Sujet
  final String message;
  final String status; // 'open' (ouvert), 'in_progress' (en cours), 'closed' (fermé)
  final String? adminResponse;
  final String? respondedByAdminId;
  final String? respondedByAdminName;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String priority; // 'low', 'medium', 'high'

  RemarkModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'prof',
    required this.subject,
    required this.message,
    this.status = 'open',
    this.adminResponse,
    this.respondedByAdminId,
    this.respondedByAdminName,
    required this.createdAt,
    this.respondedAt,
    this.priority = 'medium',
  });

  factory RemarkModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RemarkModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'prof',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'open',
      adminResponse: data['adminResponse'],
      respondedByAdminId: data['respondedByAdminId'],
      respondedByAdminName: data['respondedByAdminName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      priority: data['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'subject': subject,
      'message': message,
      'status': status,
      'adminResponse': adminResponse,
      'respondedByAdminId': respondedByAdminId,
      'respondedByAdminName': respondedByAdminName,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'priority': priority,
    };
  }

  // Getters utiles
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isClosed => status == 'closed';
  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;

  String get statusText {
    switch (status) {
      case 'open':
        return 'مفتوح';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'closed':
        return 'مغلق';
      default:
        return 'غير معروف';
    }
  }

  String get priorityText {
    switch (priority) {
      case 'high':
        return 'عالية';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return 'متوسطة';
    }
  }

  RemarkModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? subject,
    String? message,
    String? status,
    String? adminResponse,
    String? respondedByAdminId,
    String? respondedByAdminName,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? priority,
  }) {
    return RemarkModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedByAdminId: respondedByAdminId ?? this.respondedByAdminId,
      respondedByAdminName: respondedByAdminName ?? this.respondedByAdminName,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      priority: priority ?? this.priority,
    );
  }
}