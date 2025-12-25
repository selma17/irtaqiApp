// lib/widgets/exam_notification_banner.dart
// ✨ VERSION AMÉLIORÉE - Design moderne et élégant

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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient de fond
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F6F52),
                  Color(0xFF6B8F71),
                  Color(0xFF5F8D4E),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          
          // Motif décoratif
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Contenu principal
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentExamsPage(),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête amélioré
                    Row(
                      children: [
                        // Badge avec animation pulse
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF4F6F52),
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 14),
                        
                        // Titre et sous-titre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'لديك امتحان قادم',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Badge compteur
                                  if (upcomingExams.length > 1)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${upcomingExams.length - 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getUrgencyText(daysUntil),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Flèche
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    // Ligne de séparation stylée
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 18),

                    // Détails de l'examen - Grid Layout
                    Row(
                      children: [
                        // Colonne gauche
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoCard(
                                icon: Icons.calendar_month,
                                label: _formatExamDate(nextExam.examDate),
                                isLarge: true,
                              ),
                              SizedBox(height: 10),
                              _buildInfoCard(
                                icon: Icons.menu_book,
                                label: nextExam.typeDisplay,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 10),
                        
                        // Colonne droite
                        Expanded(
                          child: Column(
                            children: [
                              if (nextExam.assignedProfName != null)
                                _buildInfoCard(
                                  icon: Icons.person_outline,
                                  label: nextExam.assignedProfName!,
                                ),
                              if (nextExam.assignedProfName != null && nextExam.groupName != null)
                                SizedBox(height: 10),
                              if (nextExam.groupName != null)
                                _buildInfoCard(
                                  icon: Icons.group_outlined,
                                  label: nextExam.groupName!,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isLarge ? 20 : 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 15 : 13,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  int _getDaysUntilExam(DateTime? examDate) {
    if (examDate == null) return 999;
    DateTime now = DateTime.now();
    return examDate.difference(now).inDays;
  }

  String _getUrgencyText(int days) {
    if (days == 0) return 'الامتحان اليوم! 🔥';
    if (days == 1) return 'الامتحان غداً';
    if (days <= 3) return 'الامتحان قريب جداً';
    if (days <= 7) return 'استعد جيداً';
    return 'لديك وقت كافٍ للتحضير';
  }

  String _formatExamDate(DateTime? date) {
    if (date == null) return 'لم يحدد بعد';

    DateTime now = DateTime.now();
    Duration difference = date.difference(now);

    String formattedTime = DateFormat('HH:mm', 'ar').format(date);

    if (difference.inDays == 0) {
      return 'اليوم - $formattedTime';
    } else if (difference.inDays == 1) {
      return 'غداً - $formattedTime';
    } else if (difference.inDays == 2) {
      return 'بعد غد - $formattedTime';
    } else if (difference.inDays < 7) {
      return 'بعد ${difference.inDays} أيام - $formattedTime';
    } else {
      String formattedDate = DateFormat('dd/MM/yyyy', 'ar').format(date);
      return '$formattedDate - $formattedTime';
    }
  }
}