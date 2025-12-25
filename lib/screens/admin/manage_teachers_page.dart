// lib/screens/admin/manage_teachers_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../services/activity_service.dart';
import '../../utils/validators.dart';

class ManageTeachersPage extends StatefulWidget {
  @override
  _ManageTeachersPageState createState() => _ManageTeachersPageState();
}

class _ManageTeachersPageState extends State<ManageTeachersPage> {
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
          title: Text('إدارة الأساتذة'),
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
                  hintText: 'ابحث عن أستاذ بالاسم أو البريد الإلكتروني...',
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

            // Tableau des enseignants
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'prof')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدث خطأ: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا يوجد أساتذة حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'انقر على "إضافة أستاذ" لإضافة أستاذ جديد',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filtrer les enseignants selon la recherche
                  List<UserModel> teachers = snapshot.data!.docs
                      .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                      .where((teacher) {
                        if (_searchQuery.isEmpty) return true;
                        return teacher.fullName.toLowerCase().contains(_searchQuery) ||
                            teacher.email.toLowerCase().contains(_searchQuery) ||
                            teacher.phone.contains(_searchQuery);
                      })
                      .toList();

                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج للبحث',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'جرب كلمات بحث مختلفة',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
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
                              label: Text(
                                'الرقم',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'الاسم الكامل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'البريد الإلكتروني',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'الهاتف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'المدينة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'المجموعات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'الإجراءات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F6F52),
                                ),
                              ),
                            ),
                          ],
                          rows: List.generate(teachers.length, (index) {
                            final teacher = teachers[index];
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
                                  Text(
                                    teacher.fullName,
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    teacher.email,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                                DataCell(Text(teacher.phone)),
                                DataCell(
                                  Text(teacher.city ?? 'غير محدد'),
                                ),
                                DataCell(
                                  FutureBuilder<int>(
                                    future: _getTeacherGroupsCount(teacher.id),
                                    builder: (context, snapshot) {
                                      int count = snapshot.data ?? 0;
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: count > 0
                                              ? Color(0xFF4F6F52).withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          count.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: count > 0
                                                ? Color(0xFF4F6F52)
                                                : Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 20),
                                        color: Color(0xFF4F6F52),
                                        tooltip: 'تعديل',
                                        onPressed: () => _showEditTeacherDialog(teacher),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20),
                                        color: Colors.red,
                                        tooltip: 'حذف',
                                        onPressed: () => _handleDeleteTeacher(teacher),
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
          onPressed: () => _showAddTeacherDialog(),
          backgroundColor: Color(0xFF4F6F52),
          icon: Icon(Icons.add),
          label: Text('إضافة أستاذ'),
        ),
      ),
    );
  }

  Future<int> _getTeacherGroupsCount(String teacherId) async {
    QuerySnapshot groups = await _firestore
        .collection('groups')
        .where('profId', isEqualTo: teacherId)
        .get();
    return groups.docs.length;
  }

  // Ajouter un enseignant
  void _showAddTeacherDialog() {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _cityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة أستاذ جديد'),
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
                  validator: (value) => Validators.validateName(value, 'الاسم'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'اللقب *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => Validators.validateName(value, 'اللقب'),
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
                  validator: Validators.validateEmail,
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
                  validator: Validators.validatePhone,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'المدينة *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) => Validators.validateName(value, 'المدينة'),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'كلمة المرور الافتراضية: prof123',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4F6F52),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await _addTeacher(
                  _firstNameController.text.trim(),
                  _lastNameController.text.trim(),
                  _emailController.text.trim(),
                  _phoneController.text.trim(),
                  _cityController.text.trim(),
                );
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTeacher(
    String firstName,
    String lastName,
    String email,
    String phone,
    String city,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: CircularProgressIndicator()),
      );

      final result = await _authService.register(
        email: email,
        password: 'prof123',
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: 'prof',
        city: city,
      );

      Navigator.pop(context);

      if (result['success']) {
        // Enregistrer l'activité
        await ActivityService().logTeacherAdded(
          result['user'].uid,
          '$firstName $lastName',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إضافة الأستاذ بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
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

  // Modifier un enseignant
  void _showEditTeacherDialog(UserModel teacher) {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController(text: teacher.firstName);
    final _lastNameController = TextEditingController(text: teacher.lastName);
    final _phoneController = TextEditingController(text: teacher.phone);
    final _cityController = TextEditingController(text: teacher.city ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل بيانات الأستاذ'),
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
                  validator: (value) => Validators.validateName(value, 'الاسم'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'اللقب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => Validators.validateName(value, 'اللقب'),
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
                  validator: Validators.validatePhone,
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
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'البريد الإلكتروني: ${teacher.email}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      Text(
                        '(لا يمكن تعديل البريد الإلكتروني)',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4F6F52),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await _updateTeacher(
                  teacher.id,
                  _firstNameController.text.trim(),
                  _lastNameController.text.trim(),
                  _phoneController.text.trim(),
                  _cityController.text.trim(),
                );
              }
            },
            child: Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacher(
    String teacherId,
    String firstName,
    String lastName,
    String phone,
    String city,
  ) async {
    try {
      await _firestore.collection('users').doc(teacherId).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'city': city,
      });

      // Enregistrer l'activité
      await ActivityService().logTeacherUpdated(
        teacherId,
        '$firstName $lastName',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحديث بيانات الأستاذ بنجاح'),
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

  // Supprimer un enseignant
  Future<void> _handleDeleteTeacher(UserModel teacher) async {
    int groupsCount = await _getTeacherGroupsCount(teacher.id);

    if (groupsCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('تنبيه'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لا يمكن حذف الأستاذ ${teacher.fullName}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('السبب: الأستاذ لديه $groupsCount مجموعة نشطة'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'يجب إعادة تعيين جميع مجموعاته لأساتذة آخرين أولاً',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F6F52),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('انتقل إلى صفحة المجموعات لإعادة التعيين'),
                  ),
                );
              },
              child: Text('إدارة المجموعات'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من حذف الأستاذ ${teacher.fullName}؟'),
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
                    Text('• سيفقد الأستاذ إمكانية الدخول للحساب'),
                    Text('• سيتم الاحتفاظ بسجل المتابعة للطلاب'),
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
                await _softDeleteTeacher(teacher.id, teacher.fullName);
              },
              child: Text('تأكيد الحذف'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _softDeleteTeacher(String teacherId, String teacherName) async {
    try {
      await _firestore.collection('users').doc(teacherId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _authService.getCurrentUserId(),
      });

      // Enregistrer l'activité
      await ActivityService().logTeacherDeleted(teacherId, teacherName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حذف الأستاذ $teacherName بنجاح'),
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