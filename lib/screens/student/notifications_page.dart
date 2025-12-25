// lib/screens/student/notifications_page.dart
// 📬 PAGE NOTIFICATIONS

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notificationService.getUserNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F6F52)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            List<Map<String, dynamic>> notifications = snapshot.data!;

            return Column(
              children: [
                _buildStatsHeader(notifications),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'الإشعارات',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4F6F52)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await _notificationService.markAllAsRead();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم وضع علامة مقروء على الكل'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text('قراءة الكل'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4F6F52),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(List<Map<String, dynamic>> notifications) {
    int unread = notifications.where((n) => !n['isRead']).length;
    int total = notifications.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لديك $unread إشعار جديد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إجمالي $total إشعار',
                  style: const TextStyle(
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

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    String notificationId = data['id'] ?? '';
    bool isRead = data['isRead'] ?? false;
    String type = data['type'] ?? '';
    String title = data['title'] ?? '';
    String message = data['message'] ?? '';
    String senderName = data['senderName'] ?? 'النظام';
    Timestamp? createdAt = data['createdAt'];

    IconData icon;
    Color color;
    
    switch (type) {
      case 'exam':
        icon = Icons.assignment_outlined;
        color = Colors.blue;
        break;
      case 'result':
        icon = Icons.grade_outlined;
        color = Colors.green;
        break;
      case 'announcement':
        icon = Icons.campaign_outlined;
        color = Colors.purple;
        break;
      case 'test':
        icon = Icons.science_outlined;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    String timeAgo = createdAt != null ? _getTimeAgo(createdAt.toDate()) : '';

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _notificationService.deleteUserNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الإشعار')),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await _notificationService.markAsRead(notificationId);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.transparent : color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            senderName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر إشعاراتك هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}