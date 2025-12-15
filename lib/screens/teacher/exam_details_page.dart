// lib/screens/teacher/exam_details_page.dart

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
                  if (exam.isCompleted) ...[
                    SizedBox(height: 20),
                    _buildResultsSection(exam),
                  ],
                  SizedBox(height: 30),
                  if (!exam.isCompleted) _buildActionsSection(exam),
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
            '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
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
    Color bgColor = exam.isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1);
    String text = exam.isCompleted ? 'تم إتمام الاختبار بنجاح' : 'قيد الانتظار';

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
            'النتيجة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${exam.score ?? 0}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(' / 60', style: TextStyle(fontSize: 24, color: Colors.grey)),
              ],
            ),
          ),
          if (exam.feedback != null && exam.feedback!.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('ملاحظات الأستاذ:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(exam.feedback!),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(ExamModel exam) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _showCompleteDialog(exam),
        icon: Icon(Icons.check_circle),
        label: Text('إتمام الاختبار', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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

  void _showCompleteDialog(ExamModel exam) {
    double currentScore = 30;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('إتمام الاختبار'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('العلامة: ${currentScore.toInt()} / 60'),
              Slider(
                value: currentScore,
                min: 0,
                max: 60,
                divisions: 60,
                activeColor: Color(0xFF4F6F52),
                onChanged: (value) => setStateDialog(() => currentScore = value),
              ),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(ctx);
                await _completeExam(exam.id, currentScore.toInt(), feedbackController.text);
              },
              child: Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeExam(String examId, int score, String feedback) async {
    bool success = await _examService.completeExam(examId, score, feedback);
    
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