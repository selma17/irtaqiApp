// lib/screens/teacher/teacher_announcements_page.dart
// ✅ VERSION CORRIGÉE - Ajout ouverture détails d'annonce

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/announcement_detail_page.dart';

class TeacherAnnouncementsPage extends StatefulWidget {
  @override
  _TeacherAnnouncementsPageState createState() => _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState extends State<TeacherAnnouncementsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedFilter = 'all'; // all, new, old

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الإعلانات'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildFilterChips(),
            SizedBox(height: 16),
            Expanded(
              child: _buildAnnouncementsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(16),
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.campaign, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإعلانات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تابع آخر الإعلانات والأخبار',
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

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('الكل', 'all'),
          SizedBox(width: 8),
          _buildFilterChip('جديدة', 'new'),
          SizedBox(width: 8),
          _buildFilterChip('مقروءة', 'old'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF4F6F52).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFF4F6F52) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Color(0xFF4F6F52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Color(0xFF4F6F52) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF4F6F52)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل الإعلانات',
                  style: TextStyle(color: Colors.red),
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
                Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد إعلانات حاليًا',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        List<DocumentSnapshot> announcements = snapshot.data!.docs;
        
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .get(),
          builder: (context, userSnapshot) {
            List<String> readAnnouncements = [];
            
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
              readAnnouncements = List<String>.from(userData['readAnnouncements'] ?? []);
            }

            // Filtrer
            List<DocumentSnapshot> filteredAnnouncements = announcements.where((doc) {
              bool isRead = readAnnouncements.contains(doc.id);
              
              if (selectedFilter == 'new') return !isRead;
              if (selectedFilter == 'old') return isRead;
              return true; // 'all'
            }).toList();

            if (filteredAnnouncements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إعلانات في هذا التصنيف',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: filteredAnnouncements.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                var doc = filteredAnnouncements[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                bool isRead = readAnnouncements.contains(doc.id);
                
                return _buildAnnouncementCard(
                  doc.id,
                  data,
                  isRead,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(String announcementId, Map<String, dynamic> data, bool isRead) {
    String title = data['title'] ?? 'إعلان';
    String message = data['message'] ?? data['content'] ?? '';
    Timestamp? timestamp = data['createdAt'];
    DateTime createdAt = timestamp?.toDate() ?? DateTime.now();

    return InkWell(
      // ✅ AJOUTÉ : Ouverture de la page de détails
      onTap: () {
        _markAsRead(announcementId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailPage(
              announcementId: announcementId,
              announcementData: data,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Color(0xFF4F6F52).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[300]! : Color(0xFF4F6F52).withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      color: isRead ? Colors.grey[800] : Color(0xFF4F6F52),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              message.length > 100 ? message.substring(0, 100) + '...' : message,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String announcementId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'readAnnouncements': FieldValue.arrayUnion([announcementId]),
      });
    } catch (e) {
      print('Erreur marquage lecture: $e');
    }
  }
}