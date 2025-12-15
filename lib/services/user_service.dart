// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer un utilisateur par son ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Erreur getUserById: $e');
      return null;
    }
  }

  /// Stream d'un utilisateur (écoute en temps réel)
  Stream<UserModel?> userStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Récupérer tous les étudiants
  Future<List<UserModel>> getAllStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .orderBy('firstName')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur getAllStudents: $e');
      return [];
    }
  }

  /// Récupérer tous les professeurs
  Future<List<UserModel>> getAllProfs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'prof')
          .orderBy('firstName')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur getAllProfs: $e');
      return [];
    }
  }

  /// Récupérer les étudiants d'un groupe
  Future<List<UserModel>> getStudentsByGroup(String groupId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('groupId', isEqualTo: groupId)
          .orderBy('firstName')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur getStudentsByGroup: $e');
      return [];
    }
  }

  /// Mettre à jour un utilisateur
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(data);
      return true;
    } catch (e) {
      print('Erreur updateUser: $e');
      return false;
    }
  }

  /// Supprimer un utilisateur
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete();
      return true;
    } catch (e) {
      print('Erreur deleteUser: $e');
      return false;
    }
  }

  /// Activer/Désactiver un compte
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Erreur toggleUserStatus: $e');
      return false;
    }
  }

  /// Mettre à jour le hafdhCurrent d'un étudiant
  Future<bool> updateHafdCurrent(String studentId, int hafdCurrent) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentId)
          .update({'hafdCurrent': hafdCurrent});
      return true;
    } catch (e) {
      print('Erreur updateHafdCurrent: $e');
      return false;
    }
  }
}