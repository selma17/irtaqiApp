// lib/screens/admin/admin_exams_dashboard.dart
// ✨ VERSION PRO - Design moderne avec tableau dominant

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminExamsDashboard extends StatefulWidget {
  const AdminExamsDashboard({Key? key}) : super(key: key);

  @override
  _AdminExamsDashboardState createState() => _AdminExamsDashboardState();
}

class _AdminExamsDashboardState extends State<AdminExamsDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Filtres
  String selectedFilter = 'all';
  String searchQuery = '';
  int? selectedYear;
  int? selectedMonth;
  DateTime? selectedDay;
  List<int> availableYears = [];
  
  // État des filtres (collapsed/expanded)
  bool filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
  }

  void _loadAvailableYears() {
    int currentYear = DateTime.now().year;
    availableYears = List.generate(5, (index) => currentYear - index);
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      selectedYear = null;
      selectedMonth = null;
      selectedDay = null;
      selectedFilter = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // ✅ HEADER COMPACT
            _buildCompactHeader(),
            
            // ✅ FILTRES COMPACTS (Collapsible)
            _buildCompactFilters(),
            
            // ✅ TABLEAU DOMINANT (prend tout l'espace restant)
            Expanded(child: _buildProfessionalTable()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER COMPACT ET MODERNE
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ✅ BOUTON RETOUR
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4F6F52), size: 24),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'رجوع',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            
            // Icône + Titre
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة الامتحانات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),
            
            // Stats compactes
            _buildCompactStats(),
            
            const SizedBox(width: 12),
            
            // Boutons d'action
            if (searchQuery.isNotEmpty || selectedYear != null)
              IconButton(
                icon: const Icon(Icons.clear_all_rounded, color: Colors.red),
                onPressed: _resetFilters,
                tooltip: 'إعادة تعيين',
              ),
            
            IconButton(
              icon: Icon(
                filtersExpanded ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
                color: const Color(0xFF4F6F52),
              ),
              onPressed: () => setState(() => filtersExpanded = !filtersExpanded),
              tooltip: 'الفلاتر',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('exams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        int total = snapshot.data!.docs.length;
        int pending = snapshot.data!.docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        int graded = snapshot.data!.docs.where((d) => (d.data() as Map)['status'] == 'graded').length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniStat(total, 'الكل', Colors.blue[700]!),
              Container(width: 1, height: 20, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
              _buildMiniStat(pending, 'قيد الانتظار', Colors.orange[700]!),
              Container(width: 1, height: 20, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
              _buildMiniStat(graded, 'مكتمل', Colors.green[700]!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(int count, String label, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FILTRES COMPACTS ET COLLAPSIBLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: filtersExpanded ? null : 0,
      child: filtersExpanded
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Barre de recherche
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن طالب...',
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () => setState(() => searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Filtres de date (inline)
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildCompactYearFilter()),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildCompactMonthFilter()),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildCompactDayFilter()),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Filtres de statut (chips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('الكل', 'all', Icons.grid_view_rounded),
                        const SizedBox(width: 8),
                        _buildStatusChip('قيد الانتظار', 'pending', Icons.pending_outlined),
                        const SizedBox(width: 8),
                        _buildStatusChip('10 أحزاب', '10ahzab_pending', Icons.assignment_late_outlined),
                        const SizedBox(width: 8),
                        _buildStatusChip('مكتمل', 'graded', Icons.check_circle_outline),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCompactYearFilter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedYear,
          hint: const Text('السنة', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: [
            const DropdownMenuItem(value: null, child: Text('الكل', style: TextStyle(fontSize: 13))),
            ...availableYears.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: (v) => setState(() {
            selectedYear = v;
            if (v == null) {
              selectedMonth = null;
              selectedDay = null;
            }
          }),
        ),
      ),
    );
  }

  Widget _buildCompactMonthFilter() {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selectedYear == null ? Colors.grey[100] : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonth,
          hint: const Text('الشهر', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: [
            const DropdownMenuItem(value: null, child: Text('الكل', style: TextStyle(fontSize: 13))),
            ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i], style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: selectedYear == null ? null : (v) => setState(() {
            selectedMonth = v;
            if (v == null) selectedDay = null;
          }),
        ),
      ),
    );
  }

  Widget _buildCompactDayFilter() {
    return InkWell(
      onTap: (selectedYear == null || selectedMonth == null) ? null : () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDay ?? DateTime(selectedYear!, selectedMonth!),
          firstDate: DateTime(selectedYear!, selectedMonth!),
          lastDate: DateTime(selectedYear!, selectedMonth! + 1, 0),
        );
        if (picked != null) setState(() => selectedDay = picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: (selectedYear == null || selectedMonth == null) ? Colors.grey[100] : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDay != null ? '${selectedDay!.day}' : 'اليوم',
              style: TextStyle(fontSize: 13, color: selectedDay != null ? Colors.black : Colors.grey[600]),
            ),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, IconData icon) {
    bool isSelected = selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F6F52) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F6F52) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TABLEAU PROFESSIONNEL DOMINANT
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfessionalTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('exams').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4F6F52)),
                SizedBox(height: 16),
                Text('جاري التحميل...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filtrage
        List<DocumentSnapshot> exams = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          
          if (selectedFilter == 'pending' && data['status'] != 'pending') return false;
          if (selectedFilter == '10ahzab_pending' && !(data['type'] == '10ahzab' && data['status'] == 'pending')) return false;
          if (selectedFilter == 'graded' && data['status'] != 'graded') return false;
          
          if (searchQuery.isNotEmpty) {
            String studentName = (data['studentName'] ?? '').toLowerCase();
            if (!studentName.contains(searchQuery)) return false;
          }
          
          Timestamp? examDate = data['examDate'];
          if (examDate != null && (selectedYear != null || selectedMonth != null || selectedDay != null)) {
            DateTime date = examDate.toDate();
            if (selectedYear != null && date.year != selectedYear) return false;
            if (selectedMonth != null && date.month != selectedMonth) return false;
            if (selectedDay != null && (date.year != selectedDay!.year || date.month != selectedDay!.month || date.day != selectedDay!.day)) return false;
          }
          
          return true;
        }).toList();

        exams.sort((a, b) {
          Timestamp? aTime = (a.data() as Map<String, dynamic>)['examDate'];
          Timestamp? bTime = (b.data() as Map<String, dynamic>)['examDate'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (exams.isEmpty) {
          return _buildNoResultsState();
        }

        // TABLEAU MODERNE
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête du tableau
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6F52).withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 20, color: Color(0xFF4F6F52)),
                    const SizedBox(width: 8),
                    Text(
                      'قائمة الامتحانات (${exams.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Corps du tableau
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 20,
                      headingRowHeight: 50,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 60,
                      headingRowColor: WidgetStateProperty.all(Colors.transparent),
                      dividerThickness: 0.5,
                      columns: [
                        _buildTableHeader('#'),
                        _buildTableHeader('الطالب'),
                        _buildTableHeader('النوع'),
                        _buildTableHeader('التاريخ'),
                        _buildTableHeader('الحالة'),
                        _buildTableHeader('الأستاذ'),
                        _buildTableHeader('النتيجة'),
                        _buildTableHeader('الإجراء'),
                      ],
                      rows: List.generate(exams.length, (i) => _buildModernRow(i + 1, exams[i])),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataColumn _buildTableHeader(String label) {
    return DataColumn(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4F6F52),
        ),
      ),
    );
  }

  DataRow _buildModernRow(int num, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String studentName = data['studentName'] ?? '';
    String type = data['type'] == '5ahzab' ? '5 أحزاب' : '10 أحزاب';
    String status = data['status'] ?? '';
    Timestamp? examDate = data['examDate'];
    String dateText = examDate != null ? '${examDate.toDate().day}/${examDate.toDate().month}/${examDate.toDate().year}' : '-';
    int? grade = data['grade'];
    String assignedProf = data['assignedProfName'] ?? '-';
    
    Color statusColor = status == 'graded' ? Colors.green : status == 'pending' ? Colors.orange : Colors.grey;
    String statusText = status == 'pending' ? 'قيد الانتظار' : status == 'graded' ? 'مكتمل' : status;

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F6F52).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$num', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '؟',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: type.contains('10') ? Colors.purple[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: type.contains('10') ? Colors.purple[700] : Colors.blue[700],
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(dateText, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ),
        DataCell(Text(assignedProf, style: const TextStyle(fontSize: 13))),
        DataCell(
          grade != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: grade >= 15 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$grade/20',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: grade >= 15 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                )
              : const Text('-', style: TextStyle(fontSize: 13)),
        ),
        DataCell(
          status == 'pending' && type.contains('10')
              ? ElevatedButton.icon(
                  onPressed: () => _showAssignProfDialog(doc.id, data),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('تعيين', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6F52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              : const Text('-'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('لا توجد امتحانات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('ابدأ بإنشاء امتحانات للطلاب', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('لا توجد نتائج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('جرب تغيير الفلاتر أو البحث', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تعيين الفلاتر'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6F52),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOG ASSIGNATION
  // ═══════════════════════════════════════════════════════════
  Future<void> _showAssignProfDialog(String examId, Map<String, dynamic> examData) async {
    QuerySnapshot profsSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'prof').get();
    
    List<Map<String, dynamic>> profs = profsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {'id': doc.id, 'name': '${data['firstName']} ${data['lastName']}'};
    }).toList();

    String? selectedProfId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0); // ✅ Heure par défaut 9h00

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF4F6F52)),
                SizedBox(width: 8),
                Text('تعيين أستاذ', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F6F52).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF4F6F52)),
                      const SizedBox(width: 8),
                      Text('الطالب: ${examData['studentName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProfId,
                  decoration: const InputDecoration(
                    labelText: 'اختر الأستاذ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: profs.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(value: p['id'], child: Text(p['name']))).toList(),
                  onChanged: (v) => setDialogState(() => selectedProfId = v),
                ),
                const SizedBox(height: 16),
                const Text('تاريخ الامتحان:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                
                // ✅ NOUVEAU: Sélecteur d'heure
                const SizedBox(height: 16),
                const Text('وقت الامتحان:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Directionality(
                          textDirection: TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF4F6F52),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                      },
                    );
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedProfId == null ? null : () => _assignProf(examId, selectedProfId!, selectedDate, selectedTime, profs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6F52),
                  foregroundColor: Colors.white,
                ),
                child: const Text('تعيين'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignProf(String examId, String profId, DateTime examDate, TimeOfDay examTime, List<Map<String, dynamic>> profs) async {
    try {
      var prof = profs.firstWhere((p) => p['id'] == profId);
      
      // ✅ Combiner date et heure
      DateTime finalExamDateTime = DateTime(
        examDate.year,
        examDate.month,
        examDate.day,
        examTime.hour,
        examTime.minute,
      );
      
      await _firestore.collection('exams').doc(examId).update({
        'assignedProfId': profId,
        'assignedProfName': prof['name'],
        'examDate': Timestamp.fromDate(finalExamDateTime), // ✅ Date + heure combinées
        'status': 'approved',
      });

      await _firestore.collection('notifications').add({
        'userId': profId,
        'title': 'تم تعيينك لامتحان',
        'message': 'تم تعيينك لإجراء امتحان 10 أحزاب',
        'type': 'exam_assigned',
        'examId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم التعيين بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}