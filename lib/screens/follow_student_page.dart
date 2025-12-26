// lib/screens/teacher/follow_student_page.dart
// ✅ VERSION FINALE - Design vert + Sans overflow + Sauvegarde students_follow_up

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowStudentPage extends StatefulWidget {
  final String? groupId;
  final String studentId;
  final String firstName;
  final String lastName;

  const FollowStudentPage({
    super.key,
    this.groupId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<FollowStudentPage> createState() => _FollowStudentPageState();
}

class _FollowStudentPageState extends State<FollowStudentPage> {
  final List<Map<String, dynamic>> weeklyRecords = [];
  bool isLoading = true;
  String groupName = '';
  
  final Map<String, int> suras = {
    "الفاتحة": 7,
    "البقرة": 286,
    "آل عمران": 200,
    "النساء": 176,
    "المائدة": 120,
    "الأنعام": 165,
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
    _loadExistingRecords();
  }

  Future<void> _loadGroupInfo() async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .get();
      
      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          groupName = data['name'] ?? 'مجموعة';
        });
      }
    } catch (e) {
      print('Erreur chargement groupe: $e');
    }
  }

  // ✅ Charger depuis students_follow_up
  Future<void> _loadExistingRecords() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students_follow_up')
          .doc(widget.studentId)
          .collection('weekly_records')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        weeklyRecords.clear();
        
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          weeklyRecords.add({
            'ficheId': doc.id,
            'date': (data['date'] as Timestamp).toDate(),
            'sura': data['sura'] ?? '',
            'verseFrom': List<int>.from(data['verseFrom'] ?? List.filled(7, 1)),
            'verseTo': List<int>.from(data['verseTo'] ?? List.filled(7, 1)),
            'revision': List<String>.from(data['revision'] ?? List.filled(7, '')),
            'notes': data['notes'] ?? '',
            'isSaved': true,
          });
        }
        
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement fiches: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addNewRecord() {
    setState(() {
      weeklyRecords.insert(0, {
        'date': DateTime.now(),
        'sura': suras.keys.first,
        'verseFrom': List.filled(7, 1),
        'verseTo': List.filled(7, 1),
        'revision': List.filled(7, ''),
        'notes': '',
        'isSaved': false,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('جدول متابعة حفظ الطالب - ${widget.firstName} ${widget.lastName}'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)))
            : weeklyRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد صفحات متابعة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addNewRecord,
                          icon: Icon(Icons.add),
                          label: Text('إضافة صفحة متابعة جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4F6F52),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: weeklyRecords.length,
                    itemBuilder: (context, index) {
                      return _buildWeeklyCard(index, weeklyRecords[index]);
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewRecord,
          backgroundColor: Color(0xFF4F6F52),
          child: Icon(Icons.add),
          tooltip: "إضافة صفحة متابعة جديدة",
        ),
      ),
    );
  }

  Widget _buildWeeklyCard(int weekIndex, Map<String, dynamic> week) {
    bool isSaved = week["isSaved"] ?? false;
    DateTime date = week["date"];
    String sura = week["sura"];
    int maxVerse = suras[sura] ?? 1;

    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER AVEC DESIGN VERT + MODIFICATION DATE
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4F6F52).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date MODIFIABLE
                  Expanded(
                    child: InkWell(
                      onTap: isSaved
                          ? null
                          : () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  week["date"] = picked;
                                });
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4F6F52).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: isSaved ? null : Border.all(
                            color: Color(0xFF4F6F52),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isSaved)
                              Icon(Icons.calendar_today, 
                                   size: 16, 
                                   color: Color(0xFF4F6F52)),
                            if (!isSaved)
                              SizedBox(width: 4),
                            Text(
                              'تاريخ الحصة: ${date.day}-${date.month}-${date.year}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F6F52),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // Boutons
                  Row(
                    children: [
                      if (!isSaved)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.check, color: Colors.white, size: 24),
                            onPressed: () => _saveWeeklyRecord(weekIndex, week),
                            tooltip: "حفظ الصفحة",
                          ),
                        ),
                      if (isSaved)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.white, size: 24),
                            onPressed: () {
                              setState(() {
                                week["isSaved"] = false;
                              });
                            },
                            tooltip: "تعديل الصفحة",
                          ),
                        ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => _deleteWeeklyRecord(weekIndex, week),
                          tooltip: "حذف الصفحة",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ DROPDOWN SOURATE MODIFIABLE AVEC DESIGN VERT
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF4F6F52).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: isSaved ? null : Border.all(
                  color: Color(0xFF4F6F52),
                  width: 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: sura,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                dropdownColor: Colors.white,
                style: TextStyle(
                  color: Color(0xFF4F6F52),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: isSaved
                    ? null
                    : (val) {
                        setState(() {
                          week["sura"] = val!;
                        });
                      },
                items: suras.keys
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ TABLE HEADER VERT
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF4F6F52),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'اليوم',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'حفظ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'مراجعة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ✅ TABLE ROWS - SANS OVERFLOW
            Column(
              children: List.generate(7, (i) {
                List<String> days = [
                  'الإثنين',
                  'الثلاثاء',
                  'الأربعاء',
                  'الخميس',
                  'الجمعة',
                  'السبت',
                  'الأحد'
                ];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: i % 2 == 0 
                        ? Color(0xFF4F6F52).withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      // ✅ DAY NAME - RÉTRÉCI
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // ✅ VERSE FROM-TO - ÉLARGI
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // From
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 60),
                                child: DropdownButtonFormField<int>(
                                  value: week["verseFrom"][i],
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 11, color: Colors.black),
                                  onChanged: isSaved
                                      ? null
                                      : (val) {
                                          setState(() {
                                            week["verseFrom"][i] = val!;
                                          });
                                        },
                                  items: List.generate(maxVerse, (v) => v + 1)
                                      .map((v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(
                                              v.toString(),
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                            
                            // "إلى"
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3),
                              child: Text(
                                'إلى',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            
                            // To
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 60),
                                child: DropdownButtonFormField<int>(
                                  value: week["verseTo"][i],
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 11, color: Colors.black),
                                  onChanged: isSaved
                                      ? null
                                      : (val) {
                                          setState(() {
                                            week["verseTo"][i] = val!;
                                          });
                                        },
                                  items: List.generate(maxVerse, (v) => v + 1)
                                      .map((v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(
                                              v.toString(),
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ REVISION TEXT
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextFormField(
                            initialValue: week["revision"][i],
                            enabled: !isSaved,
                            onChanged: (val) => week["revision"][i] = val,
                            style: TextStyle(fontSize: 11),
                            decoration: InputDecoration(
                              hintText: "مراجعة اليوم",
                              hintStyle: TextStyle(fontSize: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ✅ NOTES AVEC DESIGN VERT
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4F6F52).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                initialValue: week["notes"],
                enabled: !isSaved,
                onChanged: (val) => week["notes"] = val,
                maxLines: 2,
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "ملاحظات إضافية للأسبوع القادم",
                  hintStyle: TextStyle(fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Sauvegarder dans students_follow_up
  Future<void> _saveWeeklyRecord(int weekIndex, Map<String, dynamic> week) async {
    try {
      setState(() {
        week["isSaved"] = true;
      });

      Map<String, dynamic> dataToSave = {
        'date': Timestamp.fromDate(week["date"]),
        'sura': week["sura"],
        'verseFrom': week["verseFrom"],
        'verseTo': week["verseTo"],
        'revision': week["revision"],
        'notes': week["notes"],
        'profId': _auth.currentUser!.uid,
        'groupId': widget.groupId,
      };

      // ✅ Si ficheId existe → UPDATE, sinon → CREATE
      if (week["ficheId"] != null) {
        // Modification d'une fiche existante
        await _firestore
            .collection('students_follow_up')
            .doc(widget.studentId)
            .collection('weekly_records')
            .doc(week["ficheId"])
            .update({
          ...dataToSave,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Création nouvelle fiche
        DocumentReference docRef = await _firestore
            .collection('students_follow_up')
            .doc(widget.studentId)
            .collection('weekly_records')
            .add({
          ...dataToSave,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          week["ficheId"] = docRef.id;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ الصفحة بنجاح ✓"),
          backgroundColor: Color(0xFF4F6F52),
        ),
      );
    } catch (e) {
      setState(() {
        week["isSaved"] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ أثناء الحفظ: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print('Erreur sauvegarde: $e');
    }
  }

  // ✅ Supprimer de students_follow_up
  Future<void> _deleteWeeklyRecord(int weekIndex, Map<String, dynamic> week) async {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
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
                Navigator.pop(ctx);
                
                if (week["isSaved"] == true && week["ficheId"] != null) {
                  try {
                    await _firestore
                        .collection('students_follow_up')
                        .doc(widget.studentId)
                        .collection('weekly_records')
                        .doc(week["ficheId"])
                        .delete();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم حذف الفيشة من قاعدة البيانات"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    print('Erreur suppression: $e');
                  }
                }
                
                setState(() {
                  weeklyRecords.removeAt(weekIndex);
                });
              },
              child: Text("حذف"),
            ),
          ],
        ),
      ),
    );
  }
}