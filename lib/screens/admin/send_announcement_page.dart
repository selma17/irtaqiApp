// lib/screens/admin/send_announcement_page.dart
// ✅ VERSION SANS IMAGE - Texte seulement

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/announcement_service.dart';

class SendAnnouncementPage extends StatefulWidget {
  @override
  _SendAnnouncementPageState createState() => _SendAnnouncementPageState();
}

class _SendAnnouncementPageState extends State<SendAnnouncementPage> {
  final AnnouncementService _announcementService = AnnouncementService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _targetAudience = 'all';
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;

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

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ يرجى إدخال محتوى الإعلان'),
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
      // Préparer les données (SANS imageUrl)
      Map<String, dynamic> announcementData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
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
                              'أرسل إعلانًا نصيًا للمستخدمين',
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
                      Text(
                        'المحتوى *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
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
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        maxLength: 1000,
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