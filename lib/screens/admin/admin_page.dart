// lib/screens/admin/admin_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import 'manage_students_page.dart';
import 'manage_teachers_page.dart';
import 'manage_groups_page.dart';
import 'schedule_page.dart'; // ✅ EMPLOI DU TEMPS
import 'send_announcement_page.dart'; // ✅ ANNONCES
import 'view_remarks_page.dart'; // ✅ REMARQUES
import '../../services/activity_service.dart';
import '../../services/stats_service.dart';


class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalStudents = 0;
  int totalTeachers = 0;
  int totalGroups = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();
      
      final teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'prof')
          .get();
      
      final groupsSnapshot = await _firestore
          .collection('groups')
          .get();

      setState(() {
        totalStudents = studentsSnapshot.docs.length;
        totalTeachers = teachersSnapshot.docs.length;
        totalGroups = groupsSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
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
          title: Text('لوحة تحكم الإدارة'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Notifications page
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 20),
                      _buildStatsCards(),
                      SizedBox(height: 25),
                      _buildProgressChart(),
                      SizedBox(height: 25),
                      _buildRecentActivities(),
                      SizedBox(height: 25),
                      _buildRemarks(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2D5016),  // Vert foncé élégant
            Color(0xFF4F6F52),  // Vert moyen
            Color(0xFF739072),  // Vert clair
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(Icons.dashboard_rounded, color: Colors.white, size: 36),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'لوحة التحكم الرئيسية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, color: Colors.amber, size: 24),
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION 1: Cards responsive (web 4 colonnes, mobile 2 colonnes)
  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: Web (4 colonnes) vs Mobile (2 colonnes)
        bool isWeb = constraints.maxWidth > 600;
        int crossAxisCount = isWeb ? 4 : 2;
        double aspectRatio = isWeb ? 1.3 : 1.1;

        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              title: 'الطلاب',
              count: totalStudents,
              icon: Icons.school,
              color: Color(0xFF4F6F52),
              gradient: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
            ),
            _buildStatCard(
              title: 'الأساتذة',
              count: totalTeachers,
              icon: Icons.person,
              color: Color(0xFF2D5F3F),
              gradient: [Color(0xFF2D5F3F), Color(0xFF4F6F52)],
            ),
            _buildStatCard(
              title: 'المجموعات',
              count: totalGroups,
              icon: Icons.groups,
              color: Color(0xFF739072),
              gradient: [Color(0xFF739072), Color(0xFF86A789)],
            ),
            _buildStatCard(
              title: 'الامتحانات',
              count: 0,
              icon: Icons.assignment,
              color: Color(0xFF5F7A61),
              gradient: [Color(0xFF5F7A61), Color(0xFF739072)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(10),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تطور عدد الطلاب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
              Icon(Icons.trending_up, color: Color(0xFF4F6F52)),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: StatsService().getStudentsGrowth(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> data = snapshot.data!;
                
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد بيانات كافية',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                List<FlSpot> spots = [];
                for (int i = 0; i < data.length; i++) {
                  spots.add(FlSpot(i.toDouble(), data[i]['count'].toDouble()));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < data.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  data[index]['monthName'],
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Color(0xFF4F6F52),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(0xFF4F6F52).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION 2: Scroll dans les activités récentes (Container avec maxHeight + ScrollPhysics activé)
  Widget _buildRecentActivities() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'آخر النشاطات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('activities')
                .orderBy('createdAt', descending: true)
                .limit(10) // Augmenté de 5 à 10
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد نشاطات حديثة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              // ✅ Container avec hauteur max pour scroll
              return Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(), // ✅ Scroll activé
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(height: 20),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    String type = data['type'] ?? '';
                    String title = data['title'] ?? 'نشاط جديد';
                    String description = data['description'] ?? '';
                    Timestamp? timestamp = data['createdAt'] as Timestamp?;
                    
                    String timeAgo = 'الآن';
                    if (timestamp != null) {
                      Duration diff = DateTime.now().difference(timestamp.toDate());
                      if (diff.inMinutes < 1) {
                        timeAgo = 'الآن';
                      } else if (diff.inMinutes < 60) {
                        timeAgo = 'منذ ${diff.inMinutes} دقيقة';
                      } else if (diff.inHours < 24) {
                        timeAgo = 'منذ ${diff.inHours} ساعة';
                      } else {
                        timeAgo = 'منذ ${diff.inDays} يوم';
                      }
                    }

                    return _buildActivityItem(
                      icon: ActivityService.getIconForType(type),
                      title: title,
                      subtitle: description,
                      time: timeAgo,
                      color: ActivityService.getColorForType(type),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? Color(0xFF4F6F52)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? Color(0xFF4F6F52), size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRemarks() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.feedback, color: Colors.orange, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'الملاحظات الواردة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ViewRemarksPage()),
                  );
                },
                icon: Icon(Icons.arrow_back, size: 18),
                label: Text('عرض الكل'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('remarks')
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                        SizedBox(height: 8),
                        Text(
                          'لا توجد ملاحظات جديدة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => Divider(height: 20),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  String subject = data['subject'] ?? '';
                  String type = data['type'] ?? '';
                  String status = data['status'] ?? 'new';
                  bool isAnonymous = data['isAnonymous'] ?? false;
                  String senderName = isAnonymous ? 'مجهول' : (data['senderName'] ?? '');
                  
                  IconData typeIcon;
                  Color typeColor;
                  switch (type) {
                    case 'suggestion':
                      typeIcon = Icons.lightbulb;
                      typeColor = Colors.amber;
                      break;
                    case 'problem':
                      typeIcon = Icons.warning;
                      typeColor = Colors.red;
                      break;
                    case 'question':
                      typeIcon = Icons.help;
                      typeColor = Colors.blue;
                      break;
                    default:
                      typeIcon = Icons.info;
                      typeColor = Colors.grey;
                  }
                  
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ViewRemarksPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 22),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'من: $senderName',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'new' ? Colors.red[100] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status == 'new' ? 'جديد' : 'مفتوح',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'new' ? Colors.red[900] : Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
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
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Color(0xFF4F6F52),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'لوحة تحكم الإدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'مرحباً بك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'الرئيسية',
                  onTap: () => Navigator.pop(context),
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'الإدارة',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'الأساتذة',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageTeachersPage(),
                      ),
                    );
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.school_outlined,
                  title: 'الطلاب',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageStudentsPage(),
                      ),
                    );
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.groups_outlined,
                  title: 'المجموعات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageGroupsPage(),
                      ),
                    );
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.schedule,
                  title: 'جدول الأوقات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchedulePage(),
                      ),
                    );
                  },
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'التواصل',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                _buildDrawerItem(
                  icon: Icons.campaign,
                  title: 'إرسال إعلان',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendAnnouncementPage(),
                      ),
                    );
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.feedback_outlined,
                  title: 'الملاحظات الواردة',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewRemarksPage(),
                      ),
                    );
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
            onTap: () async {
              await _authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Color(0xFF4F6F52),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        hoverColor: Color(0xFF4F6F52).withOpacity(0.1),
        selectedTileColor: Color(0xFF4F6F52).withOpacity(0.1),
      ),
    );
  }
}