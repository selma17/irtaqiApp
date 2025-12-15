// lib/services/remark_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envoyer une remarque
  Future<bool> sendRemark({
    required String subject,
    required String type, // "suggestion", "problem", "question", "other"
    required String details,
    bool isAnonymous = false,
  }) async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      String senderName = 'مستخدم مجهول';
      String senderRole = 'etudiant';

      if (!isAnonymous && userId.isNotEmpty) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          senderName = '${userData['firstName']} ${userData['lastName']}';
          senderRole = userData['role'] ?? 'etudiant';
        }
      }

      await _firestore.collection('remarks').add({
        'subject': subject,
        'type': type,
        'details': details,
        'isAnonymous': isAnonymous,
        'sentBy': isAnonymous ? null : userId,
        'senderName': senderName,
        'senderRole': senderRole,
        'status': 'new', // "new", "open"
        'response': null,
        'respondedBy': null,
        'respondedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur sendRemark: $e');
      return false;
    }
  }

  /// Obtenir toutes les remarques (pour admin)
  Stream<QuerySnapshot> getAllRemarks() {
    return _firestore
        .collection('remarks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Obtenir les remarques par statut
  Stream<QuerySnapshot> getRemarksByStatus(String status) {
    return _firestore
        .collection('remarks')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Répondre à une remarque
  Future<bool> respondToRemark({
    required String remarkId,
    required String response,
  }) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).update({
        'response': response,
        'respondedBy': _auth.currentUser?.uid,
        'respondedAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      return true;
    } catch (e) {
      print('Erreur respondToRemark: $e');
      return false;
    }
  }

  /// Changer le statut d'une remarque
  Future<bool> changeRemarkStatus(String remarkId, String status) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      print('Erreur changeRemarkStatus: $e');
      return false;
    }
  }

  /// Supprimer une remarque
  Future<bool> deleteRemark(String remarkId) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).delete();
      return true;
    } catch (e) {
      print('Erreur deleteRemark: $e');
      return false;
    }
  }

  /// Obtenir le nom de l'admin qui a répondu
  Future<String> getResponderName(String? userId) async {
    if (userId == null) return 'الإدارة';
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (e) {
      print('Error getting responder name: $e');
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

  /// Obtenir l'icône selon le type
  static String getTypeLabel(String type) {
    switch (type) {
      case 'suggestion':
        return 'اقتراح';
      case 'problem':
        return 'مشكلة';
      case 'question':
        return 'سؤال';
      case 'other':
        return 'أخرى';
      default:
        return 'ملاحظة';
    }
  }

  /// Obtenir la couleur selon le statut
  static String getStatusLabel(String status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'open':
        return 'مفتوح';
      default:
        return status;
    }
  }
}