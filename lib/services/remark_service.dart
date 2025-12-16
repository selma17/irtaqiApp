// lib/services/remark_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/remark_model.dart';

class RemarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Envoyer une remarque
  Future<bool> sendRemark({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
  }) async {
    try {
      await _firestore.collection('remarks').add({
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': message,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      return true;
    } catch (e) {
      print('Erreur sendRemark: $e');
      return false;
    }
  }

  /// Stream de toutes les remarques (pour admin)
  Stream<List<RemarkModel>> getAllRemarksStream() {
    return _firestore
        .collection('remarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RemarkModel.fromDoc(doc)).toList());
  }

  /// Stream des remarques non lues (pour admin)
  Stream<List<RemarkModel>> getUnreadRemarksStream() {
    return _firestore
        .collection('remarks')
        .where('status', isEqualTo: 'new')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RemarkModel.fromDoc(doc)).toList());
  }

  /// Stream des remarques d'un utilisateur spécifique
  Stream<List<RemarkModel>> getUserRemarksStream(String userId) {
    return _firestore
        .collection('remarks')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RemarkModel.fromDoc(doc)).toList());
  }

  /// Marquer une remarque comme lue
  Future<bool> markAsRead(String remarkId, String adminId) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).update({
        'status': 'open',
        'readBy': FieldValue.arrayUnion([adminId]),
      });
      return true;
    } catch (e) {
      print('Erreur markAsRead: $e');
      return false;
    }
  }

  /// Répondre à une remarque (admin)
  Future<bool> respondToRemark({
    required String remarkId,
    required String response,
  }) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).update({
        'adminResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'status': 'closed',
      });
      return true;
    } catch (e) {
      print('Erreur respondToRemark: $e');
      return false;
    }
  }

  /// Changer le statut d'une remarque
  Future<bool> changeStatus(String remarkId, String newStatus) async {
    try {
      await _firestore.collection('remarks').doc(remarkId).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      print('Erreur changeStatus: $e');
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

  /// Compter les remarques non lues
  Future<int> getUnreadCount() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('remarks')
          .where('status', isEqualTo: 'new')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Erreur getUnreadCount: $e');
      return 0;
    }
  }
}