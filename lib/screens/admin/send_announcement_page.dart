// lib/screens/admin/send_announcement_page.dart
// ✅ VERSION FINALE CORRIGÉE - Image s'affiche instantanément sur web

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  
  // ✅ dynamic pour supporter web (XFile) et mobile (File)
  dynamic _selectedImage;

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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ Image sélectionnée: ${image.path}');
        setState(() {
          if (kIsWeb) {
            _selectedImage = image;  // Garder XFile sur web
          } else {
            _selectedImage = File(image.path);  // Convertir en File sur mobile
          }
        });
        print('✅ _selectedImage défini: ${_selectedImage != null}');
      }
    } catch (e) {
      print('❌ Erreur sélection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      String fileName = 'announcements/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Sur web : upload bytes
        final bytes = await (_selectedImage as XFile).readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        // Sur mobile : upload file
        uploadTask = storageRef.putFile(_selectedImage as File);
      }
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _sendAnnouncement() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى إدخال عنوان الإعلان'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImage == null && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى إدخال محتوى الإعلان أو اختيار صورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_targetAudience == 'group' && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى اختيار المجموعة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image si existe
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('فشل رفع الصورة');
        }
      }

      // Préparer les données
      Map<String, dynamic> announcementData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl,
        'targetAudience': _targetAudience,
        'groupId': _selectedGroupId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Envoyer l'annonce
      await _firestore.collection('announcements').add(announcementData);

      // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم إرسال الإعلان بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedImage = null;
        _targetAudience = 'all';
        _selectedGroupId = null;
      });

      Navigator.pop(context);
    } catch (e) {
      print('Erreur envoi annonce: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء الإرسال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
                      // Titre
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

                      // Contenu
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

                      // ✅ Section Image CORRIGÉE
                      Text(
                        'الصورة (اختياري)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // ✅ AFFICHAGE IMAGE CORRIGÉ - INSTANTANÉ SUR WEB
                      if (_selectedImage != null) ...[
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    // ✅ WEB : Image.network avec blob URL (INSTANTANÉ)
                                    ? Image.network(
                                        (_selectedImage as XFile).path,  // blob:http://...
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Erreur affichage web: $error');
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.image, size: 60, color: Colors.grey),
                                                  SizedBox(height: 8),
                                                  Text('Image sélectionnée', style: TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    // ✅ MOBILE : Image.file
                                    : Image.file(
                                        _selectedImage as File,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200,
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
                      ),

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
                      ),

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
                      ),

                      RadioListTile<String>(
                        value: 'group',
                        groupValue: _targetAudience,
                        onChanged: (value) {
                          setState(() {
                            _targetAudience = value!;
                          });
                        },
                        title: Text('مجموعة محددة'),
                        activeColor: Color(0xFF4F6F52),
                      ),

                      if (_targetAudience == 'group') ...[
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedGroupId,
                          decoration: InputDecoration(
                            hintText: 'اختر المجموعة',
                            filled: true,
                            fillColor: Color(0xFFF6F3EE),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F6F52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'إرسال الإعلان',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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