// lib/screens/teacher/teacher_send_remark_page.dart
// ✅ VERSION CORRIGÉE - Fix du chargement infini des remarques

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/remark_service.dart';
import '../../models/user_model.dart';
import '../../models/remark_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSendRemarkPage extends StatefulWidget {
  @override
  _TeacherSendRemarkPageState createState() => _TeacherSendRemarkPageState();
}

class _TeacherSendRemarkPageState extends State<TeacherSendRemarkPage> {
  final AuthService _authService = AuthService();
  final RemarkService _remarkService = RemarkService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  UserModel? currentUser;
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            currentUser = UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendRemark() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء كتابة رسالة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      bool success = await _remarkService.sendRemark(
        senderId: currentUser!.id,
        senderName: currentUser!.fullName,
        senderRole: currentUser!.role,
        message: _messageController.text.trim(),
      );

      setState(() => isSending = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إرسال الملاحظة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ أثناء الإرسال'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
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
          title: Text('إرسال ملاحظة'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 20),
                    _buildMessageForm(),
                    SizedBox(height: 20),
                    _buildMyRemarksSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.message, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إرسال ملاحظة للإدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'شارك ملاحظاتك أو استفساراتك مع الإدارة',
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

  Widget _buildMessageForm() {
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
            children: [
              Icon(Icons.edit, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'اكتب رسالتك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 8,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظتك أو استفسارك هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
              ),
              filled: true,
              fillColor: Color(0xFFF6F3EE),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSending ? null : _sendRemark,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F6F52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSending
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إرسال الملاحظة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : StreamBuilder direct sur Firestore au lieu du service
  Widget _buildMyRemarksSection() {
    if (currentUser == null) {
      return SizedBox.shrink();
    }

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
            children: [
              Icon(Icons.history, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'ملاحظاتي السابقة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // ✅ StreamBuilder CORRIGÉ - Direct sur Firestore
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('remarks')
                .where('senderId', isEqualTo: currentUser!.id)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              // Debug
              print('🔍 Stream State: ${snapshot.connectionState}');
              print('🔍 Has Data: ${snapshot.hasData}');
              print('🔍 Docs Count: ${snapshot.data?.docs.length}');
              print('🔍 Error: ${snapshot.error}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF4F6F52)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.error, size: 60, color: Colors.red),
                        SizedBox(height: 12),
                        Text(
                          'خطأ: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                        SizedBox(height: 12),
                        Text(
                          'لم ترسل أي ملاحظات بعد',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              List<DocumentSnapshot> remarks = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: remarks.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  var remarkData = remarks[index].data() as Map<String, dynamic>;
                  return _buildRemarkCard(remarkData);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkCard(Map<String, dynamic> remarkData) {
    String message = remarkData['message'] ?? '';
    bool hasResponse = remarkData['adminResponse'] != null && 
                      remarkData['adminResponse'].toString().isNotEmpty;
    String? adminResponse = remarkData['adminResponse'];
    
    Timestamp? createdAtTimestamp = remarkData['createdAt'];
    DateTime createdAt = createdAtTimestamp?.toDate() ?? DateTime.now();

    Color statusColor = hasResponse ? Colors.green : Colors.orange;
    String statusText = hasResponse ? 'تم الرد' : 'قيد المعالجة';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          if (hasResponse) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.green[700]),
                      SizedBox(width: 6),
                      Text(
                        'رد الإدارة:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    adminResponse!,
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}