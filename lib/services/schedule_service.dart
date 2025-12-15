// lib/services/schedule_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir l'emploi du temps complet de tous les groupes
  Stream<List<Map<String, dynamic>>> getFullSchedule() {
    return _firestore.collection('groups').snapshots().map((snapshot) {
      List<Map<String, dynamic>> scheduleItems = [];

      for (var groupDoc in snapshot.docs) {
        Map<String, dynamic> groupData = groupDoc.data();
        String groupId = groupDoc.id;
        String groupName = groupData['name'] ?? 'مجموعة';
        String profId = groupData['profId'] ?? '';
        List<dynamic> schedule = groupData['schedule'] ?? [];

        for (var slot in schedule) {
          scheduleItems.add({
            'groupId': groupId,
            'groupName': groupName,
            'profId': profId,
            'day': slot['day'],
            'startTime': slot['startTime'],
            'endTime': slot['endTime'],
          });
        }
      }

      return scheduleItems;
    });
  }

  /// Obtenir le nom d'un professeur
  Future<String> getProfName(String profId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(profId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (e) {
      print('Error getting prof name: $e');
    }
    return 'غير محدد';
  }

  /// Obtenir les tranches horaires disponibles (08:00 à 20:00, par 2h)
  List<String> getTimeSlots() {
    return [
      '08:00',
      '10:00',
      '12:00',
      '14:00',
      '16:00',
      '18:00',
      '20:00',
    ];
  }

  /// Obtenir les jours de la semaine
  List<String> getDaysOfWeek() {
    return [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
  }

  /// Formater une plage horaire
  String formatTimeRange(String startTime, String endTime) {
    return '$startTime - $endTime';
  }
}