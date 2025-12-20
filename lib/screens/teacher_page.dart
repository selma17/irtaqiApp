// lib/screens/teacher_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:irtaqi_new/screens/teacher/exams_page.dart';
import '../services/exam_service.dart';
import '../models/exam_model.dart';
import 'login_page.dart';
import 'groups_page.dart';
import 'all_students_page.dart';
import 'teacher/teacher_settings_page.dart';
import 'teacher/teacher_schedule_page.dart';
import 'teacher/teacher_send_remark_page.dart';
import 'teacher/teacher_announcements_page.dart';
import 'teacher/teacher_profile_page.dart';

class TeacherPage extends StatefulWidget {
  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ExamService _examService = ExamService();

  int totalGroups = 0;
  int totalStudents = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      String? profId = _auth.currentUser?.uid;
      if (profId == null) return;

      // Compter les groupes du prof
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: profId)
          .get();

      int groupCount = groupsSnapshot.docs.length;
      
      // Compter tous les étudiants de ces groupes
      int studentCount = 0;
      for (var groupDoc in groupsSnapshot.docs) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        List<dynamic> studentIds = data['studentIds'] ?? [];
        studentCount += studentIds.length;
      }

      setState(() {
        totalGroups = groupCount;
        totalStudents = studentCount;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur loadStats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الرئيسية'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
        ),
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                SizedBox(height: 20),
                _buildStatsCards(),
                SizedBox(height: 25),
                _buildUpcomingExams(),
                SizedBox(height: 25),
                _buildMemorizationRules(),
                SizedBox(height: 25),
                _buildAnnouncementsAccess(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DRAWER ====================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'الرئيسية',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('التدريس', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                
                _buildDrawerItem(
                  icon: Icons.groups,
                  title: 'مجموعاتي',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupsPage()));
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'قائمة الطلاب',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AllStudentsPage()));
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'الاختبارات',
                  badge: _buildExamsBadge(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ExamsPage()));
                  },
                ),
                               
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('الإدارة', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'جدول الأوقات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeacherSchedulePage()
                    ));
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.feedback,
                  title: 'إرسال ملاحظة',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeacherSendRemarkPage()
                    ));
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.campaign,
                  title: 'الإعلانات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeacherAnnouncementsPage()
                    ));
                  },
                ),

                // ... Dans la section "الحساب":

                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'الملف الشخصي',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeacherProfilePage()
                    ));
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeacherSettingsPage()
                    ));
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            isLogout: true,
            onTap: () => _handleLogout(),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(_auth.currentUser?.uid).get(),
      builder: (context, snapshot) {
        String profName = 'الأستاذ';
        String profEmail = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          profName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
          profEmail = data['email'] ?? '';
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 35, color: Color(0xFF4F6F52)),
              ),
              SizedBox(height: 12),
              Text(profName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(profEmail, style: TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
    Widget? badge,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF4F6F52).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : isSelected ? Color(0xFF4F6F52) : Colors.grey[700], size: 22),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isLogout ? Colors.red : isSelected ? Color(0xFF4F6F52) : Colors.black87)),
        trailing: badge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExamsBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('exams').where('assignedProfId', isEqualTo: _auth.currentUser?.uid).where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
          child: Text(snapshot.data!.docs.length.toString(), style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildNotificationsBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('user_notifications').doc(_auth.currentUser?.uid).collection('notifications').where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
          child: Text(snapshot.data!.docs.length.toString(), style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الخروج'),
        content: Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage()), (route) => false);
    }
  }

  // ==================== HOME PAGE CONTENT ====================

  Widget _buildWelcomeHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(_auth.currentUser?.uid).get(),
      builder: (context, snapshot) {
        String profName = 'الأستاذ';
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          profName = data['firstName'] ?? 'الأستاذ';
        }

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)], begin: Alignment.topRight, end: Alignment.bottomLeft),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Color(0xFF4F6F52).withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.waving_hand, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً $profName', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('نتمنى لك يوماً موفقاً في التدريس', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== CARTES DASHBOARD - VERSION FINALE ====================
// Remplacer _buildStatsCards() et _buildStatCard() dans teacher_page.dart

  Widget _buildStatsCards() {
    if (isLoading) return Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Première ligne - 2 cartes
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'مجموعاتي',
                count: totalGroups,
                icon: Icons.groups_rounded,
                gradient: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'إجمالي الطلاب',
                count: totalStudents,
                icon: Icons.school_rounded,
                gradient: [Color(0xFF5F7A61), Color(0xFF739072)],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Deuxième ligne - 2 cartes
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'الاختبارات القادمة',
                count: 0,
                icon: Icons.assignment_rounded,
                gradient: [Color(0xFF739072), Color(0xFF86A789)],
                futureCount: _getUpcomingExamsCount(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'معدل الحفظ',
                count: 0,
                icon: Icons.trending_up_rounded,
                gradient: [Color(0xFF2D5F3F), Color(0xFF4F6F52)],
                suffix: ' حزب',
                futureCount: _getAverageHafd(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradient,
    String suffix = '',
    Future<int>? futureCount,
  }) {
    return Container(
      height: 110, // ✅ Taille réduite (était ~130)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // En-tête : Titre + Icône
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            
            // Nombre
            futureCount != null
                ? FutureBuilder<int>(
                    future: futureCount,
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? count}$suffix',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                : Text(
                    '$count$suffix',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExams() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text('الاختبارات القادمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder<List<ExamModel>>(
            future: _examService.getUpcomingExams(_auth.currentUser!.uid, limit: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 60, color: Colors.grey[300]),
                        SizedBox(height: 12),
                        Text('لا توجد اختبارات قادمة', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: snapshot.data!.map((exam) => _buildExamItem(exam)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamItem(ExamModel exam) {
    Color statusColor = exam.status == 'approved' ? Colors.orange : Colors.green;
    int daysUntil = exam.examDate.difference(DateTime.now()).inDays;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.assignment, color: statusColor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('نوع الاختبار: ${exam.type}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text('التاريخ: ${exam.examDate.toString().split(' ')[0]}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
            child: Text(daysUntil > 0 ? 'بعد $daysUntil يوم' : 'اليوم', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizationRules() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text('قواعد برنامج الحفظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
            ],
          ),
          SizedBox(height: 16),
          _buildRuleItem('حفظ نصف جزء أو جزء كامل يومياً'),
          _buildRuleItem('تكرار الورد 50 مرة في الحصة'),
          _buildRuleItem('احترام المواعيد والالتزام بالحضور'),
          _buildRuleItem('المراجعة المستمرة للأحزاب السابقة'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: Color(0xFF4F6F52), shape: BoxShape.circle)),
          SizedBox(width: 12),
          Expanded(child: Text(rule, style: TextStyle(fontSize: 15, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsAccess() {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('صفحة الإعلانات قيد التطوير'))),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4F6F52).withOpacity(0.1), Color(0xFF6B8F71).withOpacity(0.1)], begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF4F6F52).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Color(0xFF4F6F52), size: 28),
                SizedBox(width: 12),
                Text('الاطلاع على آخر المستجدات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4F6F52), decoration: TextDecoration.underline)),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Color(0xFF4F6F52), size: 18),
          ],
        ),
      ),
    );
  }

  Future<int> _getUpcomingExamsCount() async {
    try {
      List<ExamModel> exams = await _examService.getUpcomingExams(_auth.currentUser!.uid, limit: 100);
      return exams.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getAverageHafd() async {
    try {
      QuerySnapshot groupsSnapshot = await _firestore.collection('groups').where('profId', isEqualTo: _auth.currentUser?.uid).get();
      if (groupsSnapshot.docs.isEmpty) return 0;

      int totalHafd = 0;
      int studentCount = 0;

      for (var groupDoc in groupsSnapshot.docs) {
        List<dynamic> studentIds = (groupDoc.data() as Map<String, dynamic>)['studentIds'] ?? [];
        for (String studentId in studentIds) {
          DocumentSnapshot studentDoc = await _firestore.collection('users').doc(studentId).get();
          if (studentDoc.exists) {
            Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
            int oldHafd = ((data['oldHafd'] ?? 0) as num).toInt();
            int newHafd = ((data['newHafd'] ?? 0) as num).toInt();
            totalHafd += (oldHafd + newHafd);
            studentCount++;
          }
        }
      }
      return studentCount > 0 ? (totalHafd / studentCount).round() : 0;
    } catch (e) {
      return 0;
    }
  }
}