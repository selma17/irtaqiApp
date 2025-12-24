// lib/screens/admin/admin_exams_dashboard.dart
// ✅ Dashboard admin - Tous les examens + Assignation prof pour 10 ahzab

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminExamsDashboard extends StatefulWidget {
  @override
  _AdminExamsDashboardState createState() => _AdminExamsDashboardState();
}

class _AdminExamsDashboardState extends State<AdminExamsDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إدارة الامتحانات'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            SizedBox(height: 16),
            _buildHeader(),
            SizedBox(height: 16),
            _buildStats(),
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
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
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
                  'عرض جميع الامتحانات وتعيين الأساتذة',
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

  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('exams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        int total = snapshot.data!.docs.length;
        int pending10ahzab = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['type'] == '10ahzab' && data['status'] == 'pending';
        }).length;
        int graded = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'graded';
        }).length;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard('الإجمالي', total, Colors.blue),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('10 أحزاب قيد الانتظار', pending10ahzab, Colors.orange),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('تم التقييم', graded, Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('الكل', 'all'),
            SizedBox(width: 8),
            _buildFilterChip('قيد الانتظار', 'pending'),
            SizedBox(width: 8),
            _buildFilterChip('10 أحزاب - يحتاج تعيين', '10ahzab_pending'),
            SizedBox(width: 8),
            _buildFilterChip('تم التقييم', 'graded'),
          ],
        ),
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
          selectedFilter = selected ? value : 'all';
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
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exams')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('لا توجد امتحانات', style: TextStyle(fontSize: 18, color: Colors.grey)),
          );
        }

        // Filtrer
        List<DocumentSnapshot> exams = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          
          if (selectedFilter == 'all') return true;
          if (selectedFilter == 'pending') return data['status'] == 'pending';
          if (selectedFilter == '10ahzab_pending') {
            return data['type'] == '10ahzab' && data['status'] == 'pending';
          }
          if (selectedFilter == 'graded') return data['status'] == 'graded';
          
          return true;
        }).toList();

        // ✅ Trier par createdAt côté client
        exams.sort((a, b) {
          Timestamp? aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          Timestamp? bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
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
              ),
              child: DataTable(
                headingRowHeight: 50,
                dataRowHeight: 70,
                horizontalMargin: 16,
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(
                  Color(0xFF4F6F52).withOpacity(0.1),
                ),
                columns: [
                  DataColumn(label: Text('الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الأستاذ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('النتيجة', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الإجراء', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: exams.map((doc) {
                  return _buildExamRow(doc.id, doc.data() as Map<String, dynamic>);
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
    String profName = data['createdByProfName'] ?? 'غير معروف';
    String type = data['type'] ?? '';
    String status = data['status'] ?? '';
    int? grade = data['grade'];
    bool needsAssignment = type == '10ahzab' && status == 'pending';

    // ✅ AJOUTÉ : Date
    Timestamp? examDateTs = data['examDate'];
    String dateDisplay = examDateTs != null
        ? '${examDateTs.toDate().day}/${examDateTs.toDate().month}/${examDateTs.toDate().year}'
        : 'غير محدد';

    return DataRow(
      color: MaterialStateProperty.all(
        needsAssignment ? Colors.orange[50] : null,
      ),
      cells: [
        DataCell(Text(studentName, style: TextStyle(fontSize: 13))),
        DataCell(Text(profName, style: TextStyle(fontSize: 13))),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: type == '10ahzab' ? Colors.purple[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type == '10ahzab' ? '10 أحزاب' : '5 أحزاب',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: type == '10ahzab' ? Colors.purple[700] : Colors.blue[700],
              ),
            ),
          ),
        ),
        // ✅ AJOUTÉ : Cellule date
        DataCell(Text(dateDisplay, style: TextStyle(fontSize: 13))),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: needsAssignment ? Colors.orange[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              needsAssignment ? 'يحتاج تعيين' : _getStatusText(status),
              style: TextStyle(
                fontSize: 11,
                color: needsAssignment ? Colors.orange[700] : Colors.grey[700],
              ),
            ),
          ),
        ),
        DataCell(
          grade != null
              ? Text(
                  '$grade/20',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: grade >= 15 ? Colors.green : Colors.red,
                  ),
                )
              : Text('-', style: TextStyle(color: Colors.grey)),
        ),
        DataCell(
          needsAssignment
              ? ElevatedButton(
                  onPressed: () => _showAssignProfDialog(examId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تعيين أستاذ',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                )
              : Text('-', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'approved': return 'تمت الموافقة';
      case 'graded': return 'تم التقييم';
      default: return status;
    }
  }

  Future<void> _showAssignProfDialog(String examId, Map<String, dynamic> examData) async {
    // Récupérer tous les profs
    QuerySnapshot profsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'prof')
        .get();

    List<Map<String, dynamic>> profs = profsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': '${data['firstName']} ${data['lastName']}',
      };
    }).toList();

    String? selectedProfId;
    DateTime selectedDate = DateTime.now().add(Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعيين أستاذ للامتحان'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الطالب: ${examData['studentName']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('اختر الأستاذ:'),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedProfId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: profs.map((prof) {
                      return DropdownMenuItem<String>(
                        value: prof['id'],
                        child: Text(prof['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProfId = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('تاريخ الامتحان:'),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedProfId == null
                    ? null
                    : () => _assignProf(examId, selectedProfId!, selectedDate, profs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F6F52),
                ),
                child: Text('تعيين', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignProf(
    String examId,
    String profId,
    DateTime examDate,
    List<Map<String, dynamic>> profs,
  ) async {
    try {
      var prof = profs.firstWhere((p) => p['id'] == profId);

      await _firestore.collection('exams').doc(examId).update({
        'assignedProfId': profId,
        'assignedProfName': prof['name'],
        'examDate': Timestamp.fromDate(examDate),
        'status': 'approved',
      });

      // Notification pour le prof assigné
      await _firestore.collection('notifications').add({
        'userId': profId,
        'title': 'تم تعيينك لامتحان',
        'message': 'تم تعيينك لإجراء امتحان 10 أحزاب',
        'type': 'exam_assigned',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تعيين الأستاذ بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}