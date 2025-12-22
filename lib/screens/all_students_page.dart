// lib/screens/teacher/all_students_page.dart - VERSION CORRIGÉE
// ✅ N'affiche QUE les étudiants des groupes du professeur connecté

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

  // ✅ Charger les IDs des étudiants des groupes du prof
  Future<void> _loadMyStudentIds() async {
    try {
      String profId = _auth.currentUser?.uid ?? '';
      
      // 1. Récupérer tous les groupes du prof
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: profId)
          .get();
      
      // 2. Extraire tous les studentIds de tous les groupes
      Set<String> studentIds = {};
      for (var groupDoc in groupsSnapshot.docs) {
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        List<dynamic> groupStudentIds = groupData['studentIds'] ?? [];
        studentIds.addAll(groupStudentIds.cast<String>());
      }
      
      setState(() {
        _myStudentIds = studentIds.toList();
        _isLoadingStudentIds = false;
      });
      
      print('✅ Prof a ${_myStudentIds.length} étudiants dans ses groupes');
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
        appBar: AppBar(
          title: Text("قائمة تلاميذي"),
          backgroundColor: Color(0xFF4F6F52),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoadingStudentIds = true;
                });
                _loadMyStudentIds();
              },
            ),
          ],
        ),
        body: _isLoadingStudentIds
            ? Center(child: CircularProgressIndicator())
            : _myStudentIds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد طلاب في مجموعاتك',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يرجى إضافة طلاب إلى مجموعاتك',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    // ✅ Filtrer par les IDs des étudiants du prof
                    stream: _buildStudentsStream(),
                    builder: (context, snapshot) {
                      // Chargement
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // Erreur
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 60, color: Colors.red),
                              SizedBox(height: 16),
                              Text('حدث خطأ في تحميل البيانات'),
                              SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Pas de données
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا يوجد طلاب حاليًا',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      // ✅ Données disponibles
                      List<QueryDocumentSnapshot> students = snapshot.data!.docs;

                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header avec nombre d'étudiants
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF4F6F52).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.people, color: Color(0xFF4F6F52)),
                                  SizedBox(width: 8),
                                  Text(
                                    'عدد الطلاب: ${students.length}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Table
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                    Color(0xFF4F6F52).withOpacity(0.1),
                                  ),
                                  columns: [
                                    DataColumn(label: Text("رقم", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("الاسم", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("اللقب", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("المجموعة", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("العمر", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("الهاتف", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("البريد", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("تاريخ الانضمام", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("الحفظ الحالي", style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: List.generate(
                                    students.length,
                                    (index) {
                                      var doc = students[index];
                                      var data = doc.data() as Map<String, dynamic>;
                                      
                                      String studentId = doc.id;
                                      String firstName = data['firstName'] ?? '';
                                      String lastName = data['lastName'] ?? '';
                                      String groupId = data['groupId'] ?? '';
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
                                      
                                      // Calcul du hafd total
                                      int oldHafd = data['oldHafd'] ?? 0;
                                      int newHafd = data['newHafd'] ?? 0;
                                      int totalHafd = oldHafd + newHafd;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text((index + 1).toString())),
                                          
                                          // Cellule du prénom - CLIQUABLE
                                          DataCell(
                                            Text(
                                              firstName,
                                              style: TextStyle(
                                                color: Color(0xFF4F6F52),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: () => _navigateToFollowPage(
                                              context,
                                              studentId,
                                              groupId,
                                              firstName,
                                              lastName,
                                            ),
                                          ),
                                          
                                          // Cellule du nom - CLIQUABLE
                                          DataCell(
                                            Text(
                                              lastName,
                                              style: TextStyle(
                                                color: Color(0xFF4F6F52),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: () => _navigateToFollowPage(
                                              context,
                                              studentId,
                                              groupId,
                                              firstName,
                                              lastName,
                                            ),
                                          ),
                                          
                                          // Nom du groupe (async)
                                          DataCell(
                                            FutureBuilder<String>(
                                              future: _getGroupName(groupId),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Text(snapshot.data ?? '-');
                                                }
                                                return SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                );
                                              },
                                            ),
                                          ),
                                          
                                          DataCell(Text(age.toString())),
                                          DataCell(Text(phone)),
                                          DataCell(
                                            Container(
                                              constraints: BoxConstraints(maxWidth: 150),
                                              child: Text(
                                                email,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(dateInscription)),
                                          DataCell(
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF4F6F52).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                totalHafd.clamp(0, 60).toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4F6F52),
                                                ),
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
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // ✅ Construire le stream des étudiants du prof
  Stream<QuerySnapshot> _buildStudentsStream() {
    // Firestore limite whereIn à 10 éléments
    // Si plus de 10 étudiants, on doit faire plusieurs requêtes
    
    if (_myStudentIds.length <= 10) {
      // Cas simple: <= 10 étudiants
      return _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: _myStudentIds)
          .where('isActive', isEqualTo: true)
          .orderBy('firstName')
          .snapshots();
    } else {
      // Cas complexe: > 10 étudiants
      // On prend les 10 premiers pour l'instant
      // TODO: Implémenter pagination ou combiner plusieurs streams
      List<String> first10 = _myStudentIds.take(10).toList();
      return _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: first10)
          .where('isActive', isEqualTo: true)
          .orderBy('firstName')
          .snapshots();
    }
  }

  // ✅ Fonction pour naviguer vers FollowStudentPage
  void _navigateToFollowPage(
    BuildContext context,
    String studentId,
    String groupId,
    String firstName,
    String lastName,
  ) {
    // Vérifier si l'étudiant a un groupe
    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هذا الطالب غير مسجل في أي مجموعة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowStudentPage(
          groupId: groupId,
          studentId: studentId,
          firstName: firstName,
          lastName: lastName,
        ),
      ),
    );
  }

  // ✅ Fonction pour récupérer le nom du groupe
  Future<String> _getGroupName(String groupId) async {
    if (groupId.isEmpty) return '-';
    
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        return data['name'] ?? '-';
      }
    } catch (e) {
      print('Erreur récupération groupe: $e');
    }
    
    return '-';
  }
}