// lib/screens/student/my_followup_list_page.dart
// Version LECTURE SEULE pour l'étudiant - réutilise la logique de follow_student_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_followup_page.dart';

class MyFollowupListPage extends StatelessWidget {
  final String studentId;

  const MyFollowupListPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('فيشات متابعتي'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students_follow_up')
              .doc(studentId)
              .collection('weekly_records')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red),
                    SizedBox(height: 16),
                    Text('حدث خطأ في تحميل البيانات'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد فيشات متابعة حالياً',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سيتم إضافة فيشات المتابعة من قبل الأستاذ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;
                
                Timestamp timestamp = data['date'] as Timestamp;
                DateTime date = timestamp.toDate();
                String sura = data['sura'] ?? 'غير محدد';
                String notes = data['notes'] ?? '';

                return _buildFicheCard(
                  context,
                  ficheId: doc.id,
                  date: date,
                  sura: sura,
                  notes: notes,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFicheCard(
    BuildContext context, {
    required String ficheId,
    required DateTime date,
    required String sura,
    required String notes,
  }) {
    const monthNames = [
      'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
      'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    String arabicDate = '${date.day} ${monthNames[date.month - 1]} ${date.year}';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Naviguer vers view_followup_page.dart pour voir les détails
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewFollowupPage(
                ficheId: ficheId,
                studentId: studentId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: Color(0xFF4F6F52),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabicDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6F52),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'صفحة متابعة أسبوعية',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),

              Divider(height: 24),

              Row(
                children: [
                  Icon(Icons.book, color: Color(0xFF4F6F52), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'السورة: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    sura,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              if (notes.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, color: Colors.orange[700], size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}