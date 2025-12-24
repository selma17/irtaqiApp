// lib/services/exam_service.dart
// ✅ VERSION CORRIGÉE avec examDate nullable

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
    DateTime? examDate, // ✅ NULLABLE
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

      // Déterminer assignedProfId et date
      String? assignedProfId;
      String? assignedProfName;
      String status;
      DateTime? finalExamDate;

      if (type == '10ahzab') {
        // Pour 10 ahzab: status = pending, pas d'assignedProfId, pas de date
        status = 'pending';
        assignedProfId = null;
        assignedProfName = null;
        finalExamDate = null; // ✅ Pas de date pour 10 ahzab en attente
      } else {
        // Pour 5 ahzab: status = pending, assignedProfId = profId créateur
        status = 'pending';
        assignedProfId = profId;
        assignedProfName = profName;
        finalExamDate = examDate ?? DateTime.now().add(Duration(days: 7)); // ✅ Date par défaut
      }

      // Créer l'examen
      DocumentReference examRef = await _firestore.collection('exams').add({
        'studentId': studentId,
        'studentName': studentName,
        'type': type,
        'examDate': finalExamDate != null ? Timestamp.fromDate(finalExamDate) : null, // ✅ Peut être null
        'status': status,
        'createdByProfId': profId,
        'createdByProfName': profName,
        'assignedProfId': assignedProfId,
        'assignedProfName': assignedProfName,
        'notes': notes ?? '',
        'grade': null, // ✅ grade au lieu de score
        'score': null, // ✅ Garder pour compatibilité
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
  /// ✅ CORRIGÉ : Sans orderBy pour éviter erreur Timestamp null
  Stream<List<ExamModel>> getProfExamsStream(String profId) {
    print('📊 getProfExamsStream pour profId: $profId');
    return _firestore
        .collection('exams')
        .where('createdByProfId', isEqualTo: profId)
        .snapshots()
        .map((snapshot) {
      print('📊 Nombre examens prof: ${snapshot.docs.length}');
      List<ExamModel> exams = snapshot.docs.map((doc) {
        try {
          return ExamModel.fromDoc(doc);
        } catch (e) {
          print('❌ Erreur parsing exam ${doc.id}: $e');
          return null;
        }
      }).whereType<ExamModel>().toList();
      
      // ✅ Tri côté client
      exams.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return exams;
    });
  }

  /// Stream des examens ASSIGNÉS au prof (pour supervision)
  /// ✅ CORRIGÉ : Sans orderBy
  Stream<List<ExamModel>> getAssignedExamsStream(String profId) {
    print('📊 getAssignedExamsStream pour profId: $profId');
    return _firestore
        .collection('exams')
        .where('assignedProfId', isEqualTo: profId)
        .snapshots()
        .map((snapshot) {
      print('📊 Nombre examens assignés: ${snapshot.docs.length}');
      List<ExamModel> exams = snapshot.docs.map((doc) {
        try {
          return ExamModel.fromDoc(doc);
        } catch (e) {
          print('❌ Erreur parsing exam ${doc.id}: $e');
          return null;
        }
      }).whereType<ExamModel>().toList();
      
      // ✅ Tri côté client
      exams.sort((a, b) {
        if (a.examDate == null && b.examDate == null) return 0;
        if (a.examDate == null) return 1;
        if (b.examDate == null) return -1;
        return a.examDate!.compareTo(b.examDate!);
      });
      
      return exams;
    });
  }

  /// Stream des examens EN ATTENTE d'assignation (10 ahzab sans prof assigné)
  /// ✅ CORRIGÉ : Sans where assignedProfId (pas d'index)
  Stream<List<ExamModel>> getPendingExamsStream() {
    return _firestore
        .collection('exams')
        .where('type', isEqualTo: '10ahzab')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      // ✅ Filtrer côté client ceux sans assignedProfId
      List<ExamModel> exams = snapshot.docs
          .map((doc) {
            try {
              return ExamModel.fromDoc(doc);
            } catch (e) {
              print('❌ Erreur parsing exam ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ExamModel>()
          .where((exam) => exam.assignedProfId == null)
          .toList();
      
      return exams;
    });
  }

  /// Assigner un examen 10ahzab à un prof
  Future<bool> assignExam(String examId, String profId, DateTime examDate) async {
    try {
      // Récupérer le nom du prof
      DocumentSnapshot profDoc = await _firestore.collection('users').doc(profId).get();
      Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
      String profName = '${profData['firstName']} ${profData['lastName']}';

      await _firestore.collection('exams').doc(examId).update({
        'assignedProfId': profId,
        'assignedProfName': profName,
        'examDate': Timestamp.fromDate(examDate), // ✅ Date choisie par admin
        'status': 'approved', // ✅ approved au lieu de assigned
        'assignedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Examen $examId assigné au prof $profName pour le $examDate');
      return true;
    } catch (e) {
      print('❌ Erreur assignExam: $e');
      return false;
    }
  }

  /// Marquer un examen comme complété avec note
  Future<bool> completeExam(String examId, int grade, String feedback) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'status': 'graded', // ✅ graded au lieu de completed
        'grade': grade, // ✅ grade (0-20)
        'score': grade, // ✅ Garder pour compatibilité
        'notes': feedback, // ✅ notes au lieu de feedback
        'feedback': feedback, // ✅ Garder pour compatibilité
        'completedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Examen $examId complété avec note: $grade/20');
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
      int graded = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'graded').length;
      int pending = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'pending').length;
      int approved = snapshot.docs.where((doc) => (doc.data() as Map)['status'] == 'approved').length;

      return {
        'total': total,
        'graded': graded,
        'pending': pending,
        'approved': approved,
      };
    } catch (e) {
      print('❌ Erreur getProfExamStats: $e');
      return {'total': 0, 'graded': 0, 'pending': 0, 'approved': 0};
    }
  }

  /// Récupérer les prochains examens (pour teacher_page)
  Future<List<ExamModel>> getUpcomingExams(String profId, {int limit = 5}) async {
    try {
      DateTime now = DateTime.now();
      
      QuerySnapshot snapshot = await _firestore
          .collection('exams')
          .where('assignedProfId', isEqualTo: profId)
          .limit(limit * 2) // Prendre plus pour filtrer après
          .get();

      List<ExamModel> exams = snapshot.docs
          .map((doc) {
            try {
              return ExamModel.fromDoc(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<ExamModel>()
          .where((exam) => 
              exam.examDate != null && 
              exam.examDate!.isAfter(now) &&
              (exam.status == 'pending' || exam.status == 'approved')
          )
          .toList();

      // Trier par date
      exams.sort((a, b) => a.examDate!.compareTo(b.examDate!));
      
      return exams.take(limit).toList();
    } catch (e) {
      print('❌ Erreur getUpcomingExams: $e');
      return [];
    }
  }
}