// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer une notification globale
  /// Cette notification sera automatiquement copiée dans user_notifications pour chaque utilisateur ciblé
  Future<String?> createNotification({
    required String title,
    required String message,
    required String type,
    required List<String> targetRoles,
    List<String>? targetUserIds,
    List<String>? targetGroupIds,
    String? relatedExamId,
    String? relatedRemarkId,
  }) async {
    try {
      // Récupérer l'utilisateur actuel
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String senderName = '${userData['firstName']} ${userData['lastName']}';

      // Créer la notification globale
      DocumentReference notifRef = await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'type': type,
        'targetRoles': targetRoles,
        'targetUserIds': targetUserIds,
        'targetGroupIds': targetGroupIds,
        'relatedExamId': relatedExamId,
        'relatedRemarkId': relatedRemarkId,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [], // Liste des UIDs qui ont lu
      });

      // Déterminer les utilisateurs ciblés
      List<String> targetedUserIds = await _getTargetedUsers(
        targetRoles: targetRoles,
        targetUserIds: targetUserIds,
        targetGroupIds: targetGroupIds,
      );

      // Créer une copie dans user_notifications pour chaque utilisateur ciblé
      WriteBatch batch = _firestore.batch();
      
      for (String userId in targetedUserIds) {
        DocumentReference userNotifRef = _firestore
            .collection('user_notifications')
            .doc(userId)
            .collection('notifications')
            .doc(notifRef.id);

        batch.set(userNotifRef, {
          'notificationRef': notifRef,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      print('✅ Notification créée et distribuée à ${targetedUserIds.length} utilisateurs');
      return notifRef.id;
    } catch (e) {
      print('❌ Erreur createNotification: $e');
      return null;
    }
  }

  /// Déterminer les utilisateurs ciblés selon les critères
  Future<List<String>> _getTargetedUsers({
    required List<String> targetRoles,
    List<String>? targetUserIds,
    List<String>? targetGroupIds,
  }) async {
    Set<String> userIds = {};

    // Si des IDs spécifiques sont fournis, les utiliser directement
    if (targetUserIds != null && targetUserIds.isNotEmpty) {
      userIds.addAll(targetUserIds);
      return userIds.toList();
    }

    // Sinon, filtrer par rôles
    for (String role in targetRoles) {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true);

      QuerySnapshot snapshot = await query.get();
      
      for (var doc in snapshot.docs) {
        // Si targetGroupIds est spécifié, filtrer aussi par groupe
        if (targetGroupIds != null && targetGroupIds.isNotEmpty) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (role == 'etudiant') {
            // Pour les étudiants, vérifier le groupId
            String? studentGroupId = data['groupId'];
            if (studentGroupId != null && targetGroupIds.contains(studentGroupId)) {
              userIds.add(doc.id);
            }
          } else if (role == 'prof') {
            // Pour les profs, vérifier si un de leurs groupes est ciblé
            List<dynamic>? profGroupIds = data['groupIds'];
            if (profGroupIds != null) {
              bool hasTargetedGroup = profGroupIds.any((gId) => targetGroupIds.contains(gId));
              if (hasTargetedGroup) {
                userIds.add(doc.id);
              }
            }
          } else {
            // Admin reçoit toutes les notifications
            userIds.add(doc.id);
          }
        } else {
          // Pas de filtre de groupe, ajouter tous les utilisateurs du rôle
          userIds.add(doc.id);
        }
      }
    }

    return userIds.toList();
  }

  /// Marquer une notification comme lue pour l'utilisateur actuel
  Future<void> markAsRead(String notificationId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Marquer dans user_notifications
      await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Ajouter l'UID dans readBy de la notification globale
      await _firestore.collection('notifications').doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId])
      });

      print('✅ Notification $notificationId marquée comme lue');
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
    }
  }

  /// Marquer toutes les notifications comme lues pour l'utilisateur actuel
  Future<void> markAllAsRead() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot unreadNotifs = await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in unreadNotifs.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour aussi la notification globale
        batch.update(
          _firestore.collection('notifications').doc(doc.id),
          {'readBy': FieldValue.arrayUnion([userId])}
        );
      }

      await batch.commit();
      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
    }
  }

  /// Stream des notifications de l'utilisateur actuel (avec statut lu/non-lu)
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('user_notifications')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> userNotifData = doc.data();
        
        // Récupérer la notification globale
        DocumentReference notifRef = userNotifData['notificationRef'];
        DocumentSnapshot notifSnap = await notifRef.get();
        
        if (notifSnap.exists) {
          Map<String, dynamic> notifData = notifSnap.data() as Map<String, dynamic>;
          
          notifications.add({
            'id': doc.id,
            'title': notifData['title'],
            'message': notifData['message'],
            'type': notifData['type'],
            'senderId': notifData['senderId'],
            'senderName': notifData['senderName'],
            'createdAt': notifData['createdAt'],
            'relatedExamId': notifData['relatedExamId'],
            'relatedRemarkId': notifData['relatedRemarkId'],
            'isRead': userNotifData['isRead'],
            'readAt': userNotifData['readAt'],
          });
        }
      }

      return notifications;
    });
  }

  /// Compter les notifications non lues
  Stream<int> getUnreadCountStream() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('user_notifications')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Supprimer une notification pour l'utilisateur actuel
  Future<void> deleteUserNotification(String notificationId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      print('✅ Notification supprimée');
    } catch (e) {
      print('❌ Erreur deleteUserNotification: $e');
    }
  }

  /// Notifications pour examens (raccourci)
  Future<void> notifyExamCreated({
    required String examId,
    required String studentId,
    required String studentName,
    required String type,
    required DateTime examDate,
  }) async {
    await createNotification(
      title: 'اختبار جديد',
      message: 'تم تخطيط اختبار $type للطالب $studentName بتاريخ ${examDate.toString().split(' ')[0]}',
      type: 'exam',
      targetRoles: ['admin'],
      relatedExamId: examId,
    );
  }

  /// Notification pour examen approuvé (vers prof assigné)
  Future<void> notifyExamApproved({
    required String examId,
    required String assignedProfId,
    required String studentName,
    required DateTime examDate,
  }) async {
    await createNotification(
      title: 'تم تعيينك لإجراء اختبار',
      message: 'تم تعيينك لإجراء اختبار للطالب $studentName بتاريخ ${examDate.toString().split(' ')[0]}',
      type: 'exam',
      targetRoles: ['prof'],
      targetUserIds: [assignedProfId],
      relatedExamId: examId,
    );
  }

  /// Notification annonce générale
  Future<void> sendAnnouncement({
    required String title,
    required String message,
    required List<String> targetRoles,
    List<String>? targetGroupIds,
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: 'announcement',
      targetRoles: targetRoles,
      targetGroupIds: targetGroupIds,
    );
  }
}