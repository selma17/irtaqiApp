// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/followup_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add followup under student
  Future<DocumentReference> addFollowUp(String studentId, FollowUpModel model) {
    final ref = _db.collection('students').doc(studentId).collection('followUps');
    return ref.add(model.toMap());
  }

  // Update followup (by doc id)
  Future<void> updateFollowUp(String studentId, String followUpId, FollowUpModel model) {
    final ref = _db.collection('students').doc(studentId).collection('followUps').doc(followUpId);
    return ref.set(model.toMap(), SetOptions(merge: true));
  }

  // Delete followup
  Future<void> deleteFollowUp(String studentId, String followUpId) {
    final ref = _db.collection('students').doc(studentId).collection('followUps').doc(followUpId);
    return ref.delete();
  }

  // Stream all followups for a student (ordered by date desc)
  Stream<List<FollowUpModel>> followUpsStream(String studentId) {
    final ref = _db.collection('students').doc(studentId).collection('followUps').orderBy('date', descending: true);
    return ref.snapshots().map((snap) => snap.docs.map((d) => FollowUpModel.fromDoc(d)).toList());
  }

  // Optional: get all students simple list (manual data or later from users collection)
  Stream<List<Map<String, dynamic>>> studentsStream() {
    return _db.collection('students').snapshots().map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
