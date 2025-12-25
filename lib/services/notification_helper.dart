// lib/services/notification_helper.dart
// 🔔 Helper pour créer des notifications locales (en attendant Cloud Functions)

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer une notification lors de la création d'un examen
  static Future<void> createExamNotification({
    required String studentId,
    required String examId,
    required String examType,
    required String profName,
  }) async {
    try {
      String typeDisplay = examType == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': '📝 امتحان جديد',
        'message': 'تم إنشاء امتحان $typeDisplay لك من قبل الأستاذ $profName',
        'type': 'exam_created',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification examen créée');
    } catch (e) {
      print('❌ Erreur création notification: $e');
    }
  }

  /// Créer une notification lors de l'assignation d'un prof
  static Future<void> createAssignmentNotification({
    required String profId,
    required String studentName,
    required String examId,
    required String examType,
  }) async {
    try {
      String typeDisplay = examType == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      
      // Notification pour le prof
      await _firestore.collection('notifications').add({
        'userId': profId,
        'title': '👤 تم تعيينك لامتحان',
        'message': 'تم تعيينك لإجراء امتحان $typeDisplay للطالب $studentName',
        'type': 'exam_assigned',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification assignation créée');
    } catch (e) {
      print('❌ Erreur notification assignation: $e');
    }
  }

  /// Créer une notification lors de la publication d'un résultat
  static Future<void> createGradeNotification({
    required String studentId,
    required String examId,
    required String examType,
    required int grade,
  }) async {
    try {
      String typeDisplay = examType == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      bool isPassed = grade >= 15;
      
      String emoji = isPassed ? '🎉' : '📊';
      String title = isPassed ? '$emoji نتيجة ممتازة!' : '$emoji نتيجة الامتحان';
      
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': title,
        'message': 'حصلت على $grade/20 في امتحان $typeDisplay',
        'type': 'exam_graded',
        'examId': examId,
        'grade': grade,
        'isPassed': isPassed,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification résultat créée');
    } catch (e) {
      print('❌ Erreur notification résultat: $e');
    }
  }

  /// Créer une notification de rappel 24h avant
  static Future<void> createReminder24h({
    required String studentId,
    required String examId,
    required String examType,
    required DateTime examDate,
  }) async {
    try {
      String typeDisplay = examType == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      String time = '${examDate.hour.toString().padLeft(2, '0')}:${examDate.minute.toString().padLeft(2, '0')}';
      
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': '⏰ تذكير: امتحان غداً',
        'message': 'لديك امتحان $typeDisplay غداً الساعة $time',
        'type': 'exam_reminder_24h',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification rappel 24h créée');
    } catch (e) {
      print('❌ Erreur notification rappel: $e');
    }
  }

  /// Créer une notification de rappel 1h avant
  static Future<void> createReminder1h({
    required String studentId,
    required String examId,
    required String examType,
  }) async {
    try {
      String typeDisplay = examType == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': '🔔 امتحانك يبدأ قريباً!',
        'message': 'امتحان $typeDisplay سيبدأ خلال ساعة واحدة',
        'type': 'exam_reminder_1h',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification rappel 1h créée');
    } catch (e) {
      print('❌ Erreur notification rappel: $e');
    }
  }

  /// Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur marquage notification: $e');
    }
  }

  /// Marquer toutes les notifications d'un utilisateur comme lues
  static Future<void> markAllAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ ${snapshot.docs.length} notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur marquage toutes notifications: $e');
    }
  }

  /// Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification supprimée');
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  /// Supprimer toutes les notifications d'un utilisateur
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ ${snapshot.docs.length} notifications supprimées');
    } catch (e) {
      print('❌ Erreur suppression toutes notifications: $e');
    }
  }

  /// Récupérer le nombre de notifications non lues
  static Future<int> getUnreadCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur comptage notifications: $e');
      return 0;
    }
  }

  /// Stream des notifications d'un utilisateur
  static Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}