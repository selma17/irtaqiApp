// lib/screens/teacher/exam_details_page.dart
// ✅ VERSION AVEC VALIDATION DE DATE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';

class ExamDetailsPage extends StatefulWidget {
  final ExamModel exam;

  const ExamDetailsPage({super.key, required this.exam});

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  final ExamService _examService = ExamService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('تفاصيل الاختبار'),
          backgroundColor: Color(0xFF4F6F52),
          actions: [
            if (widget.exam.isPending)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _handleDelete(),
                tooltip: 'حذف الاختبار',
              ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('exams').doc(widget.exam.id).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('الاختبار غير موجود', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }

            ExamModel exam = ExamModel.fromDoc(snapshot.data!);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(exam),
                  SizedBox(height: 20),
                  _buildStudentInfo(exam),
                  SizedBox(height: 20),
                  _buildExamInfo(exam),
                  SizedBox(height: 20),
                  _buildStatusSection(exam),
                  // ✅ Afficher résultats si examen noté (graded) OU completé
                  if (exam.isGraded || exam.isCompleted || exam.grade != null) ...[
                    SizedBox(height: 20),
                    _buildResultsSection(exam),
                  ],
                  SizedBox(height: 30),
                  // ✅ Afficher bouton seulement si PAS noté
                  if (!exam.isGraded && exam.grade == null && !exam.isCompleted) 
                    _buildActionsSection(exam),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ExamModel exam) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.typeDisplay,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  exam.statusDisplay,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(ExamModel exam) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الطالب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.account_circle, 'الاسم', exam.studentName),
          if (exam.groupName != null) ...[
            Divider(height: 24),
            _buildInfoRow(Icons.groups, 'المجموعة', exam.groupName!),
          ],
        ],
      ),
    );
  }

  Widget _buildExamInfo(ExamModel exam) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الاختبار',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today,
            'تاريخ الاختبار',
            exam.examDate != null
                ? '${exam.examDate!.day}/${exam.examDate!.month}/${exam.examDate!.year}'
                : 'غير محدد',
          ),
          Divider(height: 24),
          _buildInfoRow(Icons.person_outline, 'أنشئ بواسطة', exam.createdByProfName),
          if (exam.assignedProfName != null) ...[
            Divider(height: 24),
            _buildInfoRow(Icons.assignment_ind, 'مسند إلى', exam.assignedProfName!),
          ],
          if (exam.notes != null && exam.notes!.isNotEmpty) ...[
            Divider(height: 24),
            _buildInfoRow(Icons.notes, 'ملاحظات', exam.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection(ExamModel exam) {
    // ✅ Vérifier si examen noté
    bool isGraded = exam.isGraded || exam.grade != null || exam.isCompleted;
    
    Color bgColor = isGraded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1);
    String text = isGraded ? 'تم التقييم بنجاح' : 'قيد الانتظار';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4F6F52),
        ),
      ),
    );
  }

  Widget _buildResultsSection(ExamModel exam) {
    int grade = exam.grade ?? exam.score ?? 0;
    bool isPassed = grade >= 15;
    Color statusColor = isPassed ? Colors.green : Colors.red;
    String statusText = isPassed ? 'ناجح ✓' : 'راسب ✗';
    IconData statusIcon = isPassed ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النتيجة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$grade',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      ' / 20',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (exam.feedback != null && exam.feedback!.isNotEmpty) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF6F3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment, color: Color(0xFF4F6F52), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ملاحظات الأستاذ:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    exam.feedback!,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(ExamModel exam) {
    // ✅ VÉRIFIER SI LA DATE EST PASSÉE
    bool canGrade = true;
    String buttonText = 'إتمام الاختبار';
    Color buttonColor = Colors.green;
    bool showDateWarning = false;
    
    if (exam.examDate != null) {
      DateTime now = DateTime.now();
      DateTime examDate = exam.examDate!;
      DateTime examDateOnly = DateTime(examDate.year, examDate.month, examDate.day);
      DateTime nowDateOnly = DateTime(now.year, now.month, now.day);
      
      if (examDateOnly.isAfter(nowDateOnly)) {
        // ❌ Date pas encore passée
        canGrade = false;
        showDateWarning = true;
        int daysLeft = examDateOnly.difference(nowDateOnly).inDays;
        buttonText = 'لا يمكن التقييم قبل موعد الامتحان';
        buttonColor = Colors.grey;
      }
    }

    return Column(
      children: [
        // ✅ Message d'avertissement + Bouton modifier date
        if (showDateWarning) ...[
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'موعد الامتحان لم يحن بعد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            exam.examDate != null
                                ? 'الامتحان مقرر يوم ${exam.examDate!.day}/${exam.examDate!.month}/${exam.examDate!.year}'
                                : 'يجب تحديد تاريخ الامتحان أولاً',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // ✅ BOUTON MODIFIER DATE
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showChangeDateDialog(exam),
                    icon: Icon(Icons.edit_calendar, size: 20),
                    label: Text('تعديل تاريخ الامتحان'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[300]!, width: 2),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Bouton notation
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: canGrade ? () => _showCompleteDialog(exam) : null,
            icon: Icon(canGrade ? Icons.check_circle : Icons.block),
            label: Text(buttonText, style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF4F6F52), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ DIALOG POUR CHANGER LA DATE
  void _showChangeDateDialog(ExamModel exam) async {
    DateTime selectedDate = exam.examDate ?? DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4F6F52),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Confirmer le changement
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تأكيد تعديل التاريخ'),
            content: Text(
              'هل تريد تغيير تاريخ الامتحان إلى:\n${pickedDate.day}/${pickedDate.month}/${pickedDate.year}؟',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F6F52),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('تأكيد'),
              ),
            ],
          ),
        ),
      );

      if (confirm == true) {
        await _updateExamDate(exam.id, pickedDate);
      }
    }
  }

  Future<void> _updateExamDate(String examId, DateTime newDate) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'examDate': Timestamp.fromDate(newDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تعديل تاريخ الامتحان بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompleteDialog(ExamModel exam) {
    double currentScore = 15.0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          bool isPassed = currentScore >= 15;
          Color statusColor = isPassed ? Colors.green : Colors.red;
          String statusText = isPassed ? 'ناجح ✓' : 'راسب ✗';
          
          return AlertDialog(
            title: Text('إتمام الاختبار', style: TextStyle(color: Color(0xFF4F6F52))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العلامة: ${currentScore.toInt()} / 20',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Slider(
                    value: currentScore,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: Color(0xFF4F6F52),
                    inactiveColor: Color(0xFF4F6F52).withOpacity(0.2),
                    onChanged: (value) => setStateDialog(() => currentScore = value),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      hintText: 'أضف ملاحظات أو تعليقات...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F6F52),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _completeExam(exam.id, currentScore.toInt(), feedbackController.text);
                },
                child: Text('تأكيد', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeExam(String examId, int grade, String feedback) async {
    bool success = await _examService.completeExam(examId, grade, feedback);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ تم إتمام الاختبار' : '❌ حدث خطأ'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _examService.deleteExam(widget.exam.id);
              if (success) Navigator.pop(context);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }
}