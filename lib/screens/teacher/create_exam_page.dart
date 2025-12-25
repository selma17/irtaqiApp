// lib/screens/teacher/create_exam_page.dart
// ✅ Page création d'examen par le prof

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class CreateExamPage extends StatefulWidget {
  @override
  _CreateExamPageState createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? selectedGroupId;
  String? selectedStudentId;
  String selectedType = '5ahzab';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0); // ✅ Heure par défaut 9h00
  
  List<Map<String, dynamic>> myGroups = [];
  List<Map<String, dynamic>> groupStudents = [];
  
  bool isLoading = true;
  bool isCreating = false;
  
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Charger info prof
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      currentUser = UserModel.fromMap(userDoc.id, userDoc.data() as Map<String, dynamic>);

      // Charger groupes du prof
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: userId)
          .get();

      setState(() {
        myGroups = groupsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'studentIds': List<String>.from(doc['studentIds'] ?? []),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadGroupStudents(String groupId) async {
    try {
      var group = myGroups.firstWhere((g) => g['id'] == groupId);
      List<String> studentIds = group['studentIds'];

      if (studentIds.isEmpty) {
        setState(() {
          groupStudents = [];
        });
        return;
      }

      // Charger les étudiants
      List<Map<String, dynamic>> students = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();
        
        if (studentDoc.exists) {
          Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
          students.add({
            'id': studentDoc.id,
            'name': '${data['firstName']} ${data['lastName']}',
          });
        }
      }

      setState(() {
        groupStudents = students;
        selectedStudentId = null;
      });
    } catch (e) {
      print('Erreur chargement étudiants: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4F6F52),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // Important pour le time picker
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF4F6F52),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _createExam() async {
    // Validation
    if (selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى اختيار المجموعة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى اختيار الطالب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    try {
      var selectedGroup = myGroups.firstWhere((g) => g['id'] == selectedGroupId);
      var selectedStudent = groupStudents.firstWhere((s) => s['id'] == selectedStudentId);

      String status = selectedType == '10ahzab' ? 'pending' : 'pending';

      // ✅ CORRECTION: Pour 10 ahzab, mettre date temporaire (sera changée par admin)
      DateTime examDateToUse;
      if (selectedType == '5ahzab') {
        // Combiner la date sélectionnée avec l'heure sélectionnée
        examDateToUse = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      } else {
        // Pour 10 ahzab, date provisoire (sera définie par admin)
        examDateToUse = DateTime.now().add(Duration(days: 30));
      } // Date provisoire

      Map<String, dynamic> examData = {
        'studentId': selectedStudentId,
        'studentName': selectedStudent['name'],
        'groupId': selectedGroupId,
        'groupName': selectedGroup['name'],
        'createdByProfId': currentUser!.id,
        'createdByProfName': currentUser!.fullName,
        'assignedProfId': selectedType == '5ahzab' ? currentUser!.id : null,
        'assignedProfName': selectedType == '5ahzab' ? currentUser!.fullName : null,
        'type': selectedType,
        'examDate': Timestamp.fromDate(examDateToUse), // ✅ Toujours une date
        'status': status,
        'grade': null,
        'notes': null,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      };

      DocumentReference examRef = await _firestore.collection('exams').add(examData);

      // Si 10 ahzab, créer notification pour admin
      if (selectedType == '10ahzab') {
        await _createAdminNotification(examRef.id, selectedStudent['name']);
      }

      // Notification pour l'étudiant
      await _createStudentNotification(
        selectedStudentId!,
        selectedStudent['name'],
        selectedType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedType == '10ahzab'
                ? '✅ تم إنشاء الامتحان وإرسال طلب للإدارة'
                : '✅ تم إنشاء الامتحان بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Erreur création examen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isCreating = false);
    }
  }

  Future<void> _createAdminNotification(String examId, String studentName) async {
    try {
      // Récupérer tous les admins
      QuerySnapshot adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var adminDoc in adminsSnapshot.docs) {
        await _firestore.collection('notifications').add({
          'userId': adminDoc.id,
          'title': 'طلب امتحان 10 أحزاب',
          'message': 'الأستاذ ${currentUser!.fullName} يطلب تعيين أستاذ لامتحان 10 أحزاب للطالب $studentName',
          'type': 'exam_10ahzab_request',
          'examId': examId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur notification admin: $e');
    }
  }

  Future<void> _createStudentNotification(
    String studentId,
    String studentName,
    String type,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': 'امتحان جديد',
        'message': 'تم إنشاء امتحان ${type == "5ahzab" ? "5 أحزاب" : "10 أحزاب"} لك',
        'type': 'exam_created',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur notification étudiant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إنشاء امتحان جديد'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 24),
                    _buildFormCard(),
                    SizedBox(height: 24),
                    _buildCreateButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امتحان جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اختر الطالب ونوع الامتحان',
                  style: TextStyle(
                    color: Colors.white70,
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

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection Groupe
          Text(
            'المجموعة *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedGroupId,
            decoration: InputDecoration(
              hintText: 'اختر المجموعة',
              prefixIcon: Icon(Icons.group, color: Color(0xFF4F6F52)),
              filled: true,
              fillColor: Color(0xFFF6F3EE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: myGroups.map((group) {
              return DropdownMenuItem<String>(
                value: group['id'],
                child: Text(group['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedGroupId = value;
                selectedStudentId = null;
              });
              if (value != null) {
                _loadGroupStudents(value);
              }
            },
          ),
          SizedBox(height: 20),

          // Sélection Étudiant
          Text(
            'الطالب *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedStudentId,
            decoration: InputDecoration(
              hintText: selectedGroupId == null
                  ? 'اختر المجموعة أولاً'
                  : 'اختر الطالب',
              prefixIcon: Icon(Icons.person, color: Color(0xFF4F6F52)),
              filled: true,
              fillColor: Color(0xFFF6F3EE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: groupStudents.map((student) {
              return DropdownMenuItem<String>(
                value: student['id'],
                child: Text(student['name']),
              );
            }).toList(),
            onChanged: selectedGroupId == null
                ? null
                : (value) {
                    setState(() {
                      selectedStudentId = value;
                    });
                  },
          ),
          SizedBox(height: 20),

          // Type d'examen
          Text(
            'نوع الامتحان *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 12),
          
          RadioListTile<String>(
            value: '5ahzab',
            groupValue: selectedType,
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
            title: Text('5 أحزاب'),
            subtitle: Text('امتحان عادي - أنت من سيقوم بالتقييم'),
            activeColor: Color(0xFF4F6F52),
          ),
          
          RadioListTile<String>(
            value: '10ahzab',
            groupValue: selectedType,
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
            title: Text('10 أحزاب'),
            subtitle: Text('امتحان خاص - سيتم تعيين أستاذ آخر من قبل الإدارة'),
            activeColor: Color(0xFF4F6F52),
          ),
          
          SizedBox(height: 20),

          // Date (seulement pour 5 ahzab)
          // Date et heure (seulement pour 5 ahzab)
          if (selectedType == '5ahzab') ...[
            Text(
              'تاريخ الامتحان *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F6F52),
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F3EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF4F6F52)),
                    SizedBox(width: 12),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ✅ NOUVEAU: Sélecteur d'heure
            SizedBox(height: 20),
            Text(
              'وقت الامتحان *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F6F52),
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F3EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF4F6F52)),
                    SizedBox(width: 12),
                    Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (selectedType == '10ahzab') ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إرسال طلب للإدارة لتعيين أستاذ وتحديد موعد الامتحان',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isCreating ? null : _createExam,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4F6F52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isCreating
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'إنشاء الامتحان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}