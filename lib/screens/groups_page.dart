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
    
    // Générer les mois sans doublons
    Set<String> uniqueMonths = {};
    for (int i = -6; i <= 6; i++) {
      DateTime month = DateTime(now.year, now.month + i);
      String monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      uniqueMonths.add(monthKey);
    }
    
    // Convertir en liste et trier
    months = uniqueMonths.toList();
    months.sort();
    
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
          .get(); // Pas de orderBy pour éviter les index manquants

      setState(() {
        attendanceSheets.clear();
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Vérifier que les données existent
          if (data['month'] != null && data['students'] != null) {
            Map<String, Map<String, String>> studentsMap = {};
            
            // Convertir les données en format correct
            Map<String, dynamic> studentsData = data['students'] as Map<String, dynamic>;
            studentsData.forEach((studentId, cellsData) {
              if (cellsData is Map) {
                studentsMap[studentId] = Map<String, String>.from(cellsData);
              }
            });
            
            attendanceSheets.add({
              "docId": doc.id,
              "month": data['month'],
              "students": studentsMap,
              "isSaved": true,
            });
          }
        }
        
        // Trier par mois (plus récent en premier)
        attendanceSheets.sort((a, b) => b['month'].compareTo(a['month']));
      });
    } catch (e) {
      print('Erreur chargement fiches: $e');
      // Ne pas bloquer l'interface si erreur
      setState(() {
        attendanceSheets.clear();
      });
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

            // Si aucun groupe sélectionné, afficher la liste des groupes
            if (selectedGroupId == null) {
              return _buildGroupsList(groupDocs);
            }

            // Si un groupe est sélectionné, afficher les onglets
            return Column(
              children: [
                // Barre avec le groupe sélectionné
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bouton retour
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedGroupId = null;
                            selectedGroupData = null;
                            groupStudents.clear();
                            attendanceSheets.clear();
                          });
                        },
                        icon: Icon(Icons.arrow_back, color: Color(0xFF4F6F52)),
                        tooltip: 'العودة للمجموعات',
                      ),
                      SizedBox(width: 12),
                      // Nom du groupe sélectionné
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.group, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedGroupData?['name'] ?? 'مجموعة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${groupStudents.length} طالب',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu des onglets - Vérifier que tout est chargé
                if (selectedGroupData != null && !isLoadingStudents)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildAttendanceTab(),
                      ],
                    ),
                  )
                else if (isLoadingStudents)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF4F6F52),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري تحميل البيانات...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'حدث خطأ في التحميل',
                        style: TextStyle(color: Colors.grey),
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

  // Nouvelle méthode : Afficher la liste des groupes
  Widget _buildGroupsList(List<QueryDocumentSnapshot> groupDocs) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر مجموعة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),
          ...groupDocs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildGroupCard(doc.id, data);
          }).toList(),
        ],
      ),
    );
  }

  // Carte de groupe
  Widget _buildGroupCard(String groupId, Map<String, dynamic> groupData) {
    return InkWell(
      onTap: () async {
        try {
          setState(() {
            selectedGroupId = groupId;
            selectedGroupData = groupData; // Définir immédiatement
            isLoadingStudents = true;
          });
          
          await _loadGroupDetails(groupId);
          await _loadExistingSheets();
        } catch (e) {
          print('Erreur clic groupe: $e');
          setState(() {
            selectedGroupId = null;
            selectedGroupData = null;
            isLoadingStudents = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ في تحميل المجموعة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
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
                    groupData['name'] ?? 'مجموعة بدون اسم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'انقر للدخول',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          ],
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
    
    // Vérifier que le mois existe dans la liste
    if (!months.contains(month)) {
      // Si le mois n'existe pas, utiliser le mois actuel
      month = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      sheet["month"] = month;
    }
    
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
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: month,
                    isExpanded: true,
                    underline: SizedBox(),
                    onChanged: isSaved
                        ? null
                        : (val) {
                            setState(() {
                              sheet["month"] = val!;
                            });
                          },
                    items: months.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          _getMonthName(m),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSaved ? Colors.grey.shade700 : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
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
    // Vérifier que les jours de session sont valides
    if (sessionDays.isEmpty) {
      sessionDays = ['اليوم 1', 'اليوم 2'];
    }
    
    // Vérifier qu'on a des étudiants
    if (groupStudents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'لا يوجد طلاب في هذه المجموعة',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

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
                    width: 320, // 4 cellules × 80px = 320px (au lieu de 240)
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
                        width: 160, // 2 cellules × 80px = 160px (au lieu de 120)
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
                        width: 80, // Au lieu de 60
                        child: Center(
                          child: Text(
                            'ت',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                          ),
                        ),
                      ),
                      Container(
                        width: 80, // Au lieu de 60
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
      width: 80,  // Plus large (au lieu de 60)
      height: 90, // Plus haut pour 3 lignes (au lieu de 50)
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
        maxLines: 3, // Permettre 3 lignes
        minLines: 1, // Minimum 1 ligne
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          hintText: !isSaved ? '...' : '',
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 10),
          isDense: true,
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
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text("تأكيد الحذف"),
          content: Text("هل تريد حذف هذا الجدول؟\nلا يمكن التراجع عن هذا الإجراء."),
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
                Navigator.pop(ctx); // Fermer le dialogue d'abord
                
                // Si déjà sauvegardé dans Firestore, supprimer
                if (docId != null) {
                  try {
                    await _firestore.collection('attendance').doc(docId).delete();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حذف الفيش من قاعدة البيانات بنجاح'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    print('Erreur suppression Firestore: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ في الحذف: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return; // Ne pas supprimer localement si erreur
                  }
                }
                
                // Supprimer de la liste locale
                setState(() {
                  attendanceSheets.removeAt(index);
                });
              },
              child: Text("حذف"),
            ),
          ],
        ),
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
      setState(() {
        isLoadingStudents = true;
      });

      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        setState(() {
          isLoadingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('المجموعة غير موجودة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> studentIds = List<String>.from(groupData['studentIds'] ?? []);

      // Charger les étudiants
      List<Map<String, dynamic>> students = [];
      for (String studentId in studentIds) {
        try {
          DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
          if (studentDoc.exists) {
            Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
            studentData['id'] = studentDoc.id;
            students.add(studentData);
          }
        } catch (e) {
          print('Erreur chargement étudiant $studentId: $e');
        }
      }

      setState(() {
        selectedGroupData = groupData;
        groupStudents = students;
        isLoadingStudents = false;
      });
    } catch (e) {
      print('Erreur load group: $e');
      setState(() {
        isLoadingStudents = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل المجموعة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}