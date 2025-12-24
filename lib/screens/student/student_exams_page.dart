// lib/screens/student/student_exams_page.dart
// ✅ Page examens pour étudiants - Voir examens à venir + résultats

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentExamsPage extends StatefulWidget {
  @override
  _StudentExamsPageState createState() => _StudentExamsPageState();
}

class _StudentExamsPageState extends State<StudentExamsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String selectedTab = 'upcoming'; // upcoming, results

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('امتحاناتي'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            SizedBox(height: 16),
            _buildHeader(),
            SizedBox(height: 16),
            _buildTabs(),
            SizedBox(height: 16),
            Expanded(
              child: selectedTab == 'upcoming'
                  ? _buildUpcomingExams()
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
            child: Icon(Icons.quiz, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امتحاناتي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'متابعة الامتحانات والنتائج',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'الامتحانات القادمة',
              'upcoming',
              Icons.upcoming,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              'النتائج',
              'results',
              Icons.grade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value, IconData icon) {
    bool isSelected = selectedTab == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4F6F52) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF4F6F52) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExams() {
    String? studentId = _auth.currentUser?.uid;
    if (studentId == null) return Center(child: Text('خطأ'));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد امتحانات قادمة',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // ✅ Filtrer côté client pour status pending/approved
        List<DocumentSnapshot> upcomingExams = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? '';
          return status == 'pending' || status == 'approved';
        }).toList();

        if (upcomingExams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد امتحانات قادمة',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: upcomingExams.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            var doc = upcomingExams[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildUpcomingExamCard(data);
          },
        );
      },
    );
  }

  Widget _buildUpcomingExamCard(Map<String, dynamic> data) {
    String type = data['type'] ?? '';
    String typeDisplay = type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
    
    Timestamp? examDateTs = data['examDate'];
    String dateDisplay = examDateTs != null
        ? '${examDateTs.toDate().day}/${examDateTs.toDate().month}/${examDateTs.toDate().year}'
        : 'لم يحدد بعد';
    
    String status = data['status'] ?? '';
    bool isWaiting = type == '10ahzab' && status == 'pending';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWaiting ? Colors.orange[300]! : Color(0xFF4F6F52).withOpacity(0.3),
          width: 2,
        ),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: type == '10ahzab' ? Colors.purple[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: type == '10ahzab' ? Colors.purple[700] : Colors.blue[700],
                  ),
                ),
              ),
              Spacer(),
              if (isWaiting)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, size: 14, color: Colors.orange[700]),
                      SizedBox(width: 4),
                      Text(
                        'قيد التحضير',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'التاريخ: $dateDisplay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isWaiting) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الإدارة بصدد تحديد موعد الامتحان',
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

  Widget _buildResults() {
    String? studentId = _auth.currentUser?.uid;
    if (studentId == null) return Center(child: Text('خطأ'));

    // ✅ CORRIGÉ : Query simple sans where + orderBy
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('📊 RÉSULTATS ÉTUDIANT: Aucun examen trouvé');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد نتائج بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        print('📊 RÉSULTATS ÉTUDIANT: ${snapshot.data!.docs.length} examens totaux');

        // ✅ AJOUTÉ : Filtrer côté client pour status = graded
        List<DocumentSnapshot> gradedExams = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('   - Examen ${doc.id}: status=${data['status']}, grade=${data['grade']}');
          return data['status'] == 'graded';
        }).toList();

        print('📊 RÉSULTATS ÉTUDIANT: ${gradedExams.length} examens notés');

        // ✅ AJOUTÉ : Trier par completedAt (plus récent en premier)
        gradedExams.sort((a, b) {
          Timestamp? aTime = (a.data() as Map<String, dynamic>)['completedAt'];
          Timestamp? bTime = (b.data() as Map<String, dynamic>)['completedAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending
        });

        if (gradedExams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد نتائج بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: gradedExams.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            var doc = gradedExams[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildResultCard(data);
          },
        );
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    String type = data['type'] ?? '';
    String typeDisplay = type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
    
    int grade = data['grade'] ?? 0;
    bool isPassed = grade >= 15;
    String notes = data['notes'] ?? '';
    
    Timestamp? completedAtTs = data['completedAt'];
    String dateDisplay = completedAtTs != null
        ? '${completedAtTs.toDate().day}/${completedAtTs.toDate().month}/${completedAtTs.toDate().year}'
        : 'غير محدد';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed ? Colors.green[300]! : Colors.red[300]!,
          width: 2,
        ),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: type == '10ahzab' ? Colors.purple[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: type == '10ahzab' ? Colors.purple[700] : Colors.blue[700],
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPassed ? Colors.green[300]! : Colors.red[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$grade/20',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      isPassed ? Icons.check_circle : Icons.cancel,
                      color: isPassed ? Colors.green[700] : Colors.red[700],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                'تاريخ الامتحان: $dateDisplay',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPassed ? Icons.emoji_events : Icons.replay,
                size: 16,
                color: isPassed ? Colors.green[700] : Colors.red[700],
              ),
              SizedBox(width: 6),
              Text(
                isPassed ? 'ناجح' : 'راسب - يجب الإعادة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF6F3EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment, size: 14, color: Color(0xFF4F6F52)),
                      SizedBox(width: 6),
                      Text(
                        'ملاحظات الأستاذ:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
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
}