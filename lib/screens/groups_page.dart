// lib/screens/groups_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedGroupId;
  Map<String, dynamic>? selectedGroupData;
  List<Map<String, dynamic>> groupStudents = [];
  bool isLoadingStudents = false;
  
  late TabController _tabController;
  
  // Liste des fiches de présence mensuelles
  List<Map<String, dynamic>> attendanceSheets = [];
  
  // Mois disponibles
  List<String> months = _generateMonths();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static List<String> _generateMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = -6; i <= 6; i++) {
      DateTime month = DateTime(now.year, now.month + i);
      months.add('${month.year}-${month.month.toString().padLeft(2, '0')}');
    }
    return months;
  }

  String _getMonthName(String monthKey) {
    List<String> parts = monthKey.split('-');
    int month = int.parse(parts[1]);
    List<String> arabicMonths = [
      'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
      'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${arabicMonths[month - 1]} ${parts[0]}';
  }

  Future<void> _loadExistingSheets() async {
    if (selectedGroupId == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('groupId', isEqualTo: selectedGroupId)
          .orderBy('month', descending: true)
          .get();

      setState(() {
        attendanceSheets.clear();
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          attendanceSheets.add({
            "docId": doc.id,
            "month": data['month'],
            "students": Map<String, Map<String, String>>.from(
              (data['students'] as Map).map((key, value) =>
                MapEntry(key, Map<String, String>.from(value as Map))
              )
            ),
            "isSaved": true,
          });
        }
      });
    } catch (e) {
      print('Erreur chargement fiches: $e');
    }
  }

  void _addNewSheet() {
    String currentMonth = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    
    // Créer structure vide pour tous les étudiants
    Map<String, Map<String, String>> studentsData = {};
    for (var student in groupStudents) {
      String studentId = student['id'];
      studentsData[studentId] = {};
      
      // 4 semaines × 2 jours × 2 types = 16 cellules
      for (int week = 0; week < 4; week++) {
        for (int day = 0; day < 2; day++) {
          studentsData[studentId]!['${studentId}_w${week}_d${day}_tasmi3'] = '';
          studentsData[studentId]!['${studentId}_w${week}_d${day}_wajib'] = '';
        }
      }
    }

    attendanceSheets.insert(0, {
      "month": currentMonth,
      "students": studentsData,
      "isSaved": false,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text("قائمة المجموعات"),
          backgroundColor: Color(0xFF4F6F52),
          bottom: selectedGroupId != null
              ? TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(icon: Icon(Icons.people), text: 'معلومات المجموعة'),
                    Tab(icon: Icon(Icons.table_chart), text: 'جدول الحضور'),
                  ],
                )
              : null,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('groups')
              .where('profId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            List<QueryDocumentSnapshot> groupDocs = snapshot.data!.docs;

            return Column(
              children: [
                // Sélecteur de groupe
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "اختر المجموعة",
                      prefixIcon: Icon(Icons.group, color: Color(0xFF4F6F52)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
                      ),
                    ),
                    value: selectedGroupId,
                    items: groupDocs.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'مجموعة بدون اسم'),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedGroupId = value;
                        isLoadingStudents = true;
                      });
                      await _loadGroupDetails(value!);
                      await _loadExistingSheets();
                    },
                  ),
                ),

                // Contenu des onglets
                if (selectedGroupData != null)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildAttendanceTab(),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'الرجاء اختيار مجموعة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد مجموعات مسندة لك',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'يمكن للإدارة إضافة مجموعات جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Onglet Informations
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte récapitulatif
          Container(
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
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.groups, color: Colors.white, size: 40),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedGroupData!['name'] ?? 'مجموعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'عدد الطلاب: ${groupStudents.length}',
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

          // Horaires
          Container(
            padding: EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Color(0xFF4F6F52)),
                    SizedBox(width: 8),
                    Text(
                      'أوقات الحصص',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ..._buildSchedule(selectedGroupData!['schedule']),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Liste des étudiants
          Container(
            padding: EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Color(0xFF4F6F52)),
                    SizedBox(width: 8),
                    Text(
                      'قائمة الطلاب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (isLoadingStudents)
                  Center(child: CircularProgressIndicator())
                else if (groupStudents.isEmpty)
                  Center(
                    child: Text(
                      'لا يوجد طلاب في هذه المجموعة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...groupStudents.map((student) => _buildStudentCard(student)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Tableau de présence
  Widget _buildAttendanceTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ...attendanceSheets.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> sheet = entry.value;
                  return _buildAttendanceSheet(index, sheet);
                }).toList(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addNewSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4F6F52),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: Text("إضافة فيش حضور جديدة"),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSheet(int sheetIndex, Map<String, dynamic> sheet) {
    bool isSaved = sheet["isSaved"] ?? false;
    String? docId = sheet["docId"];
    String month = sheet["month"];
    Map<String, Map<String, String>> studentsData = sheet["students"];
    List<String> sessionDays = _getSessionDays();

    return Container(
      margin: EdgeInsets.only(bottom: 25),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSaved 
            ? Color.fromARGB(255, 255, 255, 255)
            : Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        children: [
          // Barre d'outils
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "الشهر: ${_getMonthName(month)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSaved ? Colors.grey.shade700 : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Save button
              if (!isSaved)
                InkWell(
                  onTap: () => _saveSheet(sheetIndex, sheet),
                  child: _roundedIcon(Icons.check, Colors.green),
                ),

              // Edit button
              if (isSaved)
                InkWell(
                  onTap: () {
                    setState(() {
                      sheet["isSaved"] = false;
                    });
                  },
                  child: _roundedIcon(Icons.edit, Colors.orange),
                ),

              SizedBox(width: 6),

              // Delete button
              InkWell(
                onTap: () => _deleteSheet(sheetIndex, docId),
                child: _roundedIcon(Icons.close, Colors.red),
              ),
            ],
          ),

          SizedBox(height: 10),

          // Tableau de présence scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(studentsData, sessionDays, isSaved),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, Map<String, String>> studentsData, List<String> sessionDays, bool isSaved) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header: Semaines
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4F6F52).withOpacity(0.2),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                SizedBox(width: 150), // Espace pour les noms
                ...List.generate(4, (week) {
                  return Container(
                    width: 240,
                    child: Center(
                      child: Text(
                        'الأسبوع ${week + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Header: Jours
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4F6F52).withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                SizedBox(width: 150),
                ...List.generate(4, (week) {
                  return Row(
                    children: sessionDays.map((day) {
                      return Container(
                        width: 120,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),

          // Header: ت/و
          Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Container(
                  width: 150,
                  child: Center(
                    child: Text(
                      'الاسم و اللقب',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F6F52)),
                    ),
                  ),
                ),
                ...List.generate(8, (index) {
                  return Row(
                    children: [
                      Container(
                        width: 60,
                        child: Center(
                          child: Text(
                            'ت',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        child: Center(
                          child: Text(
                            'و',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Lignes étudiants
          ...groupStudents.map((student) {
            String studentId = student['id'];
            Map<String, String> studentCells = studentsData[studentId] ?? {};

            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  // Nom
                  Container(
                    width: 150,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.03),
                      border: Border(left: BorderSide(color: Color(0xFF4F6F52).withOpacity(0.3), width: 2)),
                    ),
                    child: Text(
                      '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Cellules
                  ...List.generate(4, (week) {
                    return Row(
                      children: sessionDays.asMap().entries.map((entry) {
                        int dayIdx = entry.key;
                        return Row(
                          children: [
                            // Tasmi3
                            _buildCell(studentId, week, dayIdx, 'tasmi3', studentCells, isSaved),
                            // Wajib
                            _buildCell(studentId, week, dayIdx, 'wajib', studentCells, isSaved),
                          ],
                        );
                      }).toList().expand((x) => [x]).toList(),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCell(String studentId, int week, int day, String type, Map<String, String> studentCells, bool isSaved) {
    String key = '${studentId}_w${week}_d${day}_$type';
    String value = studentCells[key] ?? '';

    return Container(
      width: 60,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        color: value.isNotEmpty 
            ? (type == 'tasmi3' ? Colors.blue[50] : Colors.green[50])
            : (!isSaved ? Colors.grey[50] : Colors.white),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: !isSaved,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(4),
          hintText: !isSaved ? '...' : '',
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 10),
        ),
        onChanged: (val) {
          studentCells[key] = val;
        },
      ),
    );
  }

  Widget _roundedIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Future<void> _saveSheet(int index, Map<String, dynamic> sheet) async {
    try {
      setState(() {
        sheet["isSaved"] = true;
      });

      String docId = '${selectedGroupId}_${sheet["month"]}';

      await _firestore.collection('attendance').doc(docId).set({
        'groupId': selectedGroupId,
        'month': sheet["month"],
        'students': sheet["students"],
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      setState(() {
        sheet["docId"] = docId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ الفيش بنجاح ✓"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        sheet["isSaved"] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ أثناء الحفظ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteSheet(int index, String? docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تأكيد الحذف"),
        content: Text("هل تريد حذف هذا الجدول؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              if (docId != null) {
                try {
                  await _firestore.collection('attendance').doc(docId).delete();
                } catch (e) {
                  print('Erreur suppression: $e');
                }
              }
              
              setState(() {
                attendanceSheets.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: Text("حذف"),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    int totalHafd = (student['oldHafd'] ?? 0) + (student['newHafd'] ?? 0);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF4F6F52).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4F6F52).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF4F6F52),
            child: Text(
              (student['firstName'] ?? '؟')[0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  student['phone'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalHafd/60',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSchedule(dynamic schedule) {
    if (schedule == null || schedule is! List) {
      return [
        Text(
          "- لا توجد حصص محددة",
          style: TextStyle(color: Colors.grey),
        )
      ];
    }

    return (schedule as List).map((slot) {
      if (slot is Map<String, dynamic>) {
        String day = slot['day'] ?? '';
        String startTime = slot['startTime'] ?? '';
        String endTime = slot['endTime'] ?? '';
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF4F6F52).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF4F6F52).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                "$day: من $startTime إلى $endTime",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }
      return Text("- حصة غير محددة");
    }).toList();
  }

  List<String> _getSessionDays() {
    if (selectedGroupData == null || selectedGroupData!['schedule'] == null) {
      return ['اليوم 1', 'اليوم 2'];
    }

    List<dynamic> schedule = selectedGroupData!['schedule'];
    List<String> days = [];
    
    for (var slot in schedule) {
      if (slot is Map<String, dynamic> && slot['day'] != null) {
        String day = slot['day'];
        if (!days.contains(day)) {
          days.add(day);
        }
      }
    }

    if (days.isEmpty) {
      return ['اليوم 1', 'اليوم 2'];
    } else if (days.length == 1) {
      days.add('اليوم 2');
    }

    return days.take(2).toList();
  }

  Future<void> _loadGroupDetails(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        setState(() => isLoadingStudents = false);
        return;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> studentIds = List<String>.from(groupData['studentIds'] ?? []);

      List<Map<String, dynamic>> students = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
          studentData['id'] = studentDoc.id;
          students.add(studentData);
        }
      }

      setState(() {
        selectedGroupData = groupData;
        groupStudents = students;
        isLoadingStudents = false;
      });
    } catch (e) {
      print('Erreur load group: $e');
      setState(() => isLoadingStudents = false);
    }
  }
}