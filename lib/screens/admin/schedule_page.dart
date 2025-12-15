// lib/screens/admin/schedule_page.dart

import 'package:flutter/material.dart';
import '../../services/schedule_service.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('جدول الأوقات'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _scheduleService.getFullSchedule(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('حدث خطأ في تحميل البيانات'),
              );
            }

            List<Map<String, dynamic>> scheduleItems = snapshot.data ?? [];

            if (scheduleItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد حصص مجدولة',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'جدول الأوقات الأسبوعي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'عرض جميع الحصص المجدولة',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Schedule Table
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildScheduleTable(scheduleItems),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleTable(List<Map<String, dynamic>> scheduleItems) {
    List<String> days = _scheduleService.getDaysOfWeek();
    List<String> timeSlots = _scheduleService.getTimeSlots();

    // Organiser les données par jour et heure
    Map<String, Map<String, List<Map<String, dynamic>>>> scheduleMap = {};
    
    for (var day in days) {
      scheduleMap[day] = {};
      for (var time in timeSlots) {
        scheduleMap[day]![time] = [];
      }
    }

    // Fonction helper pour convertir "HH:MM" en minutes depuis minuit
    int _timeToMinutes(String time) {
      List<String> parts = time.split(':');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    }

    // Fonction pour vérifier si une séance chevauche un créneau
    bool _overlaps(String sessionStart, String sessionEnd, String slotStart, String slotEnd) {
      int sessionStartMin = _timeToMinutes(sessionStart);
      int sessionEndMin = _timeToMinutes(sessionEnd);
      int slotStartMin = _timeToMinutes(slotStart);
      int slotEndMin = _timeToMinutes(slotEnd);

      // Vérifie si les intervalles se chevauchent
      return (sessionStartMin < slotEndMin) && (sessionEndMin > slotStartMin);
    }

    // Remplir la map avec les données
    for (var item in scheduleItems) {
      String day = item['day'];
      String sessionStart = item['startTime'];
      String sessionEnd = item['endTime'];
      
      if (scheduleMap.containsKey(day)) {
        // Parcourir tous les créneaux pour trouver les chevauchements
        for (var slot in timeSlots) {
          // Calculer l'heure de fin du créneau (2h après le début)
          List<String> slotParts = slot.split(':');
          int slotHour = int.parse(slotParts[0]);
          String slotEnd = '${(slotHour + 2).toString().padLeft(2, '0')}:00';
          
          if (_overlaps(sessionStart, sessionEnd, slot, slotEnd)) {
            // Créer une copie de l'item pour éviter les références multiples
            Map<String, dynamic> itemCopy = Map.from(item);
            scheduleMap[day]![slot]!.add(itemCopy);
          }
        }
      }
    }

    return DataTable(
      headingRowColor: MaterialStateProperty.all(
        Color(0xFF4F6F52).withOpacity(0.1),
      ),
      columns: [
        DataColumn(
          label: Container(
            width: 80,
            child: Text(
              'الوقت',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F6F52),
              ),
            ),
          ),
        ),
        ...days.map((day) => DataColumn(
          label: Container(
            width: 120,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F6F52),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )),
      ],
      rows: timeSlots.map((timeSlot) {
        return DataRow(
          cells: [
            // Colonne de temps
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Colonnes des jours
            ...days.map((day) {
              List<Map<String, dynamic>> sessions = scheduleMap[day]![timeSlot] ?? [];
              
              return DataCell(
                Container(
                  width: 120,
                  height: 100, // ✅ Hauteur fixe pour éviter overflow
                  child: sessions.isEmpty
                      ? SizedBox.shrink()
                      : SingleChildScrollView( // ✅ Scrollable si trop de contenu
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: sessions.map((session) {
                              return FutureBuilder<String>(
                                future: _scheduleService.getProfName(session['profId']),
                                builder: (context, profSnapshot) {
                                  String profName = profSnapshot.data ?? 'جاري التحميل...';
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 6), // ✅ Réduit de 8 à 6
                                    padding: EdgeInsets.all(6), // ✅ Réduit de 8 à 6
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4F6F52).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6), // ✅ Réduit de 8 à 6
                                      border: Border.all(
                                        color: Color(0xFF4F6F52).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['groupName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10, // ✅ Réduit de 11 à 10
                                            color: Color(0xFF4F6F52),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2), // ✅ Réduit de 4 à 2
                                        Text(
                                          profName,
                                          style: TextStyle(
                                            fontSize: 9, // ✅ Réduit de 10 à 9
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2), // ✅ Réduit de 4 à 2
                                        Text(
                                          '${session['startTime']} - ${session['endTime']}',
                                          style: TextStyle(
                                            fontSize: 8, // ✅ Réduit de 9 à 8
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}