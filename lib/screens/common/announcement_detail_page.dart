// lib/screens/common/announcement_detail_page.dart
// ✅ Page complète de détails d'une annonce

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final String announcementId;
  final Map<String, dynamic> announcementData;

  AnnouncementDetailPage({
    required this.announcementId,
    required this.announcementData,
  });

  @override
  Widget build(BuildContext context) {
    String title = announcementData['title'] ?? 'إعلان';
    String content = announcementData['content'] ?? announcementData['message'] ?? '';
    String? imageUrl = announcementData['imageUrl'];
    Timestamp? timestamp = announcementData['createdAt'];
    DateTime createdAt = timestamp?.toDate() ?? DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('تفاصيل الإعلان'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
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
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.campaign, color: Colors.white, size: 32),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Image si existe
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 250,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'خطأ في تحميل الصورة',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Contenu
              if (content.isNotEmpty) ...[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          Icon(Icons.description, color: Color(0xFF4F6F52), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'المحتوى',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F6F52),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}