// lib/screens/student/student_tracking_summary_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'view_followup_page.dart';

class StudentTrackingSummaryPage extends StatefulWidget {
  @override
  _StudentTrackingSummaryPageState createState() => _StudentTrackingSummaryPageState();
}

class _StudentTrackingSummaryPageState extends State<StudentTrackingSummaryPage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? currentUser;
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            currentUser = UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur: $e');
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
          title: Text('ملخص المتابعة'),
          backgroundColor: Color(0xFF4F6F52),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.assessment),
                text: 'إحصائيات الحفظ',
              ),
              Tab(
                icon: Icon(Icons.event_note),
                text: 'فيشات المتابعة',
              ),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildFollowupTab(),
                ],
              ),
      ),
    );
  }

  // Premier onglet : Résumé des statistiques
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(),
          SizedBox(height: 16),
          _buildProgressDetails(),
          SizedBox(height: 16),
          _buildInfoCard(),
        ],
      ),
    );
  }

  // Deuxième onglet : Liste des fiches de suivi
  Widget _buildFollowupTab() {
    if (currentUser == null) {
      return Center(
        child: Text('لا توجد بيانات متاحة'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students_follow_up')
          .doc(currentUser!.id)
          .collection('weekly_records')
          .orderBy('date', descending: true)
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
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_note,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'لا توجد فيشات متابعة حالياً',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'سيتم إضافة فيشات المتابعة من قبل الأستاذ بعد كل حصة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            Timestamp timestamp = data['date'] as Timestamp;
            DateTime date = timestamp.toDate();
            String sura = data['sura'] ?? 'غير محدد';
            String notes = data['notes'] ?? '';

            return _buildFicheCard(
              context,
              ficheId: doc.id,
              date: date,
              sura: sura,
              notes: notes,
            );
          },
        );
      },
    );
  }

  Widget _buildFicheCard(
    BuildContext context, {
    required String ficheId,
    required DateTime date,
    required String sura,
    required String notes,
  }) {
    const monthNames = [
      'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
      'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    String arabicDate = '${date.day} ${monthNames[date.month - 1]} ${date.year}';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewFollowupPage(
                ficheId: ficheId,
                studentId: currentUser!.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color(0xFF4F6F52).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4F6F52),
                            Color(0xFF6B8F71),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4F6F52).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arabicDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F6F52),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'صفحة متابعة أسبوعية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F6F52).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ],
                ),

                Divider(height: 24, thickness: 1),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF4F6F52).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xFF4F6F52).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Color(0xFF4F6F52), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'السورة: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          sura,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (notes.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, color: Colors.orange[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[900],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    int oldHafd = currentUser?.oldHafd ?? 0;
    int newHafd = currentUser?.newHafd ?? 0;
    int totalHafd = oldHafd + newHafd;
    double progress = totalHafd / 60;

    return Container(
      padding: EdgeInsets.all(24),
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
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.assessment, color: Colors.white, size: 50),
          SizedBox(height: 16),
          Text(
            'ملخص الحفظ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$totalHafd',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'حزب من 60',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
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

  Widget _buildProgressDetails() {
    int oldHafd = currentUser?.oldHafd ?? 0;
    int newHafd = currentUser?.newHafd ?? 0;
    int remaining = 60 - (oldHafd + newHafd);

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
              Icon(Icons.pie_chart, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'تفاصيل الحفظ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildProgressRow(
            'الحفظ السابق',
            oldHafd,
            Colors.grey,
            'قبل الانضمام لإرتقيي',
          ),
          SizedBox(height: 16),
          _buildProgressRow(
            'الحفظ الجديد',
            newHafd,
            Colors.green,
            'في برنامج إرتقيي',
          ),
          SizedBox(height: 16),
          _buildProgressRow(
            'المتبقي',
            remaining,
            Colors.orange,
            'من القرآن الكريم',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int value, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'ملاحظة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'يتم تحديث الحفظ الجديد تلقائياً من قبل الأستاذ بعد كل حصة. للاطلاع على التفاصيل الكاملة، يرجى مراجعة فيشات المتابعة في التبويب الثاني.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'استمر في المثابرة والحفظ المنتظم 💪',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}