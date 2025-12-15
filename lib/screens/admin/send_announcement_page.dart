// lib/screens/admin/send_announcement_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/announcement_service.dart';

class SendAnnouncementPage extends StatefulWidget {
  @override
  _SendAnnouncementPageState createState() => _SendAnnouncementPageState();
}

class _SendAnnouncementPageState extends State<SendAnnouncementPage> {
  final AnnouncementService _announcementService = AnnouncementService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _targetAudience = 'all';
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  
  // ✅ NOUVEAU : Pour gérer l'image
  File? _selectedImage;
  //String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    QuerySnapshot snapshot = await _firestore.collection('groups').get();
    setState(() {
      _groups = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
              })
          .toList();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ✅ NOUVEAU : Sélectionner une image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ NOUVEAU : Upload image vers Firebase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      String fileName = 'announcements/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _sendAnnouncement() async {
    // ✅ VALIDATION AMÉLIORÉE
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ العنوان مطلوب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Si pas d'image, le contenu est obligatoire
    if (_selectedImage == null && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ يجب إدخال محتوى أو إضافة صورة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation du groupe spécifique
    if (_targetAudience == 'specific_group' && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ الرجاء اختيار مجموعة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Upload de l'image si présente
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل رفع الصورة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    bool success = await _announcementService.createAnnouncement(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      targetAudience: _targetAudience,
      targetGroupId: _targetAudience == 'specific_group' ? _selectedGroupId : null,
      imageUrl: imageUrl,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم إرسال الإعلان بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _targetAudience = 'all';
        _selectedGroupId = null;
        _selectedImage = null;
        //_uploadedImageUrl = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء الإرسال'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إرسال إعلان'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
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
                      Icon(Icons.campaign, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إعلان جديد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'أرسل إعلانًا للمستخدمين',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Form
                Container(
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
                      // Titre (OBLIGATOIRE)
                      Text(
                        'العنوان *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'أدخل عنوان الإعلان',
                          prefixIcon: Icon(Icons.title, color: Color(0xFF4F6F52)),
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
                        maxLength: 100,
                      ),
                      SizedBox(height: 20),

                      // Contenu (CONDITIONNEL)
                      Row(
                        children: [
                          Text(
                            'المحتوى',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F6F52),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedImage == null ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedImage == null ? 'مطلوب' : 'اختياري',
                              style: TextStyle(
                                fontSize: 10,
                                color: _selectedImage == null ? Colors.red[900] : Colors.green[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: 'أدخل محتوى الإعلان',
                          prefixIcon: Icon(Icons.description, color: Color(0xFF4F6F52)),
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
                        maxLines: 5,
                        maxLength: 500,
                      ),
                      SizedBox(height: 20),

                      // ✅ NOUVEAU : Section Image
                      Text(
                        'الصورة (اختياري)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      if (_selectedImage != null) ...[
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                      ],
                      
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: Icon(Icons.image),
                        label: Text(_selectedImage == null ? 'اختر صورة' : 'تغيير الصورة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4F6F52),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),

                      // Destinataires
                      Text(
                        'المستلمون *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 12),

                      RadioListTile<String>(
                        value: 'all',
                        groupValue: _targetAudience,
                        onChanged: (value) {
                          setState(() {
                            _targetAudience = value!;
                            _selectedGroupId = null;
                          });
                        },
                        title: Text('الجميع (أساتذة + طلاب)'),
                        activeColor: Color(0xFF4F6F52),
                        tileColor: _targetAudience == 'all'
                            ? Color(0xFF4F6F52).withOpacity(0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),

                      RadioListTile<String>(
                        value: 'teachers',
                        groupValue: _targetAudience,
                        onChanged: (value) {
                          setState(() {
                            _targetAudience = value!;
                            _selectedGroupId = null;
                          });
                        },
                        title: Text('الأساتذة فقط'),
                        activeColor: Color(0xFF4F6F52),
                        tileColor: _targetAudience == 'teachers'
                            ? Color(0xFF4F6F52).withOpacity(0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),

                      RadioListTile<String>(
                        value: 'students',
                        groupValue: _targetAudience,
                        onChanged: (value) {
                          setState(() {
                            _targetAudience = value!;
                            _selectedGroupId = null;
                          });
                        },
                        title: Text('الطلاب فقط'),
                        activeColor: Color(0xFF4F6F52),
                        tileColor: _targetAudience == 'students'
                            ? Color(0xFF4F6F52).withOpacity(0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),

                      RadioListTile<String>(
                        value: 'specific_group',
                        groupValue: _targetAudience,
                        onChanged: (value) {
                          setState(() {
                            _targetAudience = value!;
                          });
                        },
                        title: Text('مجموعة محددة (الأستاذ + الطلاب)'),
                        activeColor: Color(0xFF4F6F52),
                        tileColor: _targetAudience == 'specific_group'
                            ? Color(0xFF4F6F52).withOpacity(0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      if (_targetAudience == 'specific_group') ...[
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedGroupId,
                          decoration: InputDecoration(
                            labelText: 'اختر المجموعة',
                            prefixIcon: Icon(Icons.groups, color: Color(0xFF4F6F52)),
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
                          items: _groups.map((group) {
                            return DropdownMenuItem<String>(
                              value: group['id'],
                              child: Text(group['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGroupId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Bouton Envoyer
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendAnnouncement,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.send),
                    label: Text(
                      _isLoading ? 'جاري الإرسال...' : 'إرسال الإعلان',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F6F52),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}