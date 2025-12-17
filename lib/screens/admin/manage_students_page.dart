// lib/screens/admin/manage_students_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/activity_service.dart';
import '../../models/user_model.dart';
import '../view_followup_page.dart'; 

class ManageStudentsPage extends StatefulWidget {
  @override
  _ManageStudentsPageState createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
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
          title: Text('إدارة الطلاب'),
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
                  hintText: 'ابحث عن طالب بالاسم أو البريد الإلكتروني...',
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

            // Tableau des étudiants
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'etudiant')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا يوجد طلاب حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'انقر على "إضافة طالب" لإضافة طالب جديد',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  List<UserModel> students = snapshot.data!.docs
                      .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                      .where((student) {
                        if (_searchQuery.isEmpty) return true;
                        return student.fullName.toLowerCase().contains(_searchQuery) ||
                            student.email.toLowerCase().contains(_searchQuery) ||
                            student.phone.contains(_searchQuery);
                      })
                      .toList();

                  if (students.isEmpty) {
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

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Color(0xFF4F6F52).withOpacity(0.1),
                          ),
                          columns: [
                            DataColumn(
                              label: Text('الرقم', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('الاسم الكامل', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('العمر', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('المجموعة', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('الحفظ السابق', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('الحفظ الجديد', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                            DataColumn(
                              label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F6F52))),
                            ),
                          ],
                          rows: List.generate(students.length, (index) {
                            final student = students[index];
                            int oldHafd = student.oldHafd ?? 0;
                            int newHafd = student.newHafd ?? 0;
                            int totalHafd = oldHafd + newHafd;
                            
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (index.isEven) {
                                    return Color(0xFF4F6F52).withOpacity(0.03);
                                  }
                                  return null;
                                },
                              ),
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewFollowupPage(
                                            studentId: student.id,
                                            studentName: student.fullName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          student.fullName, 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4F6F52),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.event_note, size: 16, color: Color(0xFF4F6F52)),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(student.email, style: TextStyle(color: Colors.grey[700]))),
                                DataCell(Text(student.phone)),
                                DataCell(Text(student.age?.toString() ?? '-')),
                                DataCell(
                                  FutureBuilder<String>(
                                    future: _getGroupName(student.groupId),
                                    builder: (context, snapshot) {
                                      String groupName = snapshot.data ?? 'بدون مجموعة';
                                      bool hasGroup = student.groupId != null && student.groupId!.isNotEmpty;
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: hasGroup
                                              ? Color(0xFF4F6F52).withOpacity(0.2)
                                              : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          groupName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: hasGroup ? Color(0xFF4F6F52) : Colors.orange[800],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$oldHafd حزب',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$newHafd حزب',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$totalHafd/60',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.event_note, size: 20),
                                        color: Colors.blue,
                                        tooltip: 'فيشات المتابعة',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ViewFollowupPage(
                                                studentId: student.id,
                                                studentName: student.fullName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 20),
                                        color: Color(0xFF4F6F52),
                                        tooltip: 'تعديل',
                                        onPressed: () => _showEditStudentDialog(student),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20),
                                        color: Colors.red,
                                        tooltip: 'حذف',
                                        onPressed: () => _handleDeleteStudent(student),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddStudentDialog(),
          backgroundColor: Color(0xFF4F6F52),
          icon: Icon(Icons.add),
          label: Text('إضافة طالب'),
        ),
      ),
    );
  }

  Future<String> _getGroupName(String? groupId) async {
    if (groupId == null || groupId.isEmpty) return 'بدون مجموعة';
    
    try {
      DocumentSnapshot doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['name'] ?? 'بدون مجموعة';
      }
    } catch (e) {
      print('Error getting group name: $e');
    }
    return 'بدون مجموعة';
  }

  void _showAddStudentDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _ageController = TextEditingController();
    final _cityController = TextEditingController();
    final _oldHafdController = TextEditingController(text: '0');
    String? selectedGroupId;

    QuerySnapshot groupsSnapshot = await _firestore.collection('groups').get();
    List<Map<String, dynamic>> groups = groupsSnapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('إضافة طالب جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'اللقب *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال اللقب' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                      if (!value.contains('@')) return 'البريد الإلكتروني غير صالح';
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'العمر *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال العمر' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'المدينة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال المدينة' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _oldHafdController,
                    decoration: InputDecoration(
                      labelText: 'الحفظ السابق (قبل إرتقي) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                      hintText: '0-60 أحزاب',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'الرجاء إدخال الحفظ السابق';
                      int? val = int.tryParse(value);
                      if (val == null || val < 0 || val > 60) {
                        return 'يجب أن يكون بين 0 و 60';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: InputDecoration(
                      labelText: 'المجموعة (اختياري)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('بدون مجموعة', style: TextStyle(color: Colors.grey)),
                      ),
                      ...groups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group['id'],
                          child: Text(group['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedGroupId = value;
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ملاحظات:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• كلمة المرور الافتراضية: eleve123',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                        Text(
                          '• الحفظ الجديد يبدأ من 0',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                        Text(
                          '• يمكن إضافة الطالب للمجموعة لاحقاً',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                      ],
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
                  Navigator.pop(ctx);
                  await _addStudent(
                    _firstNameController.text.trim(),
                    _lastNameController.text.trim(),
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                    int.parse(_ageController.text.trim()),
                    _cityController.text.trim(),
                    int.parse(_oldHafdController.text.trim()),
                    selectedGroupId,
                  );
                }
              },
              child: Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent(
    String firstName,
    String lastName,
    String email,
    String phone,
    int age,
    String city,
    int oldHafd,
    String? groupId,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: CircularProgressIndicator()),
      );

      final result = await _authService.register(
        email: email,
        password: 'eleve123',
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: 'etudiant',
        age: age,
        oldHafd: oldHafd,
        newHafd: 0,
        groupId: groupId,
        city: city,
      );

      // ✅ AJOUT : Mettre à jour le groupe
      if (result['success'] && groupId != null && groupId.isNotEmpty) {
        String studentId = result['user'].uid;
        
        await _firestore.collection('groups').doc(groupId).update({
          'studentIds': FieldValue.arrayUnion([studentId])
        });
        
        print('✅ Étudiant $studentId ajouté au groupe $groupId');
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success']) {
        await ActivityService().logStudentAdded(
          result['user'].uid,
          '$firstName $lastName',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إضافة الطالب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur _addStudent: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditStudentDialog(UserModel student) async {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController(text: student.firstName);
    final _lastNameController = TextEditingController(text: student.lastName);
    final _phoneController = TextEditingController(text: student.phone);
    final _ageController = TextEditingController(text: student.age?.toString() ?? '');
    final _cityController = TextEditingController(text: student.city ?? '');
    final _oldHafdController = TextEditingController(text: student.oldHafd?.toString() ?? '0');
    String? selectedGroupId = student.groupId;

    QuerySnapshot groupsSnapshot = await _firestore.collection('groups').get();
    List<Map<String, dynamic>> groups = groupsSnapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('تعديل بيانات الطالب'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'اللقب',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال اللقب' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'العمر',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال العمر' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'المدينة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _oldHafdController,
                    decoration: InputDecoration(
                      labelText: 'الحفظ السابق',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                      hintText: '0-60 أحزاب',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'الرجاء إدخال الحفظ السابق';
                      int? val = int.tryParse(value);
                      if (val == null || val < 0 || val > 60) {
                        return 'يجب أن يكون بين 0 و 60';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: InputDecoration(
                      labelText: 'المجموعة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('بدون مجموعة', style: TextStyle(color: Colors.grey)),
                      ),
                      ...groups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group['id'],
                          child: Text(group['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedGroupId = value;
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'البريد الإلكتروني: ${student.email}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                        Text(
                          'الحفظ الجديد: ${student.newHafd ?? 0} حزب (تلقائي)',
                          style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '(لا يمكن تعديل البريد أو الحفظ الجديد)',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
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
                  Navigator.pop(ctx);
                  await _updateStudent(
                    student.id,
                    _firstNameController.text.trim(),
                    _lastNameController.text.trim(),
                    _phoneController.text.trim(),
                    int.parse(_ageController.text.trim()),
                    _cityController.text.trim(),
                    int.parse(_oldHafdController.text.trim()),
                    student.newHafd ?? 0,
                    selectedGroupId,
                  );
                }
              },
              child: Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStudent(
    String studentId,
    String firstName,
    String lastName,
    String phone,
    int age,
    String city,
    int oldHafd,
    int newHafd,
    String? newGroupId,
  ) async {
    try {
      // ✅ AJOUT : Récupérer l'ancien groupe
      DocumentSnapshot studentDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();
      
      String? oldGroupId;
      if (studentDoc.exists) {
        Map<String, dynamic>? data = studentDoc.data() as Map<String, dynamic>?;
        oldGroupId = data?['groupId'];
      }

      int totalHafd = oldHafd + newHafd;
      
      await _firestore.collection('users').doc(studentId).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'age': age,
        'city': city,
        'oldHafd': oldHafd,
        'totalHafd': totalHafd,
        'groupId': newGroupId,
      });

      // ✅ AJOUT : Gérer le changement de groupe
      if (oldGroupId != newGroupId) {
        // Retirer de l'ancien groupe
        if (oldGroupId != null && oldGroupId.isNotEmpty) {
          await _firestore.collection('groups').doc(oldGroupId).update({
            'studentIds': FieldValue.arrayRemove([studentId])
          });
          print('✅ Retiré du groupe $oldGroupId');
        }
        
        // Ajouter au nouveau groupe
        if (newGroupId != null && newGroupId.isNotEmpty) {
          await _firestore.collection('groups').doc(newGroupId).update({
            'studentIds': FieldValue.arrayUnion([studentId])
          });
          print('✅ Ajouté au groupe $newGroupId');
        }
      }

      await ActivityService().logStudentUpdated(
        studentId,
        '$firstName $lastName',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحديث بيانات الطالب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erreur _updateStudent: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteStudent(UserModel student) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف الطالب ${student.fullName}؟'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ملاحظة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• سيفقد الطالب إمكانية الدخول للحساب'),
                  Text('• سيتم الاحتفاظ بسجل المتابعة'),
                ],
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _softDeleteStudent(student.id, student.fullName);
            },
            child: Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _softDeleteStudent(String studentId, String studentName) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _authService.getCurrentUserId(),
      });

      await ActivityService().logStudentDeleted(studentId, studentName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حذف الطالب $studentName بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}