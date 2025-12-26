import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../login_page.dart';
import 'student_profile_card_page.dart';
import 'student_tracking_summary_page.dart';
import 'counter_page.dart';
import 'send_remark_page.dart';
import 'account_settings_page.dart';
import 'student_exams_page.dart';
import 'student_announcements_page.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../widgets/exam_notification_banner.dart';  // ✅ NOUVELLE PAGE

class StudentPage extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExamService _examService = ExamService();
  
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
      print('Erreur chargement données: $e');
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
          title: Text('الصفحة الرئيسية'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          actions: [
            // ✅ BADGE NOTIFICATION ANNONCES
            _buildNotificationBadge(),
          ],
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NOUVEAU : Bannière d'examens à venir
                    _buildWelcomeCard(),
                    SizedBox(height: 20),
                    _buildProgressCard(),
                    SizedBox(height: 20),
                    _buildQuickActions(),
                    SizedBox(height: 20),
                    _buildExamNotificationBanner(),
                    _buildAnnouncementsPreview(),
                  ],
                ),
              ),
      ),
    );
  }

  // ✅ NOUVEAU : Badge notification avec compteur
  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('announcements').snapshots(),
      builder: (context, announcementSnapshot) {
        if (!announcementSnapshot.hasData) {
          return IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => _navigateToAnnouncements(),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(currentUser?.id)
              .snapshots(),
          builder: (context, userSnapshot) {
            int unreadCount = 0;

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
              List<String> readAnnouncements = List<String>.from(
                userData['readAnnouncements'] ?? []
              );

              List<String> allAnnouncementIds = announcementSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toList();

              unreadCount = allAnnouncementIds
                  .where((id) => !readAnnouncements.contains(id))
                  .length;
            }

            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined),
                  onPressed: () => _navigateToAnnouncements(),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToAnnouncements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentAnnouncementsPage(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // 🎨 HEADER AMÉLIORÉ avec dégradé diagonal
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2D5016),  // Vert foncé
                  Color(0xFF4F6F52),  // Vert moyen
                  Color(0xFF739072),  // Vert clair
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar avec bordure blanche
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: currentUser?.profileImage != null
                        ? NetworkImage(currentUser!.profileImage!)
                        : null,
                    child: currentUser?.profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF4F6F52),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                
                // Nom avec style moderne
                Text(
                  currentUser?.fullName ?? 'الطالب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                
                // Email avec icône
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // 📋 MENU ITEMS AMÉLIORÉS
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // Accueil
                _buildModernDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'الرئيسية',
                  color: Color(0xFF4F6F52),
                  onTap: () => Navigator.pop(context),
                ),
                
                SizedBox(height: 4),
                
                // Fيش
                _buildModernDrawerItem(
                  icon: Icons.badge_outlined,
                  title: 'الفيش الشخصي',
                  color: Color(0xFF5F8D4E),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentProfileCardPage()),
                    );
                  },
                ),
                
                SizedBox(height: 4),
                
                // Suivi
                _buildModernDrawerItem(
                  icon: Icons.assessment_outlined,
                  title: 'فيش المتابعة',
                  color: Color(0xFFf39c12),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentTrackingSummaryPage()),
                    );
                  },
                ),
                
                SizedBox(height: 4),
                
                // Compteur
                _buildModernDrawerItem(
                  icon: Icons.calculate_outlined,
                  title: 'العداد',
                  color: Color(0xFF3498db),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CounterPage()),
                    );
                  },
                ),
                
                SizedBox(height: 4),
                
                // Annonces avec badge
                _buildDrawerItemWithBadge(
                  icon: Icons.campaign_outlined,
                  title: 'الإعلانات',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAnnouncements();
                  },
                ),
                
                SizedBox(height: 4),
                
                // Message
                _buildModernDrawerItem(
                  icon: Icons.message_outlined,
                  title: 'إرسال ملاحظة',
                  color: Color(0xFF16a085),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SendRemarkPage()),
                    );
                  },
                ),
                
                SizedBox(height: 4),
                
                // Examens
                _buildModernDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: 'الامتحانات',
                  color: Color(0xFF9b59b6),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentExamsPage()),
                    );
                  },
                ),
                
                SizedBox(height: 12),
                Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                SizedBox(height: 12),
                
                _buildModernDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'إعدادات الحساب',
                  color: Colors.grey[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountSettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 🚪 DÉCONNEXION EN BAS
          Divider(height: 1),
          _buildModernDrawerItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            color: Colors.red,
            isLogout: true,
            onTap: () async {
              await _authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_back_ios,
          color: Colors.grey[400],
          size: 14,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: color.withOpacity(0.05),
      ),
    );
  }

  // ✅ GARDE L'ANCIEN _buildDrawerItemWithBadge (ne change rien)
  Widget _buildDrawerItemWithBadge({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('announcements').snapshots(),
      builder: (context, announcementSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(currentUser?.id)
              .snapshots(),
          builder: (context, userSnapshot) {
            int unreadCount = 0;

            if (announcementSnapshot.hasData && 
                userSnapshot.hasData && 
                userSnapshot.data!.exists) {
              Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
              List<String> readAnnouncements = List<String>.from(
                userData['readAnnouncements'] ?? []
              );

              List<String> allAnnouncementIds = announcementSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toList();

              unreadCount = allAnnouncementIds
                  .where((id) => !readAnnouncements.contains(id))
                  .length;
            }

            return Container(
              margin: EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFe74c3c).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFFe74c3c),
                    size: 22,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_back_ios,
                      color: Colors.grey[400],
                      size: 14,
                    ),
                  ],
                ),
                onTap: onTap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Color(0xFFe74c3c).withOpacity(0.05),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Color(0xFF4F6F52),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ✅ NOUVEAU : DrawerItem avec badge

  Widget _buildWelcomeCard() {
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
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${currentUser?.firstName ?? "الطالب"}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'استمر في المذاكرة والتقدم',
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
    );
  }

  Widget _buildExamNotificationBanner() {
    if (currentUser == null) return SizedBox.shrink();

    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getStudentUpcomingExamsStream(currentUser!.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink(); // Ne rien afficher pendant le chargement
        }

        List<ExamModel> upcomingExams = snapshot.data!;
        
        if (upcomingExams.isEmpty) {
          return SizedBox.shrink(); // Pas d'examens à venir
        }

        return ExamNotificationBanner(
          upcomingExams: upcomingExams,
        );
      },
    );
  }


  Widget _buildProgressCard() {
    int oldHafd = currentUser?.oldHafd ?? 0;
    int newHafd = currentUser?.newHafd ?? 0;
    int totalHafd = (oldHafd + newHafd).clamp(0, 60);
    double progress = totalHafd / 60;

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
              Icon(Icons.bar_chart, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'تقدم الحفظ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F6F52)),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          SizedBox(height: 12),
          Text(
            '$totalHafd من 60 جزءاً',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات السريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F6F52),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.badge,
                title: 'الفيش',
                color: Color(0xFF4F6F52),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentProfileCardPage()),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calculate,
                title: 'العداد',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CounterPage()),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assessment,
                title: 'المتابعة',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentTrackingSummaryPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MODIFIÉ : Aperçu des annonces avec lien "Voir الكل"
  Widget _buildAnnouncementsPreview() {
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
                  Icon(Icons.campaign, color: Color(0xFF4F6F52)),
                  SizedBox(width: 8),
                  Text(
                    'الإعلانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToAnnouncements,
                child: Text(
                  'عرض الكل',
                  style: TextStyle(color: Color(0xFF4F6F52)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .limit(2)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد إعلانات حالياً',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF4F6F52).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.campaign, size: 20, color: Color(0xFF4F6F52)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data['title'] ?? 'إعلان',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}