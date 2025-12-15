// lib/services/activity_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Enregistrer une nouvelle activité
  Future<void> logActivity({
    required String type,
    required String title,
    required String description,
    String? targetId,
    String? targetName,
  }) async {
    try {
      await _firestore.collection('activities').add({
        'type': type,
        'title': title,
        'description': description,
        'performedBy': _auth.currentUser?.uid,
        'targetId': targetId,
        'targetName': targetName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'activité: $e');
    }
  }

  /// Activité : Ajout d'un enseignant
  Future<void> logTeacherAdded(String teacherId, String teacherName) async {
    await logActivity(
      type: 'teacher_added',
      title: 'تم إضافة أستاذ جديد',
      description: 'الأستاذ: $teacherName',
      targetId: teacherId,
      targetName: teacherName,
    );
  }

  /// Activité : Modification d'un enseignant
  Future<void> logTeacherUpdated(String teacherId, String teacherName) async {
    await logActivity(
      type: 'teacher_updated',
      title: 'تم تحديث بيانات أستاذ',
      description: 'الأستاذ: $teacherName',
      targetId: teacherId,
      targetName: teacherName,
    );
  }

  /// Activité : Suppression d'un enseignant
  Future<void> logTeacherDeleted(String teacherId, String teacherName) async {
    await logActivity(
      type: 'teacher_deleted',
      title: 'تم حذف أستاذ',
      description: 'الأستاذ: $teacherName',
      targetId: teacherId,
      targetName: teacherName,
    );
  }

  /// Activité : Ajout d'un étudiant
  Future<void> logStudentAdded(String studentId, String studentName) async {
    await logActivity(
      type: 'student_added',
      title: 'تم إضافة طالب جديد',
      description: 'الطالب: $studentName',
      targetId: studentId,
      targetName: studentName,
    );
  }

  /// Activité : Modification d'un étudiant
  Future<void> logStudentUpdated(String studentId, String studentName) async {
    await logActivity(
      type: 'student_updated',
      title: 'تم تحديث بيانات طالب',
      description: 'الطالب: $studentName',
      targetId: studentId,
      targetName: studentName,
    );
  }

  /// Activité : Suppression d'un étudiant
  Future<void> logStudentDeleted(String studentId, String studentName) async {
    await logActivity(
      type: 'student_deleted',
      title: 'تم حذف طالب',
      description: 'الطالب: $studentName',
      targetId: studentId,
      targetName: studentName,
    );
  }

  /// Activité : Création d'un groupe
  Future<void> logGroupCreated(String groupId, String groupName) async {
    await logActivity(
      type: 'group_created',
      title: 'تم إنشاء مجموعة جديدة',
      description: 'المجموعة: $groupName',
      targetId: groupId,
      targetName: groupName,
    );
  }

  /// Activité : Modification d'un groupe
  Future<void> logGroupUpdated(String groupId, String groupName) async {
    await logActivity(
      type: 'group_updated',
      title: 'تم تحديث مجموعة',
      description: 'المجموعة: $groupName',
      targetId: groupId,
      targetName: groupName,
    );
  }

  /// Activité : Suppression d'un groupe
  Future<void> logGroupDeleted(String groupId, String groupName) async {
    await logActivity(
      type: 'group_deleted',
      title: 'تم حذف مجموعة',
      description: 'المجموعة: $groupName',
      targetId: groupId,
      targetName: groupName,
    );
  }

  /// Récupérer les activités récentes (limite)
  Stream<QuerySnapshot> getRecentActivities({int limit = 10}) {
    return _firestore
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Obtenir l'icône selon le type d'activité
  static IconData getIconForType(String type) {
    switch (type) {
      case 'teacher_added':
        return Icons.person_add;
      case 'teacher_updated':
        return Icons.person_outline;
      case 'teacher_deleted':
        return Icons.person_remove;
      case 'student_added':
        return Icons.school;
      case 'student_updated':
        return Icons.edit;
      case 'student_deleted':
        return Icons.person_off;
      case 'group_created':
        return Icons.group_add;
      case 'group_updated':
        return Icons.groups;
      case 'group_deleted':
        return Icons.group_remove;
      default:
        return Icons.info;
    }
  }

  /// Obtenir la couleur selon le type d'activité
  static Color getColorForType(String type) {
    if (type.contains('added') || type.contains('created')) {
      return Colors.green;
    } else if (type.contains('updated')) {
      return Colors.blue;
    } else if (type.contains('deleted')) {
      return Colors.red;
    }
    return Colors.grey;
  }
}