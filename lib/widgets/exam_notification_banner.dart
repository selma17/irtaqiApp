// lib/widgets/exam_notification_banner.dart
// 🎨 DESIGN MINIMALISTE NOTION - Clean et moderne

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam_model.dart';
import '../screens/student/student_exams_page.dart';

class ExamNotificationBanner extends StatelessWidget {
  final List<ExamModel> upcomingExams;

  const ExamNotificationBanner({
    Key? key,
    required this.upcomingExams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (upcomingExams.isEmpty) {
      return SizedBox.shrink();
    }

    ExamModel nextExam = upcomingExams.first;
    int daysUntil = _getDaysUntilExam(nextExam.examDate);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentExamsPage()),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(daysUntil),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                // Emoji + Type
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(daysUntil),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEmoji(daysUntil),
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                
                SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextExam.typeDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getUrgencyText(daysUntil),
                        style: TextStyle(
                          fontSize: 13,
                          color: _getTextColor(daysUntil),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge jours
                if (daysUntil <= 7)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(daysUntil),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          daysUntil == 0 ? 'الآن' : daysUntil.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(daysUntil),
                          ),
                        ),
                        if (daysUntil > 0)
                          Text(
                            daysUntil == 1 ? 'يوم' : 'أيام',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTextColor(daysUntil).withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Infos row
            Row(
              children: [
                // Date
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today_outlined,
                    _formatExamDate(nextExam.examDate),
                  ),
                ),
                
                if (nextExam.groupName != null) ...[
                  SizedBox(width: 12),
                  // Groupe
                  Expanded(
                    child: _buildInfoItem(
                      Icons.group_outlined,
                      nextExam.groupName!,
                    ),
                  ),
                ],
              ],
            ),
            
            if (upcomingExams.length > 1) ...[
              SizedBox(height: 12),
              // Badge autres examens
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 14,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 6),
                    Text(
                      'لديك ${upcomingExams.length - 1} امتحانات أخرى',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_back_ios,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(int days) {
    if (days == 0) return '🔥';
    if (days == 1) return '⚡';
    if (days <= 3) return '⏰';
    return '📋';
  }

  Color _getBorderColor(int days) {
    if (days == 0) return Color(0xFFFF4757);
    if (days == 1) return Color(0xFFFF6348);
    if (days <= 3) return Color(0xFFFFA502);
    return Color(0xFF4F6F52);
  }

  Color _getBackgroundColor(int days) {
    if (days == 0) return Color(0xFFFF4757).withOpacity(0.1);
    if (days == 1) return Color(0xFFFF6348).withOpacity(0.1);
    if (days <= 3) return Color(0xFFFFA502).withOpacity(0.1);
    return Color(0xFF4F6F52).withOpacity(0.1);
  }

  Color _getTextColor(int days) {
    if (days == 0) return Color(0xFFFF4757);
    if (days == 1) return Color(0xFFFF6348);
    if (days <= 3) return Color(0xFFFFA502);
    return Color(0xFF4F6F52);
  }

  int _getDaysUntilExam(DateTime? examDate) {
    if (examDate == null) return 999;
    DateTime now = DateTime.now();
    return examDate.difference(now).inDays;
  }

  String _getUrgencyText(int days) {
    if (days == 0) return 'الامتحان اليوم!';
    if (days == 1) return 'الامتحان غداً';
    if (days <= 3) return 'الامتحان قريب جداً';
    if (days <= 7) return 'الامتحان هذا الأسبوع';
    return 'امتحان قادم';
  }

  String _formatExamDate(DateTime? examDate) {
    if (examDate == null) return 'غير محدد';

    DateTime now = DateTime.now();
    Duration difference = examDate.difference(now);
    String time = DateFormat('HH:mm').format(examDate);

    if (difference.inDays == 0) {
      return 'اليوم $time';
    } else if (difference.inDays == 1) {
      return 'غداً $time';
    } else if (difference.inDays < 7) {
      return 'بعد ${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM/yyyy').format(examDate);
    }
  }
}