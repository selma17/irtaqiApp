// lib/screens/professor/professor_announcements_page.dart
// ✅ VERSION COMPLÈTE - Avec filtres (الكل / جديدة / مقروءة)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../services/auth_service.dart';

class TeacherAnnouncementsPage extends StatefulWidget {
  @override
  _TeacherAnnouncementsPageState createState() => _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState extends State<TeacherAnnouncementsPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? currentUserId;
  String? currentUserGroupId;
  
  // ✅ Filtre actif
  String _currentFilter = 'all'; // 'all', 'new', 'read'

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUserId = _authService.getCurrentUserId();
    
    if (currentUserId != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          currentUserGroupId = (userDoc.data() as Map<String, dynamic>)['assignedGroupId'];
        });
      }
    }
  }

  Future<void> _markAsRead(String announcementId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'readAnnouncements': FieldValue.arrayUnion([announcementId])
      });
    } catch (e) {
      print('Erreur marquage lecture: $e');
    }
  }

  bool _isAnnouncementRead(String announcementId, List<String> readAnnouncements) {
    return readAnnouncements.contains(announcementId);
  }

  bool _isAnnouncementForTeacher(Map<String, dynamic> data) {
    String targetAudience = data['targetAudience'] ?? 'all';
    
    switch (targetAudience) {
      case 'all':
        return true;
      case 'teachers':
        return true;
      case 'students':
        return false;
      case 'group':
        String? announcementGroupId = data['groupId'];
        return announcementGroupId == currentUserGroupId;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('الإعلانات')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            _buildFilterChips(),
            SizedBox(height: 16),
            Expanded(child: _buildAnnouncementsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip(label: 'الكل', value: 'all', icon: Icons.list),
          SizedBox(width: 12),
          _buildFilterChip(label: 'جديدة', value: 'new', icon: Icons.new_releases),
          SizedBox(width: 12),
          _buildFilterChip(label: 'مقروءة', value: 'read', icon: Icons.done_all),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    bool isSelected = _currentFilter == value;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentFilter = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4F6F52) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Color(0xFF4F6F52) : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Color(0xFF4F6F52).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 18),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<String> readAnnouncements = [];
        if (userSnapshot.data!.exists) {
          Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
          readAnnouncements = List<String>.from(userData['readAnnouncements'] ?? []);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            List<DocumentSnapshot> filteredByAudience = snapshot.data!.docs.where((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return _isAnnouncementForTeacher(data);
            }).toList();

            List<DocumentSnapshot> filteredDocs = filteredByAudience.where((doc) {
              bool isRead = _isAnnouncementRead(doc.id, readAnnouncements);
              
              switch (_currentFilter) {
                case 'all': return true;
                case 'new': return !isRead;
                case 'read': return isRead;
                default: return true;
              }
            }).toList();

            if (filteredDocs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = filteredDocs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                
                String title = data['title'] ?? 'بدون عنوان';
                String content = data['content'] ?? '';
                String targetAudience = data['targetAudience'] ?? 'all';
                Timestamp? timestamp = data['createdAt'];
                bool isRead = _isAnnouncementRead(doc.id, readAnnouncements);

                return _buildAnnouncementCard(
                  announcementId: doc.id,
                  title: title,
                  content: content,
                  targetAudience: targetAudience,
                  timestamp: timestamp,
                  isRead: isRead,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'لا توجد إعلانات';
    if (_currentFilter == 'new') message = 'لا توجد إعلانات جديدة';
    else if (_currentFilter == 'read') message = 'لا توجد إعلانات مقروءة';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String announcementId,
    required String title,
    required String content,
    required String targetAudience,
    Timestamp? timestamp,
    required bool isRead,
  }) {
    String formattedDate = 'غير محدد';
    if (timestamp != null) {
      DateTime dateTime = timestamp.toDate();
      formattedDate = DateFormat('HH:mm - dd/MM/yyyy', 'ar').format(dateTime);
    }

    // Badge couleur selon destinataire
    Color badgeColor = Color(0xFF4F6F52);
    switch (targetAudience) {
      case 'teachers': badgeColor = Color(0xFF3498db); break;
      case 'students': badgeColor = Color(0xFFf39c12); break;
      case 'group': badgeColor = Color(0xFF9b59b6); break;
    }

    return GestureDetector(
      onTap: () async {
        await _markAsRead(announcementId);
        _showAnnouncementDialog(title, content, formattedDate);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            if (!isRead) SizedBox(width: 12),
            
            Icon(Icons.arrow_back_ios, color: Colors.grey[400], size: 16),
            SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(String title, String content, String date) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, style: TextStyle(color: Color(0xFF4F6F52), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content, style: TextStyle(fontSize: 16)),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق', style: TextStyle(color: Color(0xFF4F6F52))),
            ),
          ],
        ),
      ),
    );
  }
}