// lib/services/announcement_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer une nouvelle annonce
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required String targetAudience, // "all", "teachers", "students", "specific_group"
    String? targetGroupId,
    String? imageUrl,
    List<String>? fileUrls,
  }) async {
    try {
      // ✅ NOUVEAU : Si c'est un groupe spécifique, récupérer prof + étudiants
      List<String> targetUserIds = [];
      
      if (targetAudience == 'specific_group' && targetGroupId != null) {
        // Récupérer le groupe
        DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(targetGroupId).get();
        
        if (groupDoc.exists) {
          Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
          
          // Ajouter le prof
          String profId = groupData['profId'];
          targetUserIds.add(profId);
          
          // Ajouter tous les étudiants
          List<String> studentIds = List<String>.from(groupData['studentIds'] ?? []);
          targetUserIds.addAll(studentIds);
        }
      }

      await _firestore.collection('announcements').add({
        'title': title,
        'content': content,
        'targetAudience': targetAudience,
        'targetGroupId': targetGroupId,
        'targetUserIds': targetUserIds, // ✅ NOUVEAU : Liste des IDs concernés
        'imageUrl': imageUrl,
        'fileUrls': fileUrls ?? [],
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'viewedBy': [],
      });

      return true;
    } catch (e) {
      print('Erreur createAnnouncement: $e');
      return false;
    }
  }

  /// Obtenir toutes les annonces (pour admin)
  Stream<QuerySnapshot> getAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ AMÉLIORÉ : Obtenir les annonces pour un utilisateur spécifique
  Stream<List<DocumentSnapshot>> getAnnouncementsForUser(String userId, String role, String? groupId) {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String targetAudience = data['targetAudience'] ?? '';
            List<dynamic> targetUserIds = data['targetUserIds'] ?? [];
            
            // Si c'est pour tous
            if (targetAudience == 'all') return true;
            
            // Si c'est pour les profs et l'utilisateur est prof
            if (targetAudience == 'teachers' && role == 'prof') return true;
            
            // Si c'est pour les étudiants et l'utilisateur est étudiant
            if (targetAudience == 'students' && role == 'etudiant') return true;
            
            // Si c'est pour un groupe spécifique et l'utilisateur est dans targetUserIds
            if (targetAudience == 'specific_group' && targetUserIds.contains(userId)) {
              return true;
            }
            
            return false;
          }).toList();
        });
  }

  /// Marquer une annonce comme vue
  Future<void> markAsViewed(String announcementId) async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      await _firestore.collection('announcements').doc(announcementId).update({
        'viewedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Erreur markAsViewed: $e');
    }
  }

  /// Supprimer une annonce
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Erreur deleteAnnouncement: $e');
      return false;
    }
  }

  /// Obtenir le nom du créateur
  Future<String> getCreatorName(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (e) {
      print('Error getting creator name: $e');
    }
    return 'الإدارة';
  }

  /// Formater la date
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}