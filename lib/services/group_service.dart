// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau groupe
  Future<String?> createGroup({
    required String name,
    required String profId,
    required List<ScheduleSlot> schedule,
    required List<String> studentIds,
    int maxStudents = 20,
  }) async {
    try {
      // Créer le groupe
      DocumentReference docRef = await _firestore.collection('groups').add({
        'name': name,
        'profId': profId,
        'schedule': schedule.map((slot) => slot.toMap()).toList(),
        'studentIds': studentIds,
        'maxStudents': maxStudents,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le groupId de chaque étudiant
      WriteBatch batch = _firestore.batch();
      for (String studentId in studentIds) {
        DocumentReference studentRef = _firestore.collection('users').doc(studentId);
        batch.update(studentRef, {'groupId': docRef.id});
      }
      await batch.commit();

      return docRef.id;
    } catch (e) {
      print('Erreur createGroup: $e');
      return null;
    }
  }

  /// Mettre à jour un groupe
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? profId,
    List<ScheduleSlot>? schedule,
    int? maxStudents,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (profId != null) updates['profId'] = profId;
      if (schedule != null) {
        updates['schedule'] = schedule.map((slot) => slot.toMap()).toList();
      }
      if (maxStudents != null) updates['maxStudents'] = maxStudents;

      await _firestore.collection('groups').doc(groupId).update(updates);
      return true;
    } catch (e) {
      print('Erreur updateGroup: $e');
      return false;
    }
  }

  /// Ajouter des étudiants à un groupe
  Future<bool> addStudentsToGroup(String groupId, List<String> studentIds) async {
    try {
      // Récupérer le groupe actuel
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return false;

      List<String> currentStudents = List<String>.from(
        (groupDoc.data() as Map<String, dynamic>)['studentIds'] ?? []
      );

      // Ajouter les nouveaux étudiants
      WriteBatch batch = _firestore.batch();
      
      for (String studentId in studentIds) {
        if (!currentStudents.contains(studentId)) {
          currentStudents.add(studentId);
          
          // Retirer l'étudiant de son ancien groupe si nécessaire
          DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
          String? oldGroupId = (studentDoc.data() as Map<String, dynamic>?)?['groupId'];
          
          if (oldGroupId != null && oldGroupId.isNotEmpty && oldGroupId != groupId) {
            // Retirer de l'ancien groupe
            DocumentReference oldGroupRef = _firestore.collection('groups').doc(oldGroupId);
            batch.update(oldGroupRef, {
              'studentIds': FieldValue.arrayRemove([studentId])
            });
          }
          
          // Mettre à jour le groupId de l'étudiant
          DocumentReference studentRef = _firestore.collection('users').doc(studentId);
          batch.update(studentRef, {'groupId': groupId});
        }
      }

      // Mettre à jour le groupe
      batch.update(
        _firestore.collection('groups').doc(groupId),
        {'studentIds': currentStudents}
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur addStudentsToGroup: $e');
      return false;
    }
  }

  /// Retirer un étudiant d'un groupe
  Future<bool> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Retirer du groupe
      DocumentReference groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'studentIds': FieldValue.arrayRemove([studentId])
      });

      // Mettre à jour l'étudiant
      DocumentReference studentRef = _firestore.collection('users').doc(studentId);
      batch.update(studentRef, {'groupId': null});

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur removeStudentFromGroup: $e');
      return false;
    }
  }

  /// Transférer tous les étudiants d'un groupe à un autre
  Future<bool> transferStudents(String fromGroupId, String toGroupId) async {
    try {
      // Récupérer le groupe source
      DocumentSnapshot fromDoc = await _firestore.collection('groups').doc(fromGroupId).get();
      if (!fromDoc.exists) return false;

      List<String> studentIds = List<String>.from(
        (fromDoc.data() as Map<String, dynamic>)['studentIds'] ?? []
      );

      if (studentIds.isEmpty) return true;

      // Vérifier la capacité du groupe cible
      DocumentSnapshot toDoc = await _firestore.collection('groups').doc(toGroupId).get();
      if (!toDoc.exists) return false;

      Map<String, dynamic> toData = toDoc.data() as Map<String, dynamic>;
      int maxStudents = toData['maxStudents'] ?? 20;
      List<String> currentStudents = List<String>.from(toData['studentIds'] ?? []);

      if (currentStudents.length + studentIds.length > maxStudents) {
        return false; // Pas assez de place
      }

      // Transférer les étudiants
      WriteBatch batch = _firestore.batch();

      // Ajouter au groupe cible
      currentStudents.addAll(studentIds);
      batch.update(
        _firestore.collection('groups').doc(toGroupId),
        {'studentIds': currentStudents}
      );

      // Mettre à jour chaque étudiant
      for (String studentId in studentIds) {
        batch.update(
          _firestore.collection('users').doc(studentId),
          {'groupId': toGroupId}
        );
      }

      // Vider le groupe source
      batch.update(
        _firestore.collection('groups').doc(fromGroupId),
        {'studentIds': []}
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur transferStudents: $e');
      return false;
    }
  }

  /// Supprimer un groupe (uniquement si vide)
  Future<bool> deleteGroup(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return false;

      List<String> studentIds = List<String>.from(
        (doc.data() as Map<String, dynamic>)['studentIds'] ?? []
      );

      if (studentIds.isNotEmpty) {
        return false; // Ne peut pas supprimer un groupe avec des étudiants
      }

      await _firestore.collection('groups').doc(groupId).delete();
      return true;
    } catch (e) {
      print('Erreur deleteGroup: $e');
      return false;
    }
  }

  /// Obtenir les étudiants sans groupe
  Future<List<Map<String, dynamic>>> getStudentsWithoutGroup() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> students = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? groupId = data['groupId'];
        
        if (groupId == null || groupId.isEmpty) {
          students.add({
            'id': doc.id,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'age': data['age'] ?? 0,
            'totalHafd': (data['oldHafd'] ?? 0) + (data['newHafd'] ?? 0),
          });
        }
      }

      return students;
    } catch (e) {
      print('Erreur getStudentsWithoutGroup: $e');
      return [];
    }
  }

  /// Calculer les statistiques d'un groupe
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        return {'averageHafd': 0, 'attendanceRate': 0};
      }

      List<String> studentIds = List<String>.from(
        (groupDoc.data() as Map<String, dynamic>)['studentIds'] ?? []
      );

      if (studentIds.isEmpty) {
        return {'averageHafd': 0, 'attendanceRate': 0};
      }

      // Calculer la moyenne de hafḍ
      int totalHafd = 0;
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
          totalHafd += (data['oldHafd'] as int? ?? 0) + (data['newHafd'] as int? ?? 0);
        }
      }

      double averageHafd = totalHafd / studentIds.length;

      return {
        'averageHafd': averageHafd.round(),
        'attendanceRate': 0, // TODO: Calculer depuis followUps
      };
    } catch (e) {
      print('Erreur getGroupStats: $e');
      return {'averageHafd': 0, 'attendanceRate': 0};
    }
  }

  /// Stream de tous les groupes
  Stream<List<GroupModel>> getAllGroups() {
    return _firestore
        .collection('groups')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupModel.fromDoc(doc)).toList());
  }

  /// Obtenir un groupe par ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromDoc(doc);
    } catch (e) {
      print('Erreur getGroupById: $e');
      return null;
    }
  }
}