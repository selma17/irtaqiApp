// lib/screens/teacher/exam_grading_page.dart
// ✅ Page notation d'un examen

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamGradingPage extends StatefulWidget {
  final String examId;
  final Map<String, dynamic> examData;

  ExamGradingPage({
    required this.examId,
    required this.examData,
  });

  @override
  _ExamGradingPageState createState() => _ExamGradingPageState();
}

class _ExamGradingPageState extends State<ExamGradingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool isGraded = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingGrade();
  }

  void _loadExistingGrade() {
    if (widget.examData['grade'] != null) {
      setState(() {
        isGraded = true;
        _gradeController.text = widget.examData['grade'].toString();
        _notesController.text = widget.examData['notes'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      int grade = int.parse(_gradeController.text);
      String notes = _notesController.text.trim();

      await _firestore.collection('exams').doc(widget.examId).update({
        'grade': grade,
        'notes': notes,
        'status': 'graded',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Créer notification pour l'étudiant
      await _createStudentNotification(grade);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ التقييم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _createStudentNotification(int grade) async {
    try {
      String studentId = widget.examData['studentId'];
      String type = widget.examData['type'];
      String typeDisplay = type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
      
      await _firestore.collection('notifications').add({
        'userId': studentId,
        'title': 'نتيجة الامتحان',
        'message': 'تم نشر نتيجة امتحان $typeDisplay: $grade/20',
        'type': 'exam_graded',
        'examId': widget.examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String studentName = widget.examData['studentName'] ?? 'غير معروف';
    String type = widget.examData['type'] ?? '';
    String typeDisplay = type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
    
    Timestamp? examDateTs = widget.examData['examDate'];
    String dateDisplay = examDateTs != null
        ? '${examDateTs.toDate().day}/${examDateTs.toDate().month}/${examDateTs.toDate().year}'
        : 'غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text(isGraded ? 'تفاصيل الامتحان' : 'تقييم الامتحان'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamInfoCard(studentName, typeDisplay, dateDisplay),
                SizedBox(height: 24),
                _buildGradingForm(),
                SizedBox(height: 24),
                if (!isGraded) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamInfoCard(String studentName, String typeDisplay, String dateDisplay) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.quiz, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الامتحان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      studentName,
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
          SizedBox(height: 16),
          Divider(color: Colors.white30),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('النوع', typeDisplay, Icons.category),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('التاريخ', dateDisplay, Icons.calendar_today),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingForm() {
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
          Row(
            children: [
              Icon(Icons.grade, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'التقييم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Note sur 20
          Text(
            'النقطة (من 20) *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _gradeController,
            enabled: !isGraded,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'أدخل النقطة (0-20)',
              prefixIcon: Icon(Icons.grade, color: Color(0xFF4F6F52)),
              suffixText: '/ 20',
              filled: true,
              fillColor: isGraded ? Colors.grey[100] : Color(0xFFF6F3EE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال النقطة';
              }
              int? grade = int.tryParse(value);
              if (grade == null) {
                return 'يرجى إدخال رقم صحيح';
              }
              if (grade < 0 || grade > 20) {
                return 'النقطة يجب أن تكون بين 0 و 20';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                int? grade = int.tryParse(value);
                if (grade != null) {
                  setState(() {}); // Pour mettre à jour l'indicateur
                }
              }
            },
          ),
          
          // Indicateur Réussi/Échoué
          if (_gradeController.text.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildResultIndicator(),
          ],
          
          SizedBox(height: 20),

          // Notes/Commentaires
          Text(
            'ملاحظات (اختياري)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            enabled: !isGraded,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'أضف ملاحظات أو تعليقات حول أداء الطالب...',
              filled: true,
              fillColor: isGraded ? Colors.grey[100] : Color(0xFFF6F3EE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultIndicator() {
    int? grade = int.tryParse(_gradeController.text);
    if (grade == null) return SizedBox.shrink();

    bool isPassed = grade >= 15;
    Color color = isPassed ? Colors.green : Colors.red;
    String text = isPassed ? 'ناجح ✓' : 'راسب ✗';
    IconData icon = isPassed ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveGrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4F6F52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'حفظ التقييم',
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