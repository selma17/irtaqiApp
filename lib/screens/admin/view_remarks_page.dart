// lib/screens/admin/view_remarks_page.dart

import 'package:flutter/material.dart';
import '../../services/remark_service.dart';
import '../../models/remark_model.dart';
import 'package:intl/intl.dart'hide TextDirection;

class ViewRemarksPage extends StatefulWidget {
  const ViewRemarksPage({Key? key}) : super(key: key);

  @override
  State<ViewRemarksPage> createState() => _ViewRemarksPageState();
}

class _ViewRemarksPageState extends State<ViewRemarksPage> {
  final RemarkService _remarkService = RemarkService();
  String _filterStatus = 'all'; // all, new, open, closed

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الملاحظات الواردة'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildRemarksList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('الكل', 'all'),
            SizedBox(width: 8),
            _buildFilterChip('جديدة', 'new'),
            SizedBox(width: 8),
            _buildFilterChip('قيد المعالجة', 'open'),
            SizedBox(width: 8),
            _buildFilterChip('مغلقة', 'closed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: Color(0xFF4F6F52).withValues(alpha: 0.2),
      checkmarkColor: Color(0xFF4F6F52),
    );
  }

  Widget _buildRemarksList() {
    return StreamBuilder<List<RemarkModel>>(
      stream: _remarkService.getAllRemarksStream(),
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
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد ملاحظات',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filtrer les remarques selon le statut sélectionné
        List<RemarkModel> filteredRemarks = snapshot.data!.where((remark) {
          if (_filterStatus == 'all') return true;
          return remark.status == _filterStatus;
        }).toList();

        if (filteredRemarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد ملاحظات في هذا التصنيف',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredRemarks.length,
          itemBuilder: (context, index) {
            return _buildRemarkCard(filteredRemarks[index]);
          },
        );
      },
    );
  }

  Widget _buildRemarkCard(RemarkModel remark) {
    Color statusColor = remark.isNew
        ? Colors.orange
        : remark.isOpen
            ? Colors.blue
            : Colors.green;

    String statusText = remark.isNew
        ? 'جديدة'
        : remark.isOpen
            ? 'قيد المعالجة'
            : 'مغلقة';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRemarkDetails(remark),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status badge
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
                  SizedBox(width: 8),
                  // Role badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: remark.senderRole == 'prof'
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      remark.senderRole == 'prof' ? 'أستاذ' : 'طالب',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: remark.senderRole == 'prof'
                            ? Colors.purple
                            : Colors.blue,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatDate(remark.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Sender name
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    remark.senderName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F6F52),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Message preview
              Text(
                remark.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              if (remark.hasResponse) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'تم الرد على هذه الملاحظة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRemarkDetails(RemarkModel remark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF4F6F52),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'تفاصيل الملاحظة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info row
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            remark.senderName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: remark.senderRole == 'prof'
                                  ? Colors.purple.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              remark.senderRole == 'prof' ? 'أستاذ' : 'طالب',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: remark.senderRole == 'prof'
                                    ? Colors.purple
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          Spacer(),
                          Text(
                            _formatDate(remark.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Message
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          remark.message,
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Response section
                      if (remark.hasResponse) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                      size: 16, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    'رد الإدارة:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                remark.adminResponse!,
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      // Action buttons
                      if (!remark.isClosed) ...[
                        if (!remark.isOpen)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _changeStatus(remark.id, 'open');
                              },
                              icon: Icon(Icons.open_in_new),
                              label: Text('فتح الملاحظة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showResponseDialog(remark);
                            },
                            icon: Icon(Icons.reply),
                            label: Text('الرد على الملاحظة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4F6F52),
                              padding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponseDialog(RemarkModel remark) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('الرد على الملاحظة'),
          content: TextField(
            controller: responseController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'اكتب ردك هنا...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                if (responseController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  bool success = await _remarkService.respondToRemark(
                    remarkId: remark.id,
                    response: responseController.text.trim(),
                  );
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم إرسال الرد بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(String remarkId, String newStatus) async {
    bool success = await _remarkService.changeStatus(remarkId, newStatus);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحديث الحالة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inHours < 1) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }
}