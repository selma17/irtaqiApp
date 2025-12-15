// lib/screens/groups_page.dart - VERSION CORRIGÉE FIRESTORE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedGroupId;
  Map<String, dynamic>? selectedGroupData;
  List<Map<String, dynamic>> groupStudents = [];
  bool isLoadingStudents = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("قائمة المجموعات"),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: StreamBuilder<QuerySnapshot>(
          // Charger groupes du prof connecté
          stream: _firestore
              .collection('groups')
              .where('profId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('حدث خطأ: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

            List<QueryDocumentSnapshot> groupDocs = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("اختر المجموعة:", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),

                  // DROPDOWN SÉLECTION GROUPE
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "اختر المجموعة",
                      border: OutlineInputBorder(),
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
                    },
                  ),

                  SizedBox(height: 20),

                  // AFFICHER DÉTAILS GROUPE SI SÉLECTIONNÉ
                  if (selectedGroupData != null) ...[
                    // Nombre d'étudiants
                    Text(
                      "عدد الطلاب بالمجموعة: ${groupStudents.length}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 20),

                    // Horaires
                    Text(
                      "اوقات الحصص:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._buildSchedule(selectedGroupData!['schedule']),

                    SizedBox(height: 20),

                    // TABLEAU ÉTUDIANTS
                    if (isLoadingStudents)
                      Center(child: CircularProgressIndicator())
                    else if (groupStudents.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'لا يوجد طلاب في هذه المجموعة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Color(0xFF4F6F52).withOpacity(0.1),
                            ),
                            columns: [
                              DataColumn(label: Text("الاسم")),
                              DataColumn(label: Text("اللقب")),
                              DataColumn(label: Text("العمر")),
                              DataColumn(label: Text("الهاتف")),
                              DataColumn(label: Text("البريد الإلكتروني")),
                              DataColumn(label: Text("الحفظ")),
                            ],
                            rows: groupStudents.map((student) {
                              int totalHafd = (student['oldHafd'] ?? 0) + (student['newHafd'] ?? 0);
                              return DataRow(cells: [
                                DataCell(Text(student['firstName'] ?? '')),
                                DataCell(Text(student['lastName'] ?? '')),
                                DataCell(Text((student['age'] ?? 0).toString())),
                                DataCell(Text(student['phone'] ?? '')),
                                DataCell(Text(student['email'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('$totalHafd/60'),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),

                    SizedBox(height: 20),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Charger détails du groupe + étudiants
  Future<void> _loadGroupDetails(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        setState(() {
          isLoadingStudents = false;
        });
        return;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> studentIds = List<String>.from(groupData['studentIds'] ?? []);

      // Charger données de chaque étudiant
      List<Map<String, dynamic>> students = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();

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
      print('❌ Erreur load group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل المجموعة'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoadingStudents = false;
      });
    }
  }

  // Construire liste horaires
  List<Widget> _buildSchedule(dynamic schedule) {
    if (schedule == null || schedule is! List) {
      return [Text("- لا توجد حصص محددة")];
    }

    return (schedule as List).map((slot) {
      if (slot is Map<String, dynamic>) {
        String day = slot['day'] ?? '';
        String startTime = slot['startTime'] ?? '';
        String endTime = slot['endTime'] ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text("- $day: من $startTime إلى $endTime"),
        );
      }
      return Text("- حصة غير محددة");
    }).toList();
  }
}