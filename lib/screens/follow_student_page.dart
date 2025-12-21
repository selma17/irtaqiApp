// lib/screens/teacher/follow_student_page.dart - VERSION AVEC SYNCHRONISATION ADMIN

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowStudentPage extends StatefulWidget {
  final String groupId;     // ✅ ID du groupe
  final String studentId;   // ✅ UID Firebase de l'étudiant
  final String firstName;
  final String lastName;

  const FollowStudentPage({
    super.key,
    required this.groupId,    // ✅ AJOUTÉ pour sync admin
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

  // ✅ Charger les infos du groupe
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

  // ✅ Charger les fiches existantes depuis attendance
  Future<void> _loadExistingRecords() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // ✅ CORRIGÉ: Requête simplifiée sans orderBy pour éviter erreur d'index
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('groupId', isEqualTo: widget.groupId)
          .where('profId', isEqualTo: _auth.currentUser?.uid)
          .get();

      setState(() {
        weeklyRecords.clear();
        
        // ✅ Liste temporaire pour trier
        List<Map<String, dynamic>> tempRecords = [];
        
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Map<String, dynamic> weeklyData = data['weeklyRecords'] ?? {};
          
          // Pour chaque semaine dans le document
          weeklyData.forEach((weekKey, weekValue) {
            if (weekValue is Map && weekValue.containsKey('students')) {
              Map<String, dynamic> students = weekValue['students'];
              
              // Vérifier si cet étudiant est dans cette semaine
              if (students.containsKey(widget.studentId)) {
                Map<String, dynamic> studentData = students[widget.studentId];
                
                // Reconstruire le format attendu
                tempRecords.add({
                  "docId": doc.id,
                  "weekKey": weekKey,
                  "month": data['month'],
                  "date": (studentData['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  "sura": studentData['sura'] ?? suras.keys.first,
                  "verseFrom": List<int>.from(studentData['verseFrom'] ?? List.filled(7, 1)),
                  "verseTo": List<int>.from(studentData['verseTo'] ?? List.filled(7, 1)),
                  "revision": List<String>.from(studentData['revision'] ?? List.filled(7, "")),
                  "notes": studentData['notes'] ?? "",
                  "isSaved": true,
                });
              }
            }
          });
        }
        
        // ✅ Trier par date décroissante EN MÉMOIRE
        tempRecords.sort((a, b) => (b["date"] as DateTime).compareTo(a["date"] as DateTime));
        
        // Ajouter à la liste finale
        weeklyRecords.addAll(tempRecords);
        
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement fiches: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addEmptyWeek() {
    weeklyRecords.insert(0, {
      "date": DateTime.now(),
      "sura": suras.keys.first,
      "verseFrom": List.filled(7, 1),
      "verseTo": List.filled(7, 1),
      "revision": List.filled(7, ""),
      "notes": "",
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
          title: Text("جدول متابعة حفظ الطالب - ${widget.firstName} ${widget.lastName}"),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF4F6F52),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل فيش المتابعة...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : weeklyRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد فيش متابعة لهذا الطالب',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addEmptyWeek,
                          icon: Icon(Icons.add),
                          label: Text("إضافة فيش متابعة جديدة"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4F6F52),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...weeklyRecords.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> week = entry.value;
                          return _buildWeekTable(index, week);
                        }).toList(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _addEmptyWeek,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4F6F52),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: Text("إضافة صفحة متابعة جديدة"),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: _showTestForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4F6F52),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: Text("تخطيط اختبار"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWeekTable(int weekIndex, Map<String, dynamic> week) {
    bool isSaved = week["isSaved"] ?? false;
    String? docId = week["docId"];
    String? weekKey = week["weekKey"];

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSaved 
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isSaved
                      ? null
                      : () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: week["date"],
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              week["date"] = picked;
                            });
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "تاريخ الحصة: ${week["date"].toLocal().toString().split(' ')[0]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSaved ? Colors.grey.shade700 : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ✅ SAVE BUTTON
              if (!isSaved)
                InkWell(
                  onTap: () => _saveWeeklyRecord(weekIndex, week),
                  child: _roundedIcon(Icons.check, Colors.green),
                ),

              // ✅ EDIT BUTTON
              if (isSaved)
                InkWell(
                  onTap: () {
                    setState(() {
                      week["isSaved"] = false;
                    });
                  },
                  child: _roundedIcon(Icons.edit, Colors.orange),
                ),

              const SizedBox(width: 6),

              // ❌ DELETE BUTTON
              InkWell(
                onTap: () => _deleteWeeklyRecord(weekIndex, week),
                child: _roundedIcon(Icons.close, Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // SURAT DROPDOWN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: week["sura"],
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: isSaved
                  ? null
                  : (val) {
                      setState(() {
                        week["sura"] = val!;
                        int maxVerse = suras[val]!;
                        for (int i = 0; i < 7; i++) {
                          week["verseFrom"][i] = 1;
                          week["verseTo"][i] = maxVerse;
                        }
                      });
                    },
              items: suras.keys
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
          ),

          const SizedBox(height: 10),

          // HEADER
          Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            color: Colors.green[200],
            child: Row(
              children: [
                Expanded(child: Center(child: Text("اليوم", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("حفظ", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("مراجعة", style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),

          // DAYS ROWS
          Column(
            children: List.generate(7, (i) {
              int maxVerse = suras[week["sura"]]!;

              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        ["الإثنين","الثلاثاء","الأربعاء","الخميس","الجمعة","السبت","الأحد"][i],
                      ),
                    ),
                  ),

                  // VERSES
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: week["verseFrom"][i],
                          onChanged: isSaved
                              ? null
                              : (val) {
                                  setState(() {
                                    week["verseFrom"][i] = val!;
                                  });
                                },
                          items: List.generate(maxVerse, (v) => v + 1)
                              .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
                              .toList(),
                        ),
                        Text(" إلى "),
                        DropdownButton<int>(
                          value: week["verseTo"][i],
                          onChanged: isSaved
                              ? null
                              : (val) {
                                  setState(() {
                                    week["verseTo"][i] = val!;
                                  });
                                },
                          items: List.generate(maxVerse, (v) => v + 1)
                              .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // REVISION TEXT
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextFormField(
                        initialValue: week["revision"][i],
                        enabled: !isSaved,
                        onChanged: (val) => week["revision"][i] = val,
                        decoration: InputDecoration(
                          hintText: "مراجعة اليوم",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 10),

          // NOTES
          TextFormField(
            initialValue: week["notes"],
            enabled: !isSaved,
            onChanged: (val) => week["notes"] = val,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "ملاحظات إضافية للأسبوع القادم",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              fillColor: Colors.green[100],
              filled: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FONCTION DE SAUVEGARDE AVEC INDEX ADMIN
  Future<void> _saveWeeklyRecord(int weekIndex, Map<String, dynamic> week) async {
    try {
      setState(() {
        week["isSaved"] = true;
      });

      DateTime date = week["date"];
      String month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      String weekKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-W${((date.day - 1) ~/ 7) + 1}';
      
      String docId = '${widget.groupId}_$month';

      // Préparer les données de l'étudiant pour cette semaine
      Map<String, dynamic> studentWeekData = {
        'sura': week["sura"],
        'verseFrom': week["verseFrom"],
        'verseTo': week["verseTo"],
        'revision': week["revision"],
        'notes': week["notes"],
        'date': Timestamp.fromDate(week["date"]),
      };

      // ✅ SAUVEGARDER AVEC CHAMPS INDEX POUR ADMIN
      await _firestore.collection('attendance').doc(docId).set({
        // ✅ CHAMPS INDEX POUR FILTRES ADMIN
        'groupId': widget.groupId,
        'groupName': groupName,
        'profId': _auth.currentUser!.uid,
        'month': month,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        
        // Données de présence par semaine
        'weeklyRecords': {
          weekKey: {
            'students': {
              widget.studentId: studentWeekData,
            }
          }
        }
      }, SetOptions(merge: true));

      // Sauvegarder les références pour édition/suppression
      setState(() {
        week["docId"] = docId;
        week["weekKey"] = weekKey;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ الصفحة بنجاح ✓"),
          backgroundColor: Colors.green,
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

  // ✅ FONCTION DE SUPPRESSION
  Future<void> _deleteWeeklyRecord(int weekIndex, Map<String, dynamic> week) async {
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
              Navigator.pop(ctx);
              
              // Si déjà sauvegardé, supprimer de Firestore
              if (week["isSaved"] == true && week["docId"] != null && week["weekKey"] != null) {
                try {
                  String docId = week["docId"];
                  String weekKey = week["weekKey"];
                  
                  // Supprimer l'étudiant de cette semaine
                  await _firestore.collection('attendance').doc(docId).update({
                    'weeklyRecords.$weekKey.students.${widget.studentId}': FieldValue.delete(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("تم حذف الفيشة من قاعدة البيانات"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  print('Erreur suppression Firestore: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("حدث خطأ أثناء الحذف: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              
              // Supprimer de la liste locale
              setState(() {
                weeklyRecords.removeAt(weekIndex);
              });
            },
            child: Text("حذف"),
          ),
        ],
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

  void _showTestForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تخطيط الاختبار - قريباً")),
    );
  }
}