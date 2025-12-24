// lib/models/exam_model.dart
// ✅ VERSION FINALE CORRIGÉE

import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String id;
  final String studentId;
  final String studentName;
  final String? groupId;
  final String? groupName;
  final String createdByProfId;
  final String createdByProfName;
  final String? assignedProfId;
  final String? assignedProfName;
  final String type; // "5ahzab" ou "10ahzab"
  final DateTime? examDate; // ✅ NULLABLE pour 10 ahzab en attente
  final String status; // "pending", "approved", "completed", "graded"
  final int? grade; // 0-20
  final int? score; // Alias pour grade (compatibilité)
  final String? notes;
  final String? feedback; // Commentaires du prof
  final DateTime? createdAt; // ✅ NULLABLE
  final DateTime? completedAt;

  ExamModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.groupId,
    this.groupName,
    required this.createdByProfId,
    required this.createdByProfName,
    this.assignedProfId,
    this.assignedProfName,
    required this.type,
    this.examDate, // ✅ NULLABLE
    required this.status,
    this.grade,
    int? score,
    this.notes,
    this.feedback,
    this.createdAt, // ✅ NULLABLE
    this.completedAt,
  }) : score = score ?? grade;

  factory ExamModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ExamModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      groupId: data['groupId'],
      groupName: data['groupName'],
      createdByProfId: data['createdByProfId'] ?? '',
      createdByProfName: data['createdByProfName'] ?? '',
      assignedProfId: data['assignedProfId'],
      assignedProfName: data['assignedProfName'],
      type: data['type'] ?? '5ahzab',
      // ✅ CORRIGÉ : examDate peut être null
      examDate: data['examDate'] != null 
          ? (data['examDate'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'pending',
      grade: data['grade'] ?? data['score'],
      score: data['score'] ?? data['grade'],
      notes: data['notes'],
      feedback: data['feedback'],
      // ✅ CORRIGÉ : createdAt peut être null
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'groupId': groupId,
      'groupName': groupName,
      'createdByProfId': createdByProfId,
      'createdByProfName': createdByProfName,
      'assignedProfId': assignedProfId,
      'assignedProfName': assignedProfName,
      'type': type,
      'examDate': examDate != null ? Timestamp.fromDate(examDate!) : null,
      'status': status,
      'grade': grade,
      'score': score,
      'notes': notes,
      'feedback': feedback,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  String get typeDisplay => type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
  
  String get statusDisplay {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'approved': return 'تمت الموافقة';
      case 'completed': return 'مكتمل';
      case 'graded': return 'تم التقييم';
      default: return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isGraded => status == 'graded';
}