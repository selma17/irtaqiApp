// lib/screens/all_students_page.dart - VERSION AVEC GROUPID

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_student_page.dart';

class AllStudentsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("قائمة التلاميذ"),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: StreamBuilder<QuerySnapshot>(
          // ✅ Récupère les étudiants depuis Firestore
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'etudiant')
              .where('isActive', isEqualTo: true)
              .orderBy('firstName')
              .snapshots(),
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
                      'لا يوجد طلاب حالياً',
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text("رقم")),
                    DataColumn(label: Text("الاسم")),
                    DataColumn(label: Text("اللقب")),
                    DataColumn(label: Text("المجموعة")), // ✅ AJOUTÉ
                    DataColumn(label: Text("العمر")),
                    DataColumn(label: Text("الهاتف")),
                    DataColumn(label: Text("البريد")),
                    DataColumn(label: Text("تاريخ الانضمام")),
                    DataColumn(label: Text("الحفظ الحالي")),
                  ],
                  rows: List.generate(
                    students.length,
                    (index) {
                      // ✅ Récupère le document et les données
                      var doc = students[index];
                      var data = doc.data() as Map<String, dynamic>;
                      
                      // ✅ L'ID Firebase (UID) est dans doc.id
                      String studentId = doc.id;
                      
                      // Données de l'étudiant
                      String firstName = data['firstName'] ?? '';
                      String lastName = data['lastName'] ?? '';
                      String groupId = data['groupId'] ?? ''; // ✅ RÉCUPÉRÉ
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
                          
                          // ✅ Cellule du prénom - CLIQUABLE
                          DataCell(
                            Text(firstName),
                            onTap: () => _navigateToFollowPage(
                              context,
                              studentId,
                              groupId,
                              firstName,
                              lastName,
                            ),
                          ),
                          
                          // ✅ Cellule du nom - CLIQUABLE
                          DataCell(
                            Text(lastName),
                            onTap: () => _navigateToFollowPage(
                              context,
                              studentId,
                              groupId,
                              firstName,
                              lastName,
                            ),
                          ),
                          
                          // ✅ Nom du groupe (async)
                          DataCell(
                            FutureBuilder<String>(
                              future: _getGroupName(groupId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(snapshot.data ?? '-');
                                }
                                return Text('-');
                              },
                            ),
                          ),
                          
                          DataCell(Text(age.toString())),
                          DataCell(Text(phone)),
                          DataCell(Text(email)),
                          DataCell(Text(dateInscription)),
                          DataCell(Text(totalHafd.clamp(0, 60).toString())),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
          groupId: groupId,      // ✅ PASSÉ
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