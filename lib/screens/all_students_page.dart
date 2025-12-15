// lib/screens/all_students_page.dart - VERSION FINALE AVEC studentId

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'follow_student_page.dart';

class AllStudentsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'etudiant')
              .where('isActive', isEqualTo: true)
              .orderBy('firstName')
              .snapshots(),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Erreur
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
                      'لا يوجد طلاب مسجلين',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يمكن للإدارة إضافة طلاب جدد',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Données disponibles
            List<DocumentSnapshot> studentsDocs = snapshot.data!.docs;

            return Padding(
              padding: EdgeInsets.all(16),
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
                    DataColumn(label: Text("العمر", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("الهاتف", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("البريد", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("المجموعة", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("الحفظ القديم", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("الحفظ الجديد", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("المجموع", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(
                    studentsDocs.length,
                    (index) {
                      DocumentSnapshot doc = studentsDocs[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                      String studentId = doc.id;  // ✅ ID Firebase réel
                      String firstName = data['firstName'] ?? '';
                      String lastName = data['lastName'] ?? '';
                      int age = data['age'] ?? 0;
                      String phone = data['phone'] ?? '';
                      String email = data['email'] ?? '';
                      String groupId = data['groupId'] ?? '';
                      int oldHafd = data['oldHafd'] ?? 0;
                      int newHafd = data['newHafd'] ?? 0;
                      int totalHafd = oldHafd + newHafd;

                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          
                          // NOM cliquable
                          DataCell(
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowStudentPage(
                                      studentId: studentId,  // ✅ AJOUTÉ
                                      firstName: firstName,
                                      lastName: lastName,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                firstName,
                                style: TextStyle(
                                  color: Color(0xFF4F6F52),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          
                          // PRÉNOM cliquable
                          DataCell(
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowStudentPage(
                                      studentId: studentId,  // ✅ AJOUTÉ
                                      firstName: firstName,
                                      lastName: lastName,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                lastName,
                                style: TextStyle(
                                  color: Color(0xFF4F6F52),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          
                          DataCell(Text(age.toString())),
                          DataCell(Text(phone)),
                          DataCell(Text(email)),
                          
                          // GROUPE (avec fetch nom)
                          DataCell(
                            FutureBuilder<String>(
                              future: _getGroupName(groupId),
                              builder: (context, groupSnapshot) {
                                if (groupSnapshot.connectionState == ConnectionState.waiting) {
                                  return SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: groupSnapshot.data != 'بدون مجموعة'
                                        ? Color(0xFF4F6F52).withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    groupSnapshot.data ?? 'بدون مجموعة',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$oldHafd/60'),
                            ),
                          ),
                          
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$newHafd/60'),
                            ),
                          ),
                          
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$totalHafd/60',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
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

  /// Récupérer nom du groupe
  Future<String> _getGroupName(String? groupId) async {
    if (groupId == null || groupId.isEmpty) {
      return 'بدون مجموعة';
    }

    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        return (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'بدون مجموعة';
      }
    } catch (e) {
      print('❌ Erreur get group name: $e');
    }

    return 'بدون مجموعة';
  }
}