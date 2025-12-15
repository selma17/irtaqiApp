// lib/screens/follow_student_page.dart - VERSION FINALE UNIFIÉE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowStudentPage extends StatefulWidget {
  final String studentId;
  final String firstName;
  final String lastName;

  const FollowStudentPage({
    super.key,
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

  final Map<String, int> suras = {
    "الفاتحة": 7,
    "البقرة": 286,
    "آل عمران": 200,
    "النساء": 176,
    "المائدة": 120,
    "الأنعام": 165,
    "الأعراف": 206,
    "الأنفال": 75,
    "التوبة": 129,
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadWeeklyRecords();
  }

  /// ✅ CHARGER les données depuis Firestore
  Future<void> _loadWeeklyRecords() async {
    try {
      setState(() => isLoading = true);

      // Charger depuis la structure : students/{studentId}/weekly_follow
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .doc(widget.studentId)
          .collection('weekly_follow')
          .orderBy('createdAt', descending: true)
          .get();

      weeklyRecords.clear();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        weeklyRecords.add({
          "id": doc.id,
          "date": (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          "sura": data['sura'] ?? suras.keys.first,
          "verseFrom": List<int>.from(data['verseFrom'] ?? List.filled(7, 1)),
          "verseTo": List<int>.from(data['verseTo'] ?? List.filled(7, 1)),
          "revision": List<String>.from(data['revision'] ?? List.filled(7, "")),
          "notes": data['notes'] ?? "",
          "isSaved": true,
        });
      }

      // Si aucune donnée, ajouter une semaine vide
      if (weeklyRecords.isEmpty) {
        _addEmptyWeek();
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        appBar: AppBar(
          title: Text("جدول متابعة - ${widget.firstName} ${widget.lastName}"),
          backgroundColor: Color(0xFF4F6F52),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadWeeklyRecords,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري التحميل...'),
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
                        ElevatedButton.icon(
                          onPressed: _addEmptyWeek,
                          icon: Icon(Icons.add),
                          label: Text("إضافة صفحة جديدة"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4F6F52),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: _showTestForm,
                          icon: Icon(Icons.quiz),
                          label: Text("تخطيط اختبار"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSaved ? Colors.white : Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSaved ? Colors.grey.shade300 : Color(0xFF4F6F52),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER avec date et boutons
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18),
                        SizedBox(width: 8),
                        Text(
                          week["date"].toLocal().toString().split(' ')[0],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ✅ SAVE
              if (!isSaved)
                InkWell(
                  onTap: () => _saveWeek(week),
                  child: _roundedIcon(Icons.check, Colors.green),
                ),

              // ✏️ EDIT
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

              // ❌ DELETE
              InkWell(
                onTap: () => _confirmDelete(weekIndex, week),
                child: _roundedIcon(Icons.delete, Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // SOURATE
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
              items: suras.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // HEADER TABLEAU
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4F6F52),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "اليوم",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "حفظ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "مراجعة",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // JOURS
          Column(
            children: List.generate(7, (i) {
              int maxVerse = suras[week["sura"]]!;
              List<String> days = [
                "الإثنين",
                "الثلاثاء",
                "الأربعاء",
                "الخميس",
                "الجمعة",
                "السبت",
                "الأحد"
              ];

              return Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? Colors.grey[100] : Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          days[i],
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
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
                          Text(" → "),
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          initialValue: week["revision"][i],
                          enabled: !isSaved,
                          onChanged: (val) => week["revision"][i] = val,
                          decoration: InputDecoration(
                            hintText: "مراجعة",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                            contentPadding: EdgeInsets.all(8),
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

          const SizedBox(height: 12),

          // NOTES
          TextFormField(
            initialValue: week["notes"],
            enabled: !isSaved,
            onChanged: (val) => week["notes"] = val,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "ملاحظات إضافية",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              fillColor: Colors.green[50],
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundedIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  /// ✅ SAUVEGARDER
  Future<void> _saveWeek(Map<String, dynamic> week) async {
    try {
      setState(() => week["isSaved"] = true);

      await _firestore
          .collection('students')
          .doc(widget.studentId)
          .collection('weekly_follow')
          .add({
        'date': Timestamp.fromDate(week["date"]),
        'sura': week["sura"],
        'verseFrom': week["verseFrom"],
        'verseTo': week["verseTo"],
        'revision': week["revision"],
        'notes': week["notes"],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ تم حفظ الصفحة بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => week["isSaved"] = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ خطأ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ CONFIRMER SUPPRESSION
  void _confirmDelete(int weekIndex, Map<String, dynamic> week) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              // Supprimer de Firestore si sauvegardé
              if (week["isSaved"] && week["id"] != null) {
                await _firestore
                    .collection('students')
                    .doc(widget.studentId)
                    .collection('weekly_follow')
                    .doc(week["id"])
                    .delete();
              }

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

  /// ✅ PLANIFIER EXAMEN
  void _showTestForm() {
    String selectedType = '5ahzab';
    DateTime? testDate;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تخطيط اختبار"),
        content: StatefulBuilder(
          builder: (ctx2, setState2) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "نوع الاختبار:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: Text("10 أحزاب"),
                    value: '10ahzab',
                    groupValue: selectedType,
                    onChanged: (val) => setState2(() => selectedType = val!),
                  ),
                  RadioListTile<String>(
                    title: Text("5 أحزاب"),
                    value: '5ahzab',
                    groupValue: selectedType,
                    onChanged: (val) => setState2(() => selectedType = val!),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: ctx2,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState2(() => testDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            testDate != null
                                ? "تاريخ: ${testDate!.toLocal().toString().split(' ')[0]}"
                                : "اختر تاريخ الاختبار",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "ملاحظات (اختياري)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4F6F52),
            ),
            onPressed: () async {
              if (testDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("⚠️ الرجاء اختيار تاريخ"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              await _createExam(selectedType, testDate!, notesController.text);
            },
            child: Text("تأكيد وحفظ"),
          ),
        ],
      ),
    );
  }

  /// ✅ CRÉER EXAMEN
  Future<void> _createExam(String type, DateTime examDate, String notes) async {
    try {
      String profId = _auth.currentUser!.uid;

      // Récupérer nom prof
      DocumentSnapshot profDoc = await _firestore.collection('users').doc(profId).get();
      Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
      String profName = '${profData['firstName']} ${profData['lastName']}';

      // Créer l'examen
      await _firestore.collection('exams').add({
        'studentId': widget.studentId,
        'studentName': '${widget.firstName} ${widget.lastName}',
        'type': type,
        'examDate': Timestamp.fromDate(examDate),
        'status': 'pending',
        'createdByProfId': profId,
        'createdByProfName': profName,
        'assignedProfId': type == '5ahzab' ? profId : null,
        'assignedProfName': type == '5ahzab' ? profName : null,
        'notes': notes,
        'score': null,
        'feedback': null,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ تم إنشاء الاختبار بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ خطأ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}