// lib/screens/follow_student_page.dart - VERSION CORRIGÉE AVEC CHARGEMENT

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowStudentPage extends StatefulWidget {
  final String studentId;  // ✅ UID Firebase de l'étudiant
  final String firstName;
  final String lastName;

  const FollowStudentPage({
    super.key,
    required this.studentId,  // ✅ AJOUTÉ
    required this.firstName,
    required this.lastName,
  });

  @override
  State<FollowStudentPage> createState() => _FollowStudentPageState();
}

class _FollowStudentPageState extends State<FollowStudentPage> {
  final List<Map<String, dynamic>> weeklyRecords = [];
  bool isLoading = true; // ✅ AJOUTÉ : Indicateur de chargement
  
  final Map<String, int> suras = {
    "الفاتحة": 7,
    "البقرة": 286,
    "آل عمران": 200,
    "النساء": 176,
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadExistingRecords();  // ✅ Charger les fiches existantes
  }

  // ✅ CORRIGÉ: Charger les fiches avec indicateur de chargement
  Future<void> _loadExistingRecords() async {
    setState(() {
      isLoading = true; // Début du chargement
    });
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students_follow_up')
          .doc(widget.studentId)  // ✅ Utilise l'UID
          .collection('weekly_records')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        weeklyRecords.clear(); // Vider d'abord
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          weeklyRecords.add({
            "docId": doc.id,  // Pour pouvoir éditer/supprimer
            "date": (data['date'] as Timestamp).toDate(),
            "sura": data['sura'],
            "verseFrom": List<int>.from(data['verseFrom']),
            "verseTo": List<int>.from(data['verseTo']),
            "revision": List<String>.from(data['revision']),
            "notes": data['notes'],
            "isSaved": true,  // Déjà sauvegardé
          });
        }
        isLoading = false; // Fin du chargement
      });
    } catch (e) {
      print('Erreur chargement fiches: $e');
      setState(() {
        isLoading = false; // Fin du chargement même en cas d'erreur
      });
    }
  }

  void _addEmptyWeek() {
    weeklyRecords.insert(0, {  // Insérer au début
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
            ? // ✅ AFFICHER LOADING pendant le chargement
              Center(
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
                ? // ✅ AFFICHER MESSAGE si aucune fiche après chargement
                  Center(
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
                : // ✅ AFFICHER LES FICHES si elles existent
                  SingleChildScrollView(
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
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                              child: Text("إضافة صفحة متابعة جديدة"),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: _showTestForm,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4F6F52),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
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
    String? docId = week["docId"];  // ID du document Firestore si déjà sauvegardé

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
                  onTap: () async {
                    try {
                      setState(() {
                        week["isSaved"] = true;
                      });

                      // ✅ CORRIGÉ: Utilise l'UID
                      CollectionReference students = FirebaseFirestore.instance.collection('students_follow_up');
                      DocumentReference studentDoc = students.doc(widget.studentId);

                      // Ajouter le record de la semaine
                      DocumentReference newDoc = await studentDoc.collection('weekly_records').add({
                        'date': week["date"],
                        'sura': week["sura"],
                        'verseFrom': week["verseFrom"],
                        'verseTo': week["verseTo"],
                        'revision': week["revision"],
                        'notes': week["notes"],
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // Sauvegarder l'ID du document
                      setState(() {
                        week["docId"] = newDoc.id;
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
                    }
                  },
                  child: _roundedIcon(Icons.check, Colors.green),
                ),

              // ✅ EDIT BUTTON
              if (isSaved)
                InkWell(
                  onTap: () async {
                    // Permettre l'édition
                    setState(() {
                      week["isSaved"] = false;
                    });
                  },
                  child: _roundedIcon(Icons.edit, Colors.orange),
                ),

              const SizedBox(width: 6),

              // ❌ DELETE BUTTON
              InkWell(
                onTap: () {
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
                            // Si déjà sauvegardé, supprimer de Firestore
                            if (docId != null) {
                              try {
                                await _firestore
                                    .collection('students_follow_up')
                                    .doc(widget.studentId)
                                    .collection('weekly_records')
                                    .doc(docId)
                                    .delete();
                              } catch (e) {
                                print('Erreur suppression: $e');
                              }
                            }
                            
                            setState(() {
                              weeklyRecords.removeAt(weekIndex);
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text("حذف"),
                        ),
                      ],
                    ),
                  );
                },
                child: _roundedIcon(Icons.close, Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // SURAT
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
    // TODO: Implémenter le formulaire de test
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تخطيط الاختبار - قريباً")),
    );
  }
}