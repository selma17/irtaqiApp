// lib/screens/common/view_announcements_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/announcement_service.dart';

class ViewAnnouncementsPage extends StatefulWidget {
  final String userRole;
  final String? groupId;

  const ViewAnnouncementsPage({
    required this.userRole,
    this.groupId,
  });

  @override
  _ViewAnnouncementsPageState createState() => _ViewAnnouncementsPageState();
}

class _ViewAnnouncementsPageState extends State<ViewAnnouncementsPage> {
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    // ✅ Récupérer l'ID de l'utilisateur actuel
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الإعلانات'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        // ✅ CORRECTION : Stream<List<DocumentSnapshot>>
        body: StreamBuilder<List<DocumentSnapshot>>(
          stream: _announcementService.getAnnouncementsForUser(
            userId,
            widget.userRole,
            widget.groupId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('حدث خطأ في تحميل الإعلانات'),
              );
            }

            // ✅ CORRECTION : snapshot.data est maintenant List<DocumentSnapshot>
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إعلانات حالياً',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // ✅ CORRECTION : Utiliser directement snapshot.data!
            List<DocumentSnapshot> announcements = snapshot.data!;

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                DocumentSnapshot doc = announcements[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                return _buildAnnouncementCard(doc.id, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(String announcementId, Map<String, dynamic> data) {
    String title = data['title'] ?? '';
    String content = data['content'] ?? '';
    String? imageUrl = data['imageUrl'];
    Timestamp? createdAt = data['createdAt'];
    String createdBy = data['createdBy'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(announcementId, data),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image si présente
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Contenu
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4F6F52).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.campaign,
                          color: Color(0xFF4F6F52),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (content.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(
                      content,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 12),

                  // Footer avec date et auteur
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _announcementService.formatDate(createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Spacer(),
                      FutureBuilder<String>(
                        future: _announcementService.getCreatorName(createdBy),
                        builder: (context, snapshot) {
                          return Row(
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                snapshot.data ?? 'الإدارة',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          );
                        },
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

  void _showAnnouncementDetails(String announcementId, Map<String, dynamic> data) {
    String title = data['title'] ?? '';
    String content = data['content'] ?? '';
    String? imageUrl = data['imageUrl'];
    Timestamp? createdAt = data['createdAt'];
    String createdBy = data['createdBy'] ?? '';

    // Marquer comme vue
    _announcementService.markAsViewed(announcementId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image si présente
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],

              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF4F6F52).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.campaign,
                            color: Color(0xFF4F6F52),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F6F52),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (content.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 12),

                    // Infos
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          _announcementService.formatDate(createdAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _announcementService.getCreatorName(createdBy),
                      builder: (context, snapshot) {
                        return Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Text(
                              'من: ${snapshot.data ?? "الإدارة"}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}