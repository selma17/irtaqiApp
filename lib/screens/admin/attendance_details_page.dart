// lib/screens/admin/attendance_details_page.dart - VERSION ADAPTÉE À LA STRUCTURE ACTUELLE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AttendanceDetailsPage extends StatefulWidget {
  final String attendanceId;
  final String groupName;
  final String profName;
  final String month;

  AttendanceDetailsPage({
    required this.attendanceId,
    required this.groupName,
    required this.profName,
    required this.month,
  });

  @override
  _AttendanceDetailsPageState createState() => _AttendanceDetailsPageState();
}

class _AttendanceDetailsPageState extends State<AttendanceDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> attendanceData = {};
  Map<String, Map<String, dynamic>> studentsData = {};
  List<int> weeks = [0, 1, 2, 3];
  int selectedWeek = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('attendance')
          .doc(widget.attendanceId)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> students = data['students'] ?? {};

      // Charger les données des étudiants
      for (String studentId in students.keys) {
        DocumentSnapshot studentDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();
        if (studentDoc.exists) {
          studentsData[studentId] = studentDoc.data() as Map<String, dynamic>;
        }
      }

      setState(() {
        attendanceData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('تفاصيل فيشة الحضور'),
          backgroundColor: Color(0xFF4F6F52),
          actions: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _exportToExcel,
              tooltip: 'تصدير Excel',
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16),
                    _buildWeekSelector(),
                    SizedBox(height: 16),
                    _buildAttendanceTable(),
                    SizedBox(height: 16),
                    _buildStatistics(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.groupName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatMonth(widget.month),
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.person, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.profName,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.people, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '${studentsData.length}',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'اختر الأسبوع:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: weeks.map((week) {
                bool isSelected = week == selectedWeek;
                return ChoiceChip(
                  label: Text('الأسبوع ${week + 1}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedWeek = week;
                      });
                    }
                  },
                  selectedColor: Color(0xFF4F6F52),
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    Map<String, dynamic> students = attendanceData['students'] ?? {};

    if (students.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'لا توجد بيانات حضور',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    List<String> dayNames = ['اليوم 1', 'اليوم 2'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Color(0xFF4F6F52).withOpacity(0.1)),
          headingRowHeight: 45,
          dataRowHeight: 80,
          columnSpacing: 12,
          horizontalMargin: 12,
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
            ...dayNames.map((dayName) {
              return DataColumn(
                label: Container(
                  width: 220,
                  alignment: Alignment.center,
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
          rows: students.entries.map((studentEntry) {
            String studentId = studentEntry.key;
            Map<String, dynamic> studentAttendance = studentEntry.value as Map<String, dynamic>;
            String studentName = studentsData[studentId]?['firstName'] ?? 'طالب';

            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 100,
                    child: Text(
                      studentName,
                      style: TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ...[0, 1].map((dayIndex) {
                  String tasmi3Key = '${studentId}_w${selectedWeek}_d${dayIndex}_tasmi3';
                  String wajibKey = '${studentId}_w${selectedWeek}_d${dayIndex}_wajib';
                  
                  String tasmi3 = studentAttendance[tasmi3Key] ?? '';
                  String wajib = studentAttendance[wajibKey] ?? '';
                  
                  return DataCell(_buildAttendanceCell(tasmi3, wajib));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAttendanceCell(String tasmi3, String wajib) {
    bool hasTasmi3 = tasmi3.isNotEmpty && tasmi3.trim().isNotEmpty;
    bool hasWajib = wajib.isNotEmpty && wajib.trim().isNotEmpty;
    
    if (!hasTasmi3 && !hasWajib) {
      return Container(
        width: 220,
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text(
            'غياب',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 220,
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          // Tasmi3 à gauche
          if (hasTasmi3)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: hasWajib ? 4 : 0),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, size: 12, color: Colors.green[700]),
                        SizedBox(width: 4),
                        Text(
                          'تسميع',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      tasmi3,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green[900],
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          
          // Wajib à droite
          if (hasWajib)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: hasTasmi3 ? 4 : 0),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, size: 12, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          'واجب',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      wajib,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blue[900],
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    Map<String, dynamic> students = attendanceData['students'] ?? {};
    
    int totalTasmi3 = 0;
    int totalWajib = 0;
    int totalAbsent = 0;

    students.forEach((studentId, data) {
      Map<String, dynamic> studentData = data as Map<String, dynamic>;
      
      for (int day = 0; day < 2; day++) {
        String tasmi3Key = '${studentId}_w${selectedWeek}_d${day}_tasmi3';
        String wajibKey = '${studentId}_w${selectedWeek}_d${day}_wajib';
        
        String tasmi3 = studentData[tasmi3Key] ?? '';
        String wajib = studentData[wajibKey] ?? '';
        
        bool hasTasmi3 = tasmi3.isNotEmpty && tasmi3.trim().isNotEmpty;
        bool hasWajib = wajib.isNotEmpty && wajib.trim().isNotEmpty;
        
        if (hasTasmi3) totalTasmi3++;
        if (hasWajib) totalWajib++;
        if (!hasTasmi3 && !hasWajib) totalAbsent++;
      }
    });

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF4F6F52), size: 18),
              SizedBox(width: 8),
              Text(
                'الإحصائيات - الأسبوع ${selectedWeek + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('تسميع', totalTasmi3, Colors.green),
              _buildStatCard('واجب', totalWajib, Colors.blue),
              _buildStatCard('غياب', totalAbsent, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800]!,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey[900]!,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['المجموعة', widget.groupName]);
      rows.add(['الشهر', widget.month]);
      rows.add(['الأستاذ', widget.profName]);
      rows.add(['الأسبوع', 'الأسبوع ${selectedWeek + 1}']);
      rows.add([]);
      
      // Table header
      rows.add(['الطالب', 'اليوم 1 تسميع', 'اليوم 1 واجب', 'اليوم 2 تسميع', 'اليوم 2 واجب']);
      
      // Data
      Map<String, dynamic> students = attendanceData['students'] ?? {};
      students.forEach((studentId, data) {
        String studentName = studentsData[studentId]?['firstName'] ?? 'طالب';
        Map<String, dynamic> studentData = data as Map<String, dynamic>;
        
        List<dynamic> row = [studentName];
        for (int day = 0; day < 2; day++) {
          String tasmi3Key = '${studentId}_w${selectedWeek}_d${day}_tasmi3';
          String wajibKey = '${studentId}_w${selectedWeek}_d${day}_wajib';
          
          row.add(studentData[tasmi3Key] ?? '');
          row.add(studentData[wajibKey] ?? '');
        }
        rows.add(row);
      });

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);
      
      if (kIsWeb) {
        // Version Web
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'attendance_${widget.month}_week${selectedWeek + 1}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Version Mobile
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/attendance_${widget.month}_week${selectedWeek + 1}.csv';
        final file = File(path);
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(path)],
          text: 'فيش الحضور - ${widget.groupName}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ تم تصدير البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التصدير: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMonth(String month) {
    List<String> monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    try {
      List<String> parts = month.split('-');
      if (parts.length == 2) {
        int monthIndex = int.parse(parts[1]) - 1;
        return '${monthNames[monthIndex]} ${parts[0]}';
      }
    } catch (e) {}
    
    return month;
  }
}