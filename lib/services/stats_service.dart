// lib/services/stats_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir le nombre d'étudiants par mois (6 derniers mois)
  Future<List<Map<String, dynamic>>> getStudentsGrowth() async {
    try {
      // Date actuelle
      DateTime now = DateTime.now();
      
      // Liste pour stocker les stats
      List<Map<String, dynamic>> monthlyStats = [];
      
      // Récupérer tous les étudiants actifs avec leur date d'inscription
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('isActive', isEqualTo: true)
          .get();

      // Calculer pour les 6 derniers mois
      for (int i = 5; i >= 0; i--) {
        DateTime monthDate = DateTime(now.year, now.month - i, 1);
        DateTime nextMonth = DateTime(now.year, now.month - i + 1, 1);
        
        // Compter les étudiants inscrits avant ce mois
        int count = studentsSnapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (data['dateInscription'] == null) return false;
          
          DateTime inscriptionDate;
          if (data['dateInscription'] is Timestamp) {
            inscriptionDate = (data['dateInscription'] as Timestamp).toDate();
          } else if (data['dateInscription'] is DateTime) {
            inscriptionDate = data['dateInscription'];
          } else {
            return false;
          }
          
          // Compter si inscrit avant le mois suivant
          return inscriptionDate.isBefore(nextMonth);
        }).length;
        
        monthlyStats.add({
          'month': monthDate,
          'monthName': _getArabicMonthName(monthDate.month),
          'count': count,
        });
      }
      
      return monthlyStats;
    } catch (e) {
      print('Erreur getStudentsGrowth: $e');
      return [];
    }
  }

  /// Obtenir le nombre d'étudiants inscrits par mois
  Future<List<Map<String, dynamic>>> getMonthlyRegistrations() async {
    try {
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> monthlyRegistrations = [];
      
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('isActive', isEqualTo: true)
          .get();

      for (int i = 5; i >= 0; i--) {
        DateTime monthStart = DateTime(now.year, now.month - i, 1);
        DateTime monthEnd = DateTime(now.year, now.month - i + 1, 1);
        
        int count = studentsSnapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (data['dateInscription'] == null) return false;
          
          DateTime inscriptionDate;
          if (data['dateInscription'] is Timestamp) {
            inscriptionDate = (data['dateInscription'] as Timestamp).toDate();
          } else if (data['dateInscription'] is DateTime) {
            inscriptionDate = data['dateInscription'];
          } else {
            return false;
          }
          
          return inscriptionDate.isAfter(monthStart) && 
                 inscriptionDate.isBefore(monthEnd);
        }).length;
        
        monthlyRegistrations.add({
          'month': monthStart,
          'monthName': _getArabicMonthName(monthStart.month),
          'count': count,
        });
      }
      
      return monthlyRegistrations;
    } catch (e) {
      print('Erreur getMonthlyRegistrations: $e');
      return [];
    }
  }

  /// Convertir numéro de mois en nom arabe
  String _getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  /// Obtenir les statistiques générales
  Future<Map<String, dynamic>> getGeneralStats() async {
    try {
      // Nombre total d'étudiants
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Nombre total de profs
      QuerySnapshot profsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'prof')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Nombre total de groupes
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .get();
      
      // Nombre d'examens planifiés
      QuerySnapshot examsSnapshot = await _firestore
          .collection('exams')
          .where('status', isEqualTo: 'planned')
          .get();
      
      // Étudiants sans groupe
      int studentsWithoutGroup = studentsSnapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['groupId'] == null || data['groupId'].toString().isEmpty;
      }).length;
      
      return {
        'totalStudents': studentsSnapshot.docs.length,
        'totalProfs': profsSnapshot.docs.length,
        'totalGroups': groupsSnapshot.docs.length,
        'plannedExams': examsSnapshot.docs.length,
        'studentsWithoutGroup': studentsWithoutGroup,
      };
    } catch (e) {
      print('Erreur getGeneralStats: $e');
      return {
        'totalStudents': 0,
        'totalProfs': 0,
        'totalGroups': 0,
        'plannedExams': 0,
        'studentsWithoutGroup': 0,
      };
    }
  }
}