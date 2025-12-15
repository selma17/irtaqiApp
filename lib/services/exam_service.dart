// lib/services/exam_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exam_model.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer un nouvel examen
  Future<String?> createExam({
    required String studentId,
    required String type,
    required DateTime examDate,
    String? notes,
  }) async {
    try {
      String profId = _auth.currentUser!.uid;

      // Récupérer les infos du prof créateur
      DocumentSnapshot profDoc = await _firestore.collection('users').doc(profId).get();
      Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
      String profName = '${profData['firstName']} ${profData['lastName']}';

      // Récupérer les infos de l'étudiant
      DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
      Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
      String studentName = '${studentData['firstName']} ${studentData['lastName']}';

      // Déterminer assignedProfId
      String? assignedProfId;
      String? assignedProfName;
      String status;

      if (type == '10ahzab') {
        // Pour 10 ahzab: status = pending, pas d'assignedProfId
        status = 'pending';
        assignedProfId = null;
        assignedProfName = null;
      } else {
        // Pour 5 ahzab: status = pending, assignedProfId = profId créateur
        status = 'pending';
        assignedProfId = profId;
        assignedProfName = profName;
      }

      // Créer l'examen
      DocumentReference examRef = await _firestore.collection('exams').add({
        'studentId': studentId,
        'studentName': studentName,
        'type': type,
        'examDate': Timestamp.fromDate(examDate),
        'status': status,
        'createdByProfId': profId,
        'createdByProfName': profName,
        'assignedProfId': assignedProfId,
        'assignedProfName': assignedProfName,
        'notes': notes ?? '',
        'score': null,
        'feedback': null,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Examen créé: ${examRef.id}');
      print('   - Type: $type');
      print('   - Status: $status');
      print('   - assignedProfId: ${assignedProfId ?? "null (en attente)"}');

      return examRef.id;
    } catch (e) {
      print('❌ Erreur createExam: $e');
      return null;
    }
  }

  /// Stream des examens créés par le prof (tous types confondus)
  Stream<List<ExamModel>> getProfExamsStream(String profId) {
    return _firestore
        .collection('exams')
        .where('createdByProfId', isEqualTo: profId)
        .orderBy('examDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExamModel.fromDoc(doc)).toList();
    });
  }

  /// Stream des examens ASSIGNÉS au prof (pour supervision)
  Stream<List<ExamModel>> getAssignedExamsStream(String profId) {
    return _firestore
        .collection('exams')
        .where('assignedProfId', isEqualTo: profId)
        .orderBy('examDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExamModel.fromDoc(doc)).toList();
    });
  }

  /// Stream des examens EN ATTENTE d'assignation (10 ahzab sans prof assigné)
  Stream<List<ExamModel>> getPendingExamsStream() {
    return _firestore
        .collection('exams')
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: '10ahzab')
        .where('assignedProfId', isEqualTo: null)
        .orderBy('examDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExamModel.fromDoc(doc)).toList();
    });
  }

  /// Assigner un examen 10ahzab à un prof
  Future<bool> assignExam(String examId, String profId) async {
    try {
      // Récupérer le nom du prof
      DocumentSnapshot profDoc = await _firestore.collection('users').doc(profId).get();
      Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
      String profName = '${profData['firstName']} ${profData['lastName']}';

      await _firestore.collection('exams').doc(examId).update({
        'assignedProfId': profId,
        'assignedProfName': profName,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Examen $examId assigné au prof $profName');
      return true;
    } catch (e) {
      print('❌ Erreur assignExam: $e');
      return false;
    }
  }

  /// Marquer un examen comme complété avec note
  Future<bool> completeExam(String examId, int score, String feedback) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'status': 'completed',
        'score': score,
        'feedback': feedback,
        'completedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Examen $examId complété avec note: $score');
      return true;
    } catch (e) {
      print('❌ Erreur completeExam: $e');
      return false;
    }
  }

  /// Récupérer un examen par ID
  Future<ExamModel?> getExamById(String examId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('exams').doc(examId).get();
      if (!doc.exists) return null;
      return ExamModel.fromDoc(doc);
    } catch (e) {
      print('❌ Erreur getExamById: $e');
      return null;
    }
  }

  /// Supprimer un examen (seulement si status = pending)
  Future<bool> deleteExam(String examId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('exams').doc(examId).get();
      if (!doc.exists) return false;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        print('❌ Impossible de supprimer: examen déjà assigné ou complété');
        return false;
      }

      await _firestore.collection('exams').doc(examId).delete();
      print('✅ Examen $examId supprimé');
      return true;
    } catch (e) {
      print('❌ Erreur deleteExam: $e');
      return false;
    }
  }

  /// Statistiques des examens d'un prof
  Future<Map<String, int>> getProfExamStats(String profId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exams')
          .where('createdByProfId', isEqualTo: profId)
          .get();

      int total = snapshot.docs.length;
      int completed = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'completed').length;
      int pending = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'pending').length;
      int assigned = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'assigned').length;

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'assigned': assigned,
      };
    } catch (e) {
      print('❌ Erreur getProfExamStats: $e');
      return {'total': 0, 'completed': 0, 'pending': 0, 'assigned': 0};
    }
  }

  /// Récupérer les prochains examens (pour teacher_page)
  Future<List<ExamModel>> getUpcomingExams(String profId, {int limit = 5}) async {
    try {
      DateTime now = DateTime.now();
      
      QuerySnapshot snapshot = await _firestore
          .collection('exams')
          .where('assignedProfId', isEqualTo: profId)
          .where('status', whereIn: ['pending', 'assigned'])
          .orderBy('examDate')
          .limit(limit)
          .get();

      List<ExamModel> exams = snapshot.docs
          .map((doc) => ExamModel.fromDoc(doc))
          .where((exam) => exam.examDate.isAfter(now))
          .toList();

      return exams;
    } catch (e) {
      print('❌ Erreur getUpcomingExams: $e');
      return [];
    }
  }
}