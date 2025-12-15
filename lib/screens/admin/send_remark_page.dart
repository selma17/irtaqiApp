// lib/screens/common/send_remark_page.dart

import 'package:flutter/material.dart';
import '../../services/remark_service.dart';

class SendRemarkPage extends StatefulWidget {
  @override
  _SendRemarkPageState createState() => _SendRemarkPageState();
}

class _SendRemarkPageState extends State<SendRemarkPage> {
  final RemarkService _remarkService = RemarkService();
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _type = 'suggestion';
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _sendRemark() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await _remarkService.sendRemark(
      subject: _subjectController.text.trim(),
      type: _type,
      details: _detailsController.text.trim(),
      isAnonymous: _isAnonymous,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم إرسال الملاحظة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear and go back
      Navigator.pop(context);
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
                      Icon(Icons.feedback, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ملاحظة جديدة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'شاركنا رأيك أو اقتراحك',
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
                      // Subject
                      Text(
                        'الموضوع *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'عنوان الملاحظة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.title, color: Color(0xFF4F6F52)),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'الرجاء إدخال الموضوع' : null,
                      ),
                      SizedBox(height: 20),

                      // Type
                      Text(
                        'النوع *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTypeChip('suggestion', 'اقتراح', Icons.lightbulb),
                          _buildTypeChip('problem', 'مشكلة', Icons.warning),
                          _buildTypeChip('question', 'سؤال', Icons.help),
                          _buildTypeChip('other', 'أخرى', Icons.note),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Details
                      Text(
                        'التفاصيل *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _detailsController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'اكتب تفاصيل الملاحظة هنا...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'الرجاء إدخال التفاصيل' : null,
                      ),
                      SizedBox(height: 20),

                      // Anonymous option
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          title: Text('إرسال بشكل مجهول'),
                          subtitle: Text(
                            'لن يتم إظهار اسمك للإدارة',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() => _isAnonymous = value ?? false);
                          },
                          activeColor: Color(0xFF4F6F52),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Info box
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
                                'سيتم مراجعة ملاحظتك من قبل الإدارة في أقرب وقت',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Send Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendRemark,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send),
                          label: Text(
                            _isLoading ? 'جاري الإرسال...' : 'إرسال الملاحظة',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4F6F52),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    bool isSelected = _type == value;
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Color(0xFF4F6F52),
          ),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _type = value);
        }
      },
      selectedColor: Color(0xFF4F6F52),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF4F6F52),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}