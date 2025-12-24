// lib/screens/all_students_page.dart
// ✅ VERSION TABLEAU AMÉLIORÉ - Belles couleurs et mise en page moderne

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_student_page.dart';

class AllStudentsPage extends StatefulWidget {
  @override
  _AllStudentsPageState createState() => _AllStudentsPageState();
}

class _AllStudentsPageState extends State<AllStudentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<String> _myStudentIds = [];
  bool _isLoadingStudentIds = true;

  @override
  void initState() {
    super.initState();
    _loadMyStudentIds();
  }

  Future<void> _loadMyStudentIds() async {
    try {
      String profId = _auth.currentUser?.uid ?? '';
      print('🔍 Chargement étudiants pour prof: $profId');
      
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: profId)
          .get();
      
      print('📊 Nombre de groupes du prof: ${groupsSnapshot.docs.length}');
      
      Set<String> studentIds = {};
      for (var groupDoc in groupsSnapshot.docs) {
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        List<dynamic> groupStudentIds = groupData['studentIds'] ?? [];
        print('   - Groupe ${groupData['name']}: ${groupStudentIds.length} étudiants');
        studentIds.addAll(groupStudentIds.cast<String>());
      }
      
      setState(() {
        _myStudentIds = studentIds.toList();
        _isLoadingStudentIds = false;
      });
      
      print('✅ Total: ${_myStudentIds.length} étudiants uniques dans les groupes du prof');
    } catch (e) {
      print('❌ Erreur chargement student IDs: $e');
      setState(() {
        _isLoadingStudentIds = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text(
            "قائمة تلاميذي",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          actions: [
            if (!_isLoadingStudentIds)
              Container(
                margin: EdgeInsets.only(left: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '${_myStudentIds.length}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: _isLoadingStudentIds
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4F6F52), strokeWidth: 3),
                    SizedBox(height: 20),
                    Text(
                      'جاري تحميل قائمة الطلاب...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildStudentsList()),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.table_chart, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قائمة الطلاب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'إجمالي ${_myStudentIds.length} طالب في مجموعاتك',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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

  Widget _buildStudentsList() {
    if (_myStudentIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 100, color: Colors.grey[300]),
            SizedBox(height: 24),
            Text(
              'لا توجد طلاب في مجموعاتك',
              style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'قم بإضافة طلاب إلى مجموعاتك أولاً',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return Center(child: Text('لا توجد بيانات'));
        }

        // Filtrer par groupes du prof
        List<QueryDocumentSnapshot> allStudents = snapshot.data!.docs;
        List<QueryDocumentSnapshot> myStudents = allStudents.where((doc) {
          return _myStudentIds.contains(doc.id);
        }).toList();

        // Trier par prénom
        myStudents.sort((a, b) {
          String nameA = (a.data() as Map<String, dynamic>)['firstName'] ?? '';
          String nameB = (b.data() as Map<String, dynamic>)['firstName'] ?? '';
          return nameA.compareTo(nameB);
        });

        if (myStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 80, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'لا يوجد طلاب نشطون في مجموعاتك',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 56,
                dataRowHeight: 70,
                columnSpacing: 30,
                horizontalMargin: 20,
                headingRowColor: MaterialStateProperty.all(
                  Color(0xFF4F6F52).withOpacity(0.1),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF4F6F52).withOpacity(0.2), width: 2),
                  ),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'رقم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الاسم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'اللقب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.cake, size: 16, color: Color(0xFF4F6F52)),
                        SizedBox(width: 6),
                        Text(
                          'العمر',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Color(0xFF4F6F52)),
                        SizedBox(width: 6),
                        Text(
                          'الهاتف',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Color(0xFF4F6F52)),
                        SizedBox(width: 6),
                        Text(
                          'البريد',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Color(0xFF4F6F52)),
                        SizedBox(width: 6),
                        Text(
                          'تاريخ الانضمام',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.menu_book, size: 16, color: Color(0xFF4F6F52)),
                        SizedBox(width: 6),
                        Text(
                          'الحفظ الحالي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                rows: List.generate(
                  myStudents.length,
                  (index) {
                    var doc = myStudents[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String studentId = doc.id;
                    String firstName = data['firstName'] ?? '';
                    String lastName = data['lastName'] ?? '';
                    int age = data['age'] ?? 0;
                    String phone = data['phone'] ?? '';
                    String email = data['email'] ?? '';
                    
                    // Date d'inscription
                    String dateInscription = '';
                    if (data['dateInscription'] != null) {
                      Timestamp timestamp = data['dateInscription'];
                      DateTime date = timestamp.toDate();
                      dateInscription = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    }
                    
                    // Hafd total
                    int oldHafd = data['oldHafd'] ?? 0;
                    int newHafd = data['newHafd'] ?? 0;
                    int totalHafd = (oldHafd + newHafd).clamp(0, 60);
                    
                    // Couleur alternée pour les lignes
                    Color rowColor = index % 2 == 0 
                        ? Colors.grey[50]! 
                        : Colors.white;

                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        // Numéro
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF4F6F52).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (index + 1).toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF4F6F52),
                              ),
                            ),
                          ),
                        ),
                        
                        // Prénom - CLIQUABLE
                        DataCell(
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowStudentPage(
                                    studentId: studentId,
                                    firstName: firstName,
                                    lastName: lastName,
                                    groupId: null,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                firstName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F6F52),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Nom - CLIQUABLE
                        DataCell(
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowStudentPage(
                                    studentId: studentId,
                                    firstName: firstName,
                                    lastName: lastName,
                                    groupId: null,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                lastName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F6F52),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Âge
                        DataCell(
                          Text(
                            '$age سنة',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),
                        
                        // Téléphone
                        DataCell(
                          Text(
                            phone,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),
                        
                        // Email
                        DataCell(
                          Text(
                            email,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                        
                        // Date inscription
                        DataCell(
                          Text(
                            dateInscription,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                        
                        // Hafd - AVEC BADGE COLORÉ
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getHafdColor(totalHafd).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getHafdColor(totalHafd).withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  totalHafd.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getHafdColor(totalHafd),
                                  ),
                                ),
                                Text(
                                  ' / 60',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getHafdColor(totalHafd).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHafdColor(int hafd) {
    if (hafd >= 50) return Color(0xFF2E7D32); // Vert foncé
    if (hafd >= 30) return Color(0xFF1976D2); // Bleu
    if (hafd >= 15) return Color(0xFFF57C00); // Orange
    return Color(0xFFD32F2F); // Rouge
  }

  Widget _buildErrorWidget(String error) {
    print('');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║  ❌ ERREUR LISTE ÉTUDIANTS                                 ║');
    print('╚════════════════════════════════════════════════════════════╝');
    print('📋 ERREUR: $error');
    
    if (error.contains('https://')) {
      int start = error.indexOf('https://');
      String remaining = error.substring(start);
      int end = remaining.indexOf(' ');
      if (end == -1) end = remaining.indexOf('\n');
      if (end == -1) end = remaining.length;
      String link = remaining.substring(0, end);
      print('');
      print('🔗 LIEN INDEX: $link');
      print('👉 COPIE et OUVRE dans navigateur → Create Index');
      print('════════════════════════════════════════════════════════════');
    }
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            SizedBox(height: 24),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'راجع Terminal للحصول على رابط الفهرس',
                style: TextStyle(fontSize: 15, color: Colors.red[900]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}