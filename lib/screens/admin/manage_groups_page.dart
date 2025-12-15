// lib/screens/admin/manage_groups_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../services/activity_service.dart';
import '../../models/group_model.dart';
import 'group_details_page.dart';

class ManageGroupsPage extends StatefulWidget {
  @override
  _ManageGroupsPageState createState() => _ManageGroupsPageState();
}

class _ManageGroupsPageState extends State<ManageGroupsPage> {
  final GroupService _groupService = GroupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إدارة المجموعات'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            // Barre de recherche
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن مجموعة...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF4F6F52)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Color(0xFFF6F3EE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
                  ),
                ),
              ),
            ),

            // Liste des groupes
            Expanded(
              child: StreamBuilder<List<GroupModel>>(
                stream: _groupService.getAllGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد مجموعات حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'انقر على "إنشاء مجموعة" لإضافة مجموعة جديدة',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  List<GroupModel> groups = snapshot.data!
                      .where((group) {
                        if (_searchQuery.isEmpty) return true;
                        return group.name.toLowerCase().contains(_searchQuery);
                      })
                      .toList();

                  if (groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا توجد نتائج للبحث', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return _buildGroupCard(groups[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateGroupDialog(),
          backgroundColor: Color(0xFF4F6F52),
          icon: Icon(Icons.add),
          label: Text('إنشاء مجموعة'),
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _getProfName(group.profId),
        _groupService.getGroupStats(group.id),
      ]).then((results) => {
        'profName': results[0],
        'stats': results[1],
      }),
      builder: (context, snapshot) {
        String profName = snapshot.data?['profName'] ?? 'جاري التحميل...';
        Map<String, dynamic> stats = snapshot.data?['stats'] ?? {'averageHafd': 0};

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailsPage(groupId: group.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4F6F52).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.groups, color: Color(0xFF4F6F52), size: 28),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F6F52),
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    profName,
                                    style: TextStyle(color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Divider(height: 24),

                  // Statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.people,
                          'الطلاب',
                          '${group.currentStudentsCount}/${group.maxStudents}',
                          group.isFull ? Colors.red : Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          Icons.book,
                          'متوسط الحفظ',
                          '${stats['averageHafd']} حزب',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  if (group.schedule.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                              SizedBox(width: 6),
                              Text(
                                'أوقات الحصص:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          ...group.schedule.map((slot) => Padding(
                            padding: EdgeInsets.only(top: 4, right: 22),
                            child: Text(
                              slot.toString(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 12),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailsPage(groupId: group.id),
                            ),
                          );
                        },
                        icon: Icon(Icons.visibility, size: 18),
                        label: Text('التفاصيل'),
                        style: TextButton.styleFrom(foregroundColor: Color(0xFF4F6F52)),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showEditGroupDialog(group),
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('تعديل'),
                        style: TextButton.styleFrom(foregroundColor: Color(0xFF4F6F52)),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _handleDeleteGroup(group),
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('حذف'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      print('Error getting prof name: $e');
    }
    return 'غير محدد';
  }

// SUITE DE manage_groups_page.dart (À AJOUTER APRÈS LA PARTIE 1)

  // Créer un groupe
  void _showCreateGroupDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _maxStudentsController = TextEditingController(text: '20');
    String? selectedProfId;
    List<ScheduleSlot> scheduleSlots = [];
    List<String> selectedStudentIds = [];

    // Récupérer les profs disponibles
    QuerySnapshot profsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'prof')
        .where('isActive', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> profs = profsSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': '${doc['firstName']} ${doc['lastName']}'
            })
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('إنشاء مجموعة جديدة'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم المجموعة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال اسم المجموعة' : null,
                  ),
                  SizedBox(height: 12),

                  // Prof
                  DropdownButtonFormField<String>(
                    value: selectedProfId,
                    decoration: InputDecoration(
                      labelText: 'الأستاذ المشرف *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: profs.map((prof) {
                      return DropdownMenuItem<String>(
                        value: prof['id'],
                        child: Text(prof['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedProfId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'الرجاء اختيار الأستاذ' : null,
                  ),
                  SizedBox(height: 12),

                  // Max students
                  TextFormField(
                    controller: _maxStudentsController,
                    decoration: InputDecoration(
                      labelText: 'الحد الأقصى للطلاب *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'الرجاء إدخال الحد الأقصى';
                      int? val = int.tryParse(value);
                      if (val == null || val < 1) return 'يجب أن يكون أكبر من 0';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Schedule
                  Text(
                    'أوقات الحصص:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddScheduleDialog(scheduleSlots, setStateDialog);
                    },
                    icon: Icon(Icons.add),
                    label: Text('إضافة حصة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F6F52),
                    ),
                  ),
                  SizedBox(height: 8),
                  ...scheduleSlots.map((slot) => ListTile(
                        dense: true,
                        leading: Icon(Icons.schedule, size: 20),
                        title: Text(slot.toString(), style: TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () {
                            setStateDialog(() {
                              scheduleSlots.remove(slot);
                            });
                          },
                        ),
                      )),
                  if (scheduleSlots.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'لم يتم إضافة أي حصص',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Students
                  Text(
                    'اختر الطلاب:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      List<String>? selected = await _showStudentsSelectionDialog(
                        selectedStudentIds,
                      );
                      if (selected != null) {
                        setStateDialog(() {
                          selectedStudentIds = selected;
                        });
                      }
                    },
                    icon: Icon(Icons.person_add),
                    label: Text('اختيار الطلاب (${selectedStudentIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F6F52),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (scheduleSlots.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('يجب إضافة حصة واحدة على الأقل')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  await _createGroup(
                    _nameController.text.trim(),
                    selectedProfId!,
                    scheduleSlots,
                    selectedStudentIds,
                    int.parse(_maxStudentsController.text.trim()),
                  );
                }
              },
              child: Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(
    List<ScheduleSlot> scheduleSlots,
    StateSetter setStateDialog,
  ) {
    String? selectedDay;
    final startTimeController = TextEditingController(text: '08:00');
    final endTimeController = TextEditingController(text: '10:00');

    final days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة حصة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: InputDecoration(
                labelText: 'اليوم',
                border: OutlineInputBorder(),
              ),
              items: days.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                selectedDay = value;
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: startTimeController,
              decoration: InputDecoration(
                labelText: 'من الساعة (HH:MM)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: endTimeController,
              decoration: InputDecoration(
                labelText: 'إلى الساعة (HH:MM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
            onPressed: () {
              if (selectedDay != null) {
                setStateDialog(() {
                  scheduleSlots.add(ScheduleSlot(
                    day: selectedDay!,
                    startTime: startTimeController.text.trim(),
                    endTime: endTimeController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _showStudentsSelectionDialog(
    List<String> currentSelection,
  ) async {
    List<String> selectedIds = List.from(currentSelection);
    List<Map<String, dynamic>> students =
        await _groupService.getStudentsWithoutGroup();

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('اختر الطلاب (بدون مجموعة)'),
          content: Container(
            width: double.maxFinite,
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'جميع الطلاب لديهم مجموعات',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isSelected = selectedIds.contains(student['id']);

                      return CheckboxListTile(
                        value: isSelected,
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
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F6F52)),
              onPressed: () => Navigator.pop(ctx, selectedIds),
              child: Text('تأكيد (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup(
    String name,
    String profId,
    List<ScheduleSlot> schedule,
    List<String> studentIds,
    int maxStudents,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: CircularProgressIndicator()),
      );

      String? groupId = await _groupService.createGroup(
        name: name,
        profId: profId,
        schedule: schedule,
        studentIds: studentIds,
        maxStudents: maxStudents,
      );

      Navigator.pop(context);

      if (groupId != null) {
        await ActivityService().logGroupCreated(groupId, name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إنشاء المجموعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ أثناء الإنشاء'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Modifier un groupe
  void _showEditGroupDialog(GroupModel group) {
    // TODO: Implémenter la modification (similaire à la création)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modification disponible dans la page de détails')),
    );
  }

  // Supprimer un groupe
  Future<void> _handleDeleteGroup(GroupModel group) async {
    if (group.studentIds.isNotEmpty) {
      // Le groupe a des étudiants, on doit les transférer
      _showTransferStudentsDialog(group);
    } else {
      // Le groupe est vide, on peut supprimer directement
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف المجموعة ${group.name}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                bool success = await _groupService.deleteGroup(group.id);
                if (success) {
                  await ActivityService().logGroupDeleted(group.id, group.name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم حذف المجموعة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('تأكيد الحذف'),
            ),
          ],
        ),
      );
    }
  }

  void _showTransferStudentsDialog(GroupModel fromGroup) async {
    // Récupérer les autres groupes
    QuerySnapshot snapshot = await _firestore.collection('groups').get();
    List<GroupModel> targetGroups = snapshot.docs
        .map((doc) => GroupModel.fromDoc(doc))
        .where((g) => g.id != fromGroup.id)
        .toList();

    if (!mounted) return;

    if (targetGroups.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text('تنبيه'),
            ],
          ),
          content: Text(
            'لا يمكن حذف المجموعة لأنه لا توجد مجموعات أخرى لنقل الطلاب إليها.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    String? selectedGroupId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('نقل الطلاب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المجموعة ${fromGroup.name} تحتوي على ${fromGroup.currentStudentsCount} طالب'),
              SizedBox(height: 12),
              Text('يجب نقلهم إلى مجموعة أخرى:'),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'المجموعة الهدف',
                  border: OutlineInputBorder(),
                ),
                items: targetGroups.map((group) {
                  bool hasSpace = group.availableSpots >= fromGroup.currentStudentsCount;
                  return DropdownMenuItem<String>(
                    value: group.id,
                    enabled: hasSpace,
                    child: Text(
                      '${group.name} (${group.currentStudentsCount}/${group.maxStudents}) ${!hasSpace ? "❌ ممتلئة" : "✅"}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    selectedGroupId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedGroupId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => Center(child: CircularProgressIndicator()),
                      );

                      bool transferred = await _groupService.transferStudents(
                        fromGroup.id,
                        selectedGroupId!,
                      );

                      if (transferred) {
                        bool deleted = await _groupService.deleteGroup(fromGroup.id);
                        Navigator.pop(context);

                        if (deleted) {
                          await ActivityService().logGroupDeleted(
                            fromGroup.id,
                            fromGroup.name,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ تم نقل الطلاب وحذف المجموعة بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ حدث خطأ أثناء النقل'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text('نقل وحذف'),
            ),
          ],
        ),
      ),
    );
  }
}