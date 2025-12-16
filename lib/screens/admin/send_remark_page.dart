// lib/screens/admin/send_remark_page.dart

import 'package:flutter/material.dart';
import '../../services/remark_service.dart';
import '../../services/auth_service.dart';

class SendRemarkPage extends StatefulWidget {
  const SendRemarkPage({Key? key}) : super(key: key);

  @override
  State<SendRemarkPage> createState() => _SendRemarkPageState();
}

class _SendRemarkPageState extends State<SendRemarkPage> {
  final RemarkService _remarkService = RemarkService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'suggestion';
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRemark() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Construire le message complet avec les détails
      String fullMessage = 'الموضوع: ${_subjectController.text}\n\n';
      fullMessage += 'النوع: ${_getTypeLabel(_selectedType)}\n\n';
      fullMessage += 'الرسالة:\n${_messageController.text}';
      
      if (_isAnonymous) {
        fullMessage += '\n\n(ملاحظة: هذه رسالة مجهولة)';
      }

      bool success = await _remarkService.sendRemark(
        senderId: _authService.getCurrentUserId() ?? 'unknown',
        senderName: _isAnonymous ? 'مجهول' : 'الإدارة',
        senderRole: 'admin',
        message: fullMessage,
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إرسال الملاحظة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedType = 'suggestion';
          _isAnonymous = false;
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
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'suggestion':
        return 'اقتراح';
      case 'complaint':
        return 'شكوى';
      case 'question':
        return 'استفسار';
      default:
        return 'أخرى';
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
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                SizedBox(height: 20),
                _buildFormCard(),
              ],
            ),
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
            color: Color(0xFF4F6F52).withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
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
                  'إرسال ملاحظة عامة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'يمكنك إرسال ملاحظة أو استفسار للنظام',
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

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'الموضوع *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.subject),
            ),
            validator: (value) =>
                value!.isEmpty ? 'الرجاء إدخال الموضوع' : null,
          ),
          SizedBox(height: 16),

          // Type
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'النوع *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.category),
            ),
            items: [
              DropdownMenuItem(value: 'suggestion', child: Text('اقتراح')),
              DropdownMenuItem(value: 'complaint', child: Text('شكوى')),
              DropdownMenuItem(value: 'question', child: Text('استفسار')),
              DropdownMenuItem(value: 'other', child: Text('أخرى')),
            ],
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          SizedBox(height: 16),

          // Message
          TextFormField(
            controller: _messageController,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'الرسالة *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                value!.isEmpty ? 'الرجاء إدخال الرسالة' : null,
          ),
          SizedBox(height: 16),

          // Anonymous checkbox
          CheckboxListTile(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value!),
            title: Text('إرسال كمجهول'),
            subtitle: Text('سيتم إخفاء اسمك من الملاحظة'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRemark,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F6F52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}