// lib/screens/all_students_page.dart

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
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text("قائمة التلاميذ"),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'etudiant')
              .where('isActive', isEqualTo: true)
              .orderBy('firstName')
              .snapshots(),
          builder: (context, snapshot) {
            // Chargement
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF4F6F52),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل قائمة الطلاب...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
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
                      style: TextStyle(fontSize: 18, color: Colors.red),
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
                      'لا يوجد طلاب حالياً',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Données disponibles
            List<QueryDocumentSnapshot> students = snapshot.data!.docs;

            return Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(16),
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
                        child: Icon(Icons.people, color: Colors.white, size: 32),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي الطلاب',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${students.length} طالب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                    ],
                  ),
                ),

                // Tableau des étudiants
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Color(0xFF4F6F52).withOpacity(0.1),
                              ),
                              headingRowHeight: 56,
                              dataRowHeight: 64,
                              columnSpacing: 20,
                              horizontalMargin: 20,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    "رقم",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "الاسم",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "اللقب",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "العمر",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "الهاتف",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "البريد",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "تاريخ الانضمام",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "الحفظ الحالي",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF4F6F52),
                                    ),
                                  ),
                                ),
                              ],
                              rows: List.generate(
                                students.length,
                                (index) {
                                  var doc = students[index];
                                  var data = doc.data() as Map<String, dynamic>;
                                  
                                  String studentId = doc.id;
                                  String firstName = data['firstName'] ?? '';
                                  String lastName = data['lastName'] ?? '';
                                  int age = data['age'] ?? 0;
                                  String phone = data['phone'] ?? '';
                                  String email = data['email'] ?? '';
                                  
                                  String dateInscription = '';
                                  if (data['dateInscription'] != null) {
                                    Timestamp timestamp = data['dateInscription'];
                                    DateTime date = timestamp.toDate();
                                    dateInscription = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                  }
                                  
                                  int oldHafd = data['oldHafd'] ?? 0;
                                  int newHafd = data['newHafd'] ?? 0;
                                  int totalHafd = oldHafd + newHafd;

                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color?>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return Color(0xFF4F6F52).withOpacity(0.05);
                                        }
                                        return index % 2 == 0
                                            ? Colors.grey[50]
                                            : Colors.white;
                                      },
                                    ),
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            (index + 1).toString(),
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      
                                      // Cellule du prénom - CLIQUABLE
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
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Text(
                                                  firstName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF4F6F52),
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.open_in_new,
                                                  size: 14,
                                                  color: Color(0xFF4F6F52),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Cellule du nom - CLIQUABLE
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
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Text(
                                                  lastName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF4F6F52),
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.open_in_new,
                                                  size: 14,
                                                  color: Color(0xFF4F6F52),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            age.toString(),
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            phone,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            email,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            dateInscription,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: totalHafd >= 60
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${totalHafd.clamp(0, 60)}/60',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: totalHafd >= 60
                                                  ? Colors.green[900]
                                                  : Colors.blue[900],
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
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}