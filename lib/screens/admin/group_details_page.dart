// lib/screens/admin/group_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  const GroupDetailsPage({required this.groupId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final GroupService _groupService = GroupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('تفاصيل المجموعة'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: FutureBuilder<GroupModel?>(
          future: _groupService.getGroupById(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('المجموعة غير موجودة', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }

            GroupModel group = snapshot.data!;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom du groupe
                  _buildHeader(group),
                  SizedBox(height: 20),

                  // Statistiques
                  _buildStatsSection(group),
                  SizedBox(height: 20),

                  // Info prof et horaires
                  _buildInfoSection(group),
                  SizedBox(height: 20),

                  // Liste des étudiants
                  _buildStudentsSection(group),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(GroupModel group) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.groups, color: Colors.white, size: 40),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تم الإنشاء: ${group.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(GroupModel group) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _groupService.getGroupStats(widget.groupId),
      builder: (context, snapshot) {
        Map<String, dynamic> stats = snapshot.data ?? {'averageHafd': 0};

        return Container(
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
              Text(
                '📊 الإحصائيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${group.currentStudentsCount}',
                      'عدد الطلاب',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${stats['averageHafd']}',
                      'متوسط الحفظ',
                      Icons.book,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${group.availableSpots}',
                      'أماكن متاحة',
                      Icons.event_seat,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${group.fillPercentage.toInt()}%',
                      'نسبة الامتلاء',
                      Icons.pie_chart,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(GroupModel group) {
    return Container(
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
          Text(
            'ℹ️ معلومات المجموعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),

          // Prof
          FutureBuilder<String>(
            future: _getProfName(group.profId),
            builder: (context, snapshot) {
              return _buildInfoRow(
                Icons.person,
                'الأستاذ المشرف',
                snapshot.data ?? 'جاري التحميل...',
              );
            },
          ),

          Divider(height: 24),

          // Horaires
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule, color: Color(0xFF4F6F52), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أوقات الحصص:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 6),
                    ...group.schedule.map((slot) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF4F6F52).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              slot.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F6F52),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 24),

          // Capacité
          _buildInfoRow(
            Icons.groups,
            'الحد الأقصى',
            '${group.maxStudents} طالب',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF4F6F52), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection(GroupModel group) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👥 قائمة الطلاب (${group.currentStudentsCount})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
              if (!group.isFull)
                IconButton(
                  icon: Icon(Icons.person_add, color: Color(0xFF4F6F52)),
                  onPressed: () => _showAddStudentsDialog(group),
                  tooltip: 'إضافة طلاب',
                ),
            ],
          ),
          SizedBox(height: 16),

          if (group.studentIds.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'لا يوجد طلاب في المجموعة',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    if (!group.isFull)
                      ElevatedButton.icon(
                        onPressed: () => _showAddStudentsDialog(group),
                        icon: Icon(Icons.add),
                        label: Text('إضافة طلاب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4F6F52),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            FutureBuilder<List<UserModel>>(
              future: _getStudents(group.studentIds),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<UserModel> students = snapshot.data!;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  separatorBuilder: (context, index) => Divider(height: 16),
                  itemBuilder: (context, index) {
                    UserModel student = students[index];
                    return _buildStudentItem(student, group);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(UserModel student, GroupModel group) {
    int totalHafd = (student.oldHafd ?? 0) + (student.newHafd ?? 0);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Color(0xFF4F6F52),
        child: Text(
          student.firstName[0],
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        student.fullName,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'العمر: ${student.age ?? '-'} | الحفظ: $totalHafd حزب',
        style: TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle, color: Colors.red, size: 20),
        onPressed: () => _confirmRemoveStudent(student, group),
        tooltip: 'إزالة من المجموعة',
      ),
    );
  }

  void _showAddStudentsDialog(GroupModel group) async {
    List<Map<String, dynamic>> availableStudents =
        await _groupService.getStudentsWithoutGroup();

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جميع الطلاب لديهم مجموعات')),
      );
      return;
    }

    List<String> selectedIds = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('إضافة طلاب للمجموعة'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableStudents.length,
              itemBuilder: (context, index) {
                final student = availableStudents[index];
                final isSelected = selectedIds.contains(student['id']);

                // Vérifier la capacité
                bool canAdd = group.availableSpots > selectedIds.length;

                return CheckboxListTile(
                  value: isSelected,
                  enabled: isSelected || canAdd,
                  onChanged: (bool? value) {
                    setStateDialog(() {
                      if (value == true) {
                        selectedIds.add(student['id']);
                      } else {
                        selectedIds.remove(student['id']);
                      }
                    });
                  },
                  title: Text(
                    '${student['firstName']} ${student['lastName']}',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'العمر: ${student['age']} | الحفظ: ${student['totalHafd']} حزب',
                    style: TextStyle(fontSize: 12),
                  ),
                  activeColor: Color(0xFF4F6F52),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
              onPressed: selectedIds.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      bool success = await _groupService.addStudentsToGroup(
                        group.id,
                        selectedIds,
                      );

                      if (success) {
                        setState(() {}); // Rafraîchir
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم إضافة ${selectedIds.length} طالب'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: Text('إضافة (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveStudent(UserModel student, GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الإزالة'),
        content: Text('هل تريد إزالة ${student.fullName} من المجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _groupService.removeStudentFromGroup(
                group.id,
                student.id,
              );

              if (success) {
                setState(() {}); // Rafraîchir
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم إزالة الطالب من المجموعة'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('إزالة'),
          ),
        ],
      ),
    );
  }

  Future<String> _getProfName(String profId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(profId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (e) {
      print('Error: $e');
    }
    return 'غير محدد';
  }

  Future<List<UserModel>> _getStudents(List<String> studentIds) async {
    List<UserModel> students = [];
    for (String id in studentIds) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists) {
          students.add(UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>));
        }
      } catch (e) {
        print('Error loading student $id: $e');
      }
    }
    return students;
  }
}