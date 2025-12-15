// lib/screens/teacher/create_exam_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/exam_service.dart';

class CreateExamPage extends StatefulWidget {
  @override
  _CreateExamPageState createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final _formKey = GlobalKey<FormState>();
  final ExamService _examService = ExamService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedStudentId;
  String? selectedStudentName;
  String selectedType = '5ahzab';
  DateTime selectedDate = DateTime.now().add(Duration(days: 7));
  final TextEditingController notesController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  bool isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      String profId = _auth.currentUser!.uid;

      // Récupérer les groupes du prof
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: profId)
          .get();

      Set<String> studentIds = {};
      for (var groupDoc in groupsSnapshot.docs) {
        List<dynamic> ids = (groupDoc.data() as Map<String, dynamic>)['studentIds'] ?? [];
        studentIds.addAll(ids.cast<String>());
      }

      if (studentIds.isEmpty) {
        setState(() {
          isLoadingStudents = false;
        });
        return;
      }

      // Récupérer les infos des étudiants
      List<Map<String, dynamic>> loadedStudents = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
          loadedStudents.add({
            'id': studentId,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'fullName': '${data['firstName']} ${data['lastName']}',
            'totalHafd': ((data['oldHafd'] ?? 0) as num).toInt() + ((data['newHafd'] ?? 0) as num).toInt(),
          });
        }
      }

      // Trier par nom
      loadedStudents.sort((a, b) => a['fullName'].compareTo(b['fullName']));

      setState(() {
        students = loadedStudents;
        isLoadingStudents = false;
      });
    } catch (e) {
      print('❌ Erreur _loadStudents: $e');
      setState(() {
        isLoadingStudents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إنشاء اختبار جديد'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
        ),
        body: isLoadingStudents
            ? Center(child: CircularProgressIndicator())
            : students.isEmpty
                ? _buildNoStudentsState()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          SizedBox(height: 20),
                          _buildStudentSelection(),
                          SizedBox(height: 20),
                          _buildExamTypeSelection(),
                          SizedBox(height: 20),
                          _buildDateSelection(),
                          SizedBox(height: 20),
                          _buildNotesField(),
                          SizedBox(height: 30),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52).withOpacity(0.1), Color(0xFF6B8F71).withOpacity(0.1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4F6F52).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF4F6F52), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة هامة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4F6F52),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• اختبار 5 أحزاب: ستشرف عليه بنفسك\n• اختبار 10 أحزاب: سيتم تعيين أستاذ آخر',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الطالب *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F6F52),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedStudentId,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.person, color: Color(0xFF4F6F52)),
              hintText: 'اختر طالباً من مجموعاتك',
            ),
            items: students.map((student) {
              return DropdownMenuItem<String>(
                value: student['id'],
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        student['fullName'],
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F6F52).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${student['totalHafd']} حزب',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4F6F52),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedStudentId = value;
                selectedStudentName = students.firstWhere((s) => s['id'] == value)['fullName'];
              });
            },
            validator: (value) => value == null ? 'الرجاء اختيار الطالب' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExamTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الاختبار *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F6F52),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: '5ahzab',
                title: '5 أحزاب',
                subtitle: 'ستشرف عليه',
                icon: Icons.assignment,
                isSelected: selectedType == '5ahzab',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: '10ahzab',
                title: '10 أحزاب',
                subtitle: 'أستاذ آخر',
                icon: Icons.assignment_turned_in,
                isSelected: selectedType == '10ahzab',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4F6F52).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF4F6F52) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Color(0xFF4F6F52) : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF4F6F52) : Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ الاختبار *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F6F52),
          ),
        ),
        SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF4F6F52)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التاريخ المحدد',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملاحظات (اختياري)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F6F52),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: notesController,
            maxLines: 4,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              hintText: 'أضف أي ملاحظات أو تعليمات خاصة بالاختبار...',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4F6F52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 24),
            SizedBox(width: 12),
            Text(
              'إنشاء الاختبار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 20),
            Text(
              'لا يوجد طلاب',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد طلاب في مجموعاتك حالياً\nلا يمكن إنشاء اختبار',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4F6F52),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار الطالب')),
      );
      return;
    }

    // Confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الإنشاء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد إنشاء هذا الاختبار؟'),
            SizedBox(height: 16),
            _buildConfirmItem('الطالب', selectedStudentName!),
            _buildConfirmItem('النوع', selectedType == '5ahzab' ? '5 أحزاب' : '10 أحزاب'),
            _buildConfirmItem('التاريخ', '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    // Créer l'examen
    String? examId = await _examService.createExam(
      studentId: selectedStudentId!,
      type: selectedType,
      examDate: selectedDate,
    );

    Navigator.pop(context); // Fermer loading

    if (examId != null) {
      Navigator.pop(context, true); // Retourner avec succès
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء إنشاء الاختبار'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}