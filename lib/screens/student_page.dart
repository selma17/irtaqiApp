// lib/screens/student_page.dart - VERSION MODIFIÉE

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'view_followup_page.dart';  // ✅ NOUVEAU

class StudentPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur actuel
    User? currentUser = _authService.currentUser;
    String studentId = currentUser?.uid ?? '';
    String studentEmail = currentUser?.email ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text("واجهة الطالب"),
          backgroundColor: Color(0xFF4F6F52),
        ),
        drawer: _buildDrawer(context, studentId, studentEmail),  // ✅ Drawer avec navigation
        body: Center(
          child: Text(
            "أهلا بك، أيها الطالب",
            style: TextStyle(fontSize: 20, color: Color(0xFF4F6F52)),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String studentId, String studentEmail) {
    return Drawer(
      child: Column(
        children: [
          // Header
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
                    Icons.person,
                    size: 30,
                    color: Color(0xFF4F6F52),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'حساب الطالب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  studentEmail,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'الرئيسية',
                  onTap: () => Navigator.pop(context),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'المتابعة',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ✅ NOUVEAU: Fiches de suivi
                _buildDrawerItem(
                  context,
                  icon: Icons.event_note,
                  title: 'فيشات متابعتي',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewFollowupPage(
                          studentId: studentId,
                          studentName: 'أنا',  // Ou récupérer le nom réel
                        ),
                      ),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.book,
                  title: 'تقدمي في الحفظ',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to progress page
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: 'إحصائياتي',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to stats page
                  },
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'الإعدادات',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'ملفي الشخصي',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to profile page
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.notifications,
                  title: 'الإشعارات',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to notifications page
                  },
                ),
              ],
            ),
          ),

          // Logout
          Divider(height: 1),
          _buildDrawerItem(
            context,
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

  Widget _buildDrawerItem(
    BuildContext context, {
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