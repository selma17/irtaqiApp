// lib/screens/teacher/exams_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import 'create_exam_page.dart';
import 'exam_details_page.dart';

class ExamsPage extends StatefulWidget {
  @override
  _ExamsPageState createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with SingleTickerProviderStateMixin {
  final ExamService _examService = ExamService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إدارة الاختبارات'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'اختباراتي'),
              Tab(text: 'المسندة لي'),
              Tab(text: 'قيد الانتظار'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyExamsTab(),
            _buildAssignedExamsTab(),
            _buildPendingExamsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            bool? created = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateExamPage()),
            );
            if (created == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ تم إنشاء الاختبار بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {});
            }
          },
          backgroundColor: Color(0xFF4F6F52),
          icon: Icon(Icons.add),
          label: Text('إنشاء اختبار'),
        ),
      ),
    );
  }

  // ==================== TAB 1: MES EXAMENS ====================
  Widget _buildMyExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getProfExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'لا توجد اختبارات',
            subtitle: 'لم تقم بإنشاء أي اختبار بعد\nانقر على "إنشاء اختبار" للبدء',
          );
        }

        List<ExamModel> exams = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(exams[index]);
          },
        );
      },
    );
  }

  // ==================== TAB 2: EXAMENS ASSIGNÉS ====================
  Widget _buildAssignedExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getAssignedExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'لا توجد اختبارات مسندة',
            subtitle: 'لم يتم تعيين أي اختبار 10 أحزاب لك بعد',
          );
        }

        List<ExamModel> exams = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(exams[index]);
          },
        );
      },
    );
  }

  // ==================== TAB 3: EN ATTENTE ====================
  Widget _buildPendingExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getProfExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hourglass_empty,
            title: 'لا توجد اختبارات قيد الانتظار',
            subtitle: 'جميع اختبارات 10 أحزاب تم تعيينها',
          );
        }

        // Filtrer seulement les exams en attente (10 ahzab sans assignedProfId)
        List<ExamModel> pendingExams = snapshot.data!
            .where((exam) => exam.type == '10ahzab' && exam.assignedProfId == null)
            .toList();

        if (pendingExams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hourglass_empty,
            title: 'لا توجد اختبارات قيد الانتظار',
            subtitle: 'جميع اختبارات 10 أحزاب تم تعيينها',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingExams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(pendingExams[index]);
          },
        );
      },
    );
  }

  // ==================== EXAM CARD ====================
  Widget _buildExamCard(ExamModel exam) {
    bool isPending = exam.status == 'pending';
    bool isCompleted = exam.status == 'completed';
    bool isAssigned = exam.status == 'assigned';

    Color statusColor = isPending
        ? Colors.orange
        : isCompleted
            ? Colors.green
            : Colors.blue;

    String statusText = isPending
        ? 'قيد الانتظار'
        : isCompleted
            ? 'مكتمل'
            : 'معين';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamDetailsPage(exam: exam),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isPending
                              ? Icons.hourglass_empty
                              : Icons.assignment,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.studentName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF4F6F52).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                exam.type == '5ahzab' ? 'اختبار 5 أحزاب' : 'اختبار 10 أحزاب',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Divider(height: 24),

              // Info
              _buildInfoRow(Icons.calendar_today, 'التاريخ',
                  '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}'),
              
              if (exam.assignedProfName != null)
                _buildInfoRow(Icons.person, 'الأستاذ المشرف', exam.assignedProfName!),

              if (isCompleted && exam.score != null)
                _buildInfoRow(Icons.grade, 'النتيجة', '${exam.score}/60'),

              // Actions
              if (isPending || isAssigned) ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPending)
                      TextButton.icon(
                        onPressed: () => _showCompleteDialog(exam),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('تسجيل النتيجة'),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showCompleteDialog(ExamModel exam) {
    int score = 30;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تسجيل النتيجة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الطالب: ${exam.studentName}'),
                  SizedBox(height: 16),
                  Text('النتيجة: $score / 60'),
                  Slider(
                    value: score.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 60,
                    label: score.toString(),
                    activeColor: Color(0xFF4F6F52),
                    onChanged: (value) {
                      setStateDialog(() {
                        score = value.toInt();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(),
                      hintText: 'اكتب ملاحظاتك هنا...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  bool success = await _examService.completeExam(
                    exam.id,
                    score,
                    feedbackController.text,
                  );
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم تسجيل النتيجة بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ÉTATS ====================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            SizedBox(height: 20),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh),
              label: Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
            ),
          ],
        ),
      ),
    );
  }
}