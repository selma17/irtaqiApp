import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/followup_model.dart';

class FollowService {
  final _db = FirebaseFirestore.instance;

  Future<void> addFollow(String studentId, FollowUpModel data) async {
    await _db
        .collection('students')
        .doc(studentId)
        .collection('follow')
        .add(data.toMap());
  }
}
