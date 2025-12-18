// lib/screens/student/student_exams_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/exam_model.dart';
import 'package:intl/intl.dart' hide TextDirection;

class StudentExamsPage extends StatefulWidget {
  @override
  _StudentExamsPageState createState() => _StudentExamsPageState();
}

class _StudentExamsPageState extends State<StudentExamsPage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentUserId = _authService.getCurrentUserId();
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
          title: Text('امتحاناتي'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.event_available),
                text: 'الامتحانات القادمة',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'السجل',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcomingExamsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // Onglet des examens à venir et en attente de notation
  Widget _buildUpcomingExamsTab() {
    if (currentUserId == null) {
      return Center(child: Text('خطأ في تحميل البيانات'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .where('studentId', isEqualTo: currentUserId)
          .orderBy('examDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text('حدث خطأ في تحميل الامتحانات'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            title: 'لا توجد امتحانات قادمة',
            subtitle: 'سيتم إضافة الامتحانات من قبل الأستاذ',
          );
        }

        // Filtrer côté client pour éviter l'index composite
        List<ExamModel> allExams = snapshot.data!.docs
            .map((doc) => ExamModel.fromDoc(doc))
            .where((e) => ['pending', 'approved', 'completed'].contains(e.status))
            .toList();

        if (allExams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            title: 'لا توجد امتحانات قادمة',
            subtitle: 'سيتم إضافة الامتحانات من قبل الأستاذ',
          );
        }

        // Séparer les examens à venir et ceux en attente de notation
        List<ExamModel> upcomingExams = allExams.where((e) => 
          e.examDate.isAfter(DateTime.now()) || 
          e.examDate.day == DateTime.now().day
        ).toList();
        
        List<ExamModel> pendingGrading = allExams.where((e) => 
          e.status == 'completed' &&
          e.examDate.isBefore(DateTime.now())
        ).toList();

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (upcomingExams.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.calendar_today,
                title: 'الامتحانات المقبلة',
                count: upcomingExams.length,
                color: Colors.blue,
              ),
              SizedBox(height: 12),
              ...upcomingExams.map((exam) => _buildUpcomingExamCard(exam)),
            ],
            if (pendingGrading.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildSectionHeader(
                icon: Icons.pending_actions,
                title: 'في انتظار التقييم',
                count: pendingGrading.length,
                color: Colors.orange,
              ),
              SizedBox(height: 12),
              ...pendingGrading.map((exam) => _buildPendingGradingCard(exam)),
            ],
          ],
        );
      },
    );
  }

  // Onglet de l'historique des examens notés
  Widget _buildHistoryTab() {
    if (currentUserId == null) {
      return Center(child: Text('خطأ في تحميل البيانات'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .where('studentId', isEqualTo: currentUserId)
          .orderBy('examDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text('حدث خطأ في تحميل السجل'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'لا يوجد سجل امتحانات',
            subtitle: 'ستظهر هنا الامتحانات المكتملة والمقيّمة',
          );
        }

        // Filtrer côté client pour avoir seulement les examens notés
        List<ExamModel> exams = snapshot.data!.docs
            .map((doc) => ExamModel.fromDoc(doc))
            .where((e) => e.status == 'graded')
            .toList();

        if (exams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'لا يوجد سجل امتحانات',
            subtitle: 'ستظهر هنا الامتحانات المكتملة والمقيّمة',
          );
        }

        // Calculer les statistiques
        double average = exams.isNotEmpty
            ? exams.map((e) => e.grade ?? 0).reduce((a, b) => a + b) / exams.length
            : 0;
        
        int passed = exams.where((e) => (e.grade ?? 0) >= 50).length;
        int total = exams.length;

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildStatisticsCard(average, passed, total),
            SizedBox(height: 20),
            _buildSectionHeader(
              icon: Icons.grade,
              title: 'الامتحانات المقيّمة',
              count: exams.length,
              color: Color(0xFF4F6F52),
            ),
            SizedBox(height: 12),
            ...exams.map((exam) => _buildHistoryExamCard(exam)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamCard(ExamModel exam) {
    DateTime now = DateTime.now();
    Duration difference = exam.examDate.difference(now);
    bool isToday = exam.examDate.day == now.day &&
                   exam.examDate.month == now.month &&
                   exam.examDate.year == now.year;
    bool isTomorrow = difference.inHours > 0 && difference.inHours <= 24;

    String timeIndicator = '';
    Color timeColor = Colors.blue;
    
    if (isToday) {
      timeIndicator = 'اليوم';
      timeColor = Colors.red;
    } else if (isTomorrow) {
      timeIndicator = 'غداً';
      timeColor = Colors.orange;
    } else if (difference.inDays <= 7) {
      timeIndicator = 'خلال ${difference.inDays} أيام';
      timeColor = Colors.orange;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec gradient
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue[300]!],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event, color: Colors.white, size: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.typeDisplay,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'الأستاذ: ${exam.createdByProfName}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (timeIndicator.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: timeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeIndicator,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Corps de la carte
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_month,
                  'التاريخ',
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(exam.examDate),
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'الوقت',
                  DateFormat('HH:mm', 'ar').format(exam.examDate),
                ),
                if (exam.notes != null && exam.notes!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exam.notes!,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingGradingCard(ExamModel exam) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.orange[300]!],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.pending_actions, color: Colors.white, size: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.typeDisplay,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'في انتظار التقييم',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.hourglass_empty, color: Colors.white, size: 32),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_month,
                  'تاريخ الامتحان',
                  DateFormat('d MMMM yyyy', 'ar').format(exam.examDate),
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.person,
                  'الأستاذ المقيّم',
                  exam.assignedProfName ?? exam.createdByProfName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryExamCard(ExamModel exam) {
    int grade = exam.grade ?? 0;
    Color gradeColor = grade >= 80
        ? Colors.green
        : grade >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.grade, color: Colors.white, size: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.typeDisplay,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('d MMMM yyyy', 'ar').format(exam.examDate),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de note
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        grade.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),
                      ),
                      Text(
                        '100',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person,
                  'الأستاذ المقيّم',
                  exam.assignedProfName ?? exam.createdByProfName,
                ),
                if (exam.feedback != null && exam.feedback!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Color(0xFF4F6F52).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.comment,
                          color: Color(0xFF4F6F52),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ملاحظات الأستاذ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                exam.feedback!,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(double average, int passed, int total) {
    double successRate = total > 0 ? (passed / total) * 100 : 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'إحصائيات الامتحانات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'المعدل',
                average.toStringAsFixed(1),
                Icons.star,
              ),
              Container(
                width: 2,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                'النجاح',
                '${passed}/${total}',
                Icons.check_circle,
              ),
              Container(
                width: 2,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                'نسبة النجاح',
                '${successRate.toStringAsFixed(0)}%',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF4F6F52).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF4F6F52).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4F6F52).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF4F6F52), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}