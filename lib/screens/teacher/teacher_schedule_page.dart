// lib/screens/teacher/teacher_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSchedulePage extends StatefulWidget {
  @override
  _TeacherSchedulePageState createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        body: StreamBuilder<QuerySnapshot>(
          // ✅ Charger tous les groupes du prof connecté
          stream: _firestore
              .collection('groups')
              .where('profId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4F6F52)),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل جدول الأوقات...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'حدث خطأ في تحميل البيانات',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        snapshot.error.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ Extraire les sessions de tous les groupes
            List<Map<String, dynamic>> scheduleItems = [];
            if (snapshot.hasData && snapshot.data != null) {
              try {
                for (var groupDoc in snapshot.data!.docs) {
                  Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
                  String groupName = groupData['name'] ?? 'مجموعة';
                  
                  // ✅ Récupérer l'array schedule
                  List<dynamic> schedule = groupData['schedule'] ?? [];
                  
                  // ✅ Créer une session pour chaque élément du schedule
                  for (var session in schedule) {
                    if (session is Map) {
                      scheduleItems.add({
                        'groupName': groupName,
                        'groupId': groupDoc.id,
                        'day': session['day'] ?? '',
                        'startTime': session['startTime'] ?? '',
                        'endTime': session['endTime'] ?? '',
                      });
                    }
                  }
                }
              } catch (e) {
                print('Erreur parsing données: $e');
              }
            }

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
                    SizedBox(height: 8),
                    Text(
                      'لم يتم تعيين حصص لك بعد',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                  _buildHeader(scheduleItems.length),
                  SizedBox(height: 20),
                  _buildScheduleTable(scheduleItems),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int sessionsCount) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
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
                  'لديك $sessionsCount حصة أسبوعياً',
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
    );
  }

  Widget _buildScheduleTable(List<Map<String, dynamic>> scheduleItems) {
    // Jours de la semaine en arabe
    List<String> days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    
    // Créneaux horaires heure par heure (8h à 19h)
    List<String> timeSlots = [
      '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00',
      '16:00', '17:00', '18:00', '19:00',
    ];

    // Organiser les données par jour et heure
    Map<String, Map<String, List<Map<String, dynamic>>>> scheduleMap = {};
    
    for (var day in days) {
      scheduleMap[day] = {};
      for (var time in timeSlots) {
        scheduleMap[day]![time] = [];
      }
    }

    // Fonction helper pour convertir "HH:MM" en minutes
    int _timeToMinutes(String time) {
      try {
        List<String> parts = time.split(':');
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        return hours * 60 + minutes;
      } catch (e) {
        return 0;
      }
    }

    // Fonction pour vérifier si une séance chevauche un créneau
    bool _overlaps(String sessionStart, String sessionEnd, String slotStart, String slotEnd) {
      int sessionStartMin = _timeToMinutes(sessionStart);
      int sessionEndMin = _timeToMinutes(sessionEnd);
      int slotStartMin = _timeToMinutes(slotStart);
      int slotEndMin = _timeToMinutes(slotEnd);
      return (sessionStartMin < slotEndMin) && (sessionEndMin > slotStartMin);
    }

    // Remplir la map avec les données
    for (var item in scheduleItems) {
      String day = item['day'] ?? '';
      String sessionStart = item['startTime'] ?? '';
      String sessionEnd = item['endTime'] ?? '';
      
      if (scheduleMap.containsKey(day) && sessionStart.isNotEmpty && sessionEnd.isNotEmpty) {
        for (var slot in timeSlots) {
          // Chaque créneau dure 1h
          List<String> slotParts = slot.split(':');
          int slotHour = int.parse(slotParts[0]);
          String slotEnd = '${(slotHour + 1).toString().padLeft(2, '0')}:00';
          
          if (_overlaps(sessionStart, sessionEnd, slot, slotEnd)) {
            scheduleMap[day]![slot]!.add(Map.from(item));
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Color(0xFF4F6F52).withOpacity(0.1),
            ),
            headingRowHeight: 15,
            dataRowHeight: 40,
            columnSpacing: 12,
            horizontalMargin: 12,
            columns: [
              DataColumn(
                label: Container(
                  width: 50,
                  child: Text(
                    'الوقت',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              ...days.map((day) => DataColumn(
                label: Container(
                  width: 70,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                      fontSize: 12,
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
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        timeSlot.substring(0, 5), // Afficher HH:MM
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                    ),
                  ),
                  // Colonnes des jours
                  ...days.map((day) {
                    List<Map<String, dynamic>> sessions = scheduleMap[day]![timeSlot] ?? [];
                    
                    return DataCell(
                      Container(
                        width: 90,
                        child: sessions.isEmpty
                            ? SizedBox.shrink()
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: sessions.map((session) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 4),
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF4F6F52).withOpacity(0.15),
                                            Color(0xFF6B8F71).withOpacity(0.15),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFF4F6F52).withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.groups,
                                                size: 11,
                                                color: Color(0xFF4F6F52),
                                              ),
                                              SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  session['groupName'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                    color: Color(0xFF4F6F52),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 8,
                                                color: Colors.grey[700],
                                              ),
                                              SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  '${session['startTime']}-${session['endTime']}',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
          ),
        ),
      ),
    );
  }
}