// lib/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'general', 'exam', 'announcement', 'remark_response'
  final List<String> targetRoles; // ['admin', 'prof', 'etudiant']
  final List<String>? targetUserIds; // IDs spécifiques (null = tous)
  final List<String>? targetGroupIds; // Groupes spécifiques
  final String? relatedExamId; // Si lié à un examen
  final String? relatedRemarkId; // Si lié à une remarque
  final String senderId; // Qui a envoyé
  final String senderName;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetRoles,
    this.targetUserIds,
    this.targetGroupIds,
    this.relatedExamId,
    this.relatedRemarkId,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      targetRoles: List<String>.from(data['targetRoles'] ?? []),
      targetUserIds: data['targetUserIds'] != null 
          ? List<String>.from(data['targetUserIds']) 
          : null,
      targetGroupIds: data['targetGroupIds'] != null 
          ? List<String>.from(data['targetGroupIds']) 
          : null,
      relatedExamId: data['relatedExamId'],
      relatedRemarkId: data['relatedRemarkId'],
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetRoles': targetRoles,
      'targetUserIds': targetUserIds,
      'targetGroupIds': targetGroupIds,
      'relatedExamId': relatedExamId,
      'relatedRemarkId': relatedRemarkId,
      'senderId': senderId,
      'senderName': senderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    List<String>? targetGroupIds,
    String? relatedExamId,
    String? relatedRemarkId,
    String? senderId,
    String? senderName,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetRoles: targetRoles ?? this.targetRoles,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      relatedExamId: relatedExamId ?? this.relatedExamId,
      relatedRemarkId: relatedRemarkId ?? this.relatedRemarkId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}