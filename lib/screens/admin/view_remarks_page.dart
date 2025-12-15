// lib/screens/admin/view_remarks_page.dart
// ✅ VERSION FINALE - Tous les bugs corrigés

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/remark_service.dart';

class ViewRemarksPage extends StatefulWidget {
  @override
  _ViewRemarksPageState createState() => _ViewRemarksPageState();
}

class _ViewRemarksPageState extends State<ViewRemarksPage> {
  final RemarkService _remarkService = RemarkService();
  String _selectedFilter = 'all'; // 'all', 'new', 'open'

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
            // Filter tabs
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('all', 'الكل'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('new', 'جديد'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('open', 'مفتوح'),
                  ),
                ],
              ),
            ),

            // Remarks list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _remarkService.getAllRemarks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدث خطأ في تحميل الملاحظات'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                  // ✅ Filtrer côté client
                  List<DocumentSnapshot> allDocs = snapshot.data!.docs;
                  List<DocumentSnapshot> filteredDocs;

                  if (_selectedFilter == 'all') {
                    filteredDocs = allDocs;
                  } else {
                    filteredDocs = allDocs.where((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _selectedFilter;
                    }).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد ملاحظات بحالة "${_getFilterLabel(_selectedFilter)}"',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = filteredDocs[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                      return _buildRemarkCard(doc.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'new':
        return 'جديد';
      case 'open':
        return 'مفتوح';
      default:
        return 'الكل';
    }
  }

  Widget _buildFilterChip(String value, String label) {
    bool isSelected = _selectedFilter == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4F6F52) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF4F6F52).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRemarkCard(String remarkId, Map<String, dynamic> data) {
    String subject = data['subject'] ?? '';
    String type = data['type'] ?? '';
    String status = data['status'] ?? 'new';
    String senderName = data['senderName'] ?? '';
    bool isAnonymous = data['isAnonymous'] ?? false;
    //String? response = data['response'];
    Timestamp? createdAt = data['createdAt'];

    // Icône et couleur selon le type
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (type) {
      case 'suggestion':
        typeIcon = Icons.lightbulb;
        typeColor = Colors.amber;
        typeLabel = 'اقتراح';
        break;
      case 'problem':
        typeIcon = Icons.warning;
        typeColor = Colors.red;
        typeLabel = 'مشكلة';
        break;
      case 'question':
        typeIcon = Icons.help;
        typeColor = Colors.blue;
        typeLabel = 'سؤال';
        break;
      default:
        typeIcon = Icons.info;
        typeColor = Colors.grey;
        typeLabel = 'أخرى';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: typeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showRemarkDetails(remarkId, data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              isAnonymous ? 'مجهول' : senderName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              _remarkService.formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'new' ? Colors.red[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'new' ? 'جديد' : 'مفتوح',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status == 'new' ? Colors.red[900] : Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FONCTION SIMPLIFIÉE : Admin peut uniquement changer le statut (pas de réponse)
  void _showRemarkDetails(String remarkId, Map<String, dynamic> data) {
    String currentStatus = data['status'] ?? 'new';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('تفاصيل الملاحظة'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('الموضوع', data['subject'] ?? ''),
                SizedBox(height: 12),
                _buildDetailRow('النوع', _getTypeLabel(data['type'] ?? '')),
                SizedBox(height: 12),
                _buildDetailRow('من', data['isAnonymous'] == true ? 'مجهول' : (data['senderName'] ?? '')),
                SizedBox(height: 12),
                _buildDetailRow('التفاصيل', data['details'] ?? ''),
                
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 12),
                
                // ✅ Changement de statut uniquement
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'الحالة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: currentStatus,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'new',
                              child: Row(
                                children: [
                                  Icon(Icons.fiber_new, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('جديد'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.folder_open, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('مفتوح'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              currentStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Info box
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'يمكنك تغيير حالة الملاحظة لتنظيمها',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق'),
            ),
            
            // ✅ Bouton pour changer le statut si modifié
            if (currentStatus != data['status'])
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F6F52),
                ),
                onPressed: () async {
                  await _remarkService.changeRemarkStatus(remarkId, currentStatus);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم تحديث الحالة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('تحديث الحالة'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'suggestion':
        return 'اقتراح';
      case 'problem':
        return 'مشكلة';
      case 'question':
        return 'سؤال';
      default:
        return 'أخرى';
    }
  }
}