// lib/screens/teacher/teacher_exams_list_page.dart
// ✅ Liste examens prof avec tableau et notation rapide

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_exam_page.dart';
import 'exam_grading_page.dart';

class TeacherExamsListPage extends StatefulWidget {
  @override
  _TeacherExamsListPageState createState() => _TeacherExamsListPageState();
}

class _TeacherExamsListPageState extends State<TeacherExamsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String selectedFilter = 'all'; // all, pending, graded, 5ahzab, 10ahzab
  String selectedTypeFilter = 'all'; // all, 5ahzab, 10ahzab

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الامتحانات'),
          backgroundColor: Color(0xFF4F6F52),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateExamPage()),
                );
              },
              tooltip: 'إنشاء امتحان',
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(height: 16),
            _buildHeader(),
            SizedBox(height: 16),
            _buildFilters(),
            SizedBox(height: 16),
            Expanded(child: _buildExamsTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الامتحانات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'عرض وتقييم امتحانات الطلاب',
                  style: TextStyle(
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

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تصفية حسب:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all', selectedFilter),
                SizedBox(width: 8),
                _buildFilterChip('قيد الانتظار', 'pending', selectedFilter),
                SizedBox(width: 8),
                _buildFilterChip('تم التقييم', 'graded', selectedFilter),
                SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                SizedBox(width: 16),
                _buildFilterChip('5 أحزاب', '5ahzab', selectedTypeFilter, isType: true),
                SizedBox(width: 8),
                _buildFilterChip('10 أحزاب', '10ahzab', selectedTypeFilter, isType: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, {bool isType = false}) {
    bool isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isType) {
            selectedTypeFilter = selected ? value : 'all';
          } else {
            selectedFilter = selected ? value : 'all';
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF4F6F52).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFF4F6F52) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
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

  Widget _buildExamsTable() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('خطأ في التحقق من الهوية'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .where('createdByProfId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد امتحانات',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateExamPage()),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('إنشاء امتحان جديد'),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF4F6F52),
                  ),
                ),
              ],
            ),
          );
        }

        // Filtrer les examens
        List<DocumentSnapshot> exams = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Filtre statut
          if (selectedFilter != 'all') {
            if (data['status'] != selectedFilter) return false;
          }
          
          // Filtre type
          if (selectedTypeFilter != 'all') {
            if (data['type'] != selectedTypeFilter) return false;
          }
          
          return true;
        }).toList();

        // ✅ Trier par createdAt côté client (gère les null)
        exams.sort((a, b) {
          Timestamp? aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          Timestamp? bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending
        });

        if (exams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد امتحانات في هذا التصنيف',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DataTable(
                headingRowHeight: 50,
                dataRowHeight: 65,
                horizontalMargin: 16,
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(
                  Color(0xFF4F6F52).withOpacity(0.1),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'الطالب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'النوع',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'التاريخ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الحالة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'النتيجة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الإجراء',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ),
                ],
                rows: exams.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return _buildExamRow(doc.id, data);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildExamRow(String examId, Map<String, dynamic> data) {
    String studentName = data['studentName'] ?? 'غير معروف';
    String type = data['type'] ?? '';
    String typeDisplay = type == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
    
    Timestamp? examDateTs = data['examDate'];
    String dateDisplay = examDateTs != null
        ? '${examDateTs.toDate().day}/${examDateTs.toDate().month}/${examDateTs.toDate().year}'
        : 'غير محدد';
    
    String status = data['status'] ?? 'pending';
    int? grade = data['grade'];

    Color statusColor;
    String statusText;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = type == '10ahzab' ? 'في انتظار التعيين' : 'قيد الانتظار';
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusText = 'تمت الموافقة';
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'مكتمل';
        break;
      case 'graded':
        statusColor = Colors.green;
        statusText = 'تم التقييم';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return DataRow(
      cells: [
        // Nom étudiant
        DataCell(
          Container(
            constraints: BoxConstraints(maxWidth: 150),
            child: Text(
              studentName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        
        // Type
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: type == '10ahzab' ? Colors.purple[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              typeDisplay,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: type == '10ahzab' ? Colors.purple[700] : Colors.blue[700],
              ),
            ),
          ),
        ),
        
        // Date
        DataCell(Text(dateDisplay, style: TextStyle(fontSize: 13))),
        
        // Statut
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
        
        // Note
        DataCell(
          grade != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$grade/20',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: grade >= 15 ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      grade >= 15 ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: grade >= 15 ? Colors.green : Colors.red,
                    ),
                  ],
                )
              : Text('-', style: TextStyle(color: Colors.grey)),
        ),
        
        // Action
        DataCell(
          status == 'graded'
              ? IconButton(
                  icon: Icon(Icons.visibility, color: Color(0xFF4F6F52)),
                  onPressed: () {
                    _viewExamDetails(examId, data);
                  },
                  tooltip: 'عرض التفاصيل',
                )
              : type == '10ahzab' && status == 'pending'
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'انتظار',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamGradingPage(
                              examId: examId,
                              examData: data,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F6F52),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'تقييم',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
        ),
      ],
    );
  }

  void _viewExamDetails(String examId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamGradingPage(
          examId: examId,
          examData: data,
        ),
      ),
    );
  }
}