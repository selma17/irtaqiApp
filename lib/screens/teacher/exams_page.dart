// lib/screens/teacher/exams_page.dart
// ✅ VERSION AVEC FILTRE PAR NOM D'ÉTUDIANT

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import 'create_exam_page.dart';
import 'exam_details_page.dart';

class ExamsPage extends StatefulWidget {
  @override
  _ExamsPageState createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with SingleTickerProviderStateMixin {
  final ExamService _examService = ExamService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  
  // ✅ AJOUTÉ : Contrôleur de recherche
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إدارة الاختبارات'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'اختباراتي'),
              Tab(text: 'المسندة لي'),
              Tab(text: 'قيد الانتظار'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ✅ BARRE DE RECHERCHE
            _buildSearchBar(),
            
            // TABS CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyExamsTab(),
                  _buildAssignedExamsTab(),
                  _buildPendingExamsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            bool? created = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateExamPage()),
            );
            if (created == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ تم إنشاء الاختبار بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {});
            }
          },
          backgroundColor: Color(0xFF4F6F52),
          icon: Icon(Icons.add),
          label: Text('إنشاء اختبار'),
        ),
      ),
    );
  }

  // ✅ BARRE DE RECHERCHE
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن طالب...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF4F6F52)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ==================== TAB 1: MES EXAMENS ====================
  Widget _buildMyExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getProfExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'لا توجد اختبارات',
            subtitle: 'لم تقم بإنشاء أي اختبار بعد\nانقر على "إنشاء اختبار" للبدء',
          );
        }

        List<ExamModel> exams = snapshot.data!;
        
        // ✅ FILTRER PAR NOM
        if (_searchQuery.isNotEmpty) {
          exams = exams.where((exam) {
            return exam.studentName.toLowerCase().contains(_searchQuery);
          }).toList();
        }
        
        // Tri alphabétique
        exams.sort((a, b) => a.studentName.compareTo(b.studentName));

        if (exams.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResultsWidget();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(exams[index]);
          },
        );
      },
    );
  }

  // ==================== TAB 2: EXAMENS ASSIGNÉS ====================
  Widget _buildAssignedExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getAssignedExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'لا توجد اختبارات مسندة',
            subtitle: 'لم يتم تعيين أي اختبار 10 أحزاب لك بعد',
          );
        }

        List<ExamModel> exams = snapshot.data!;
        
        // ✅ FILTRER PAR NOM
        if (_searchQuery.isNotEmpty) {
          exams = exams.where((exam) {
            return exam.studentName.toLowerCase().contains(_searchQuery);
          }).toList();
        }
        
        // Tri alphabétique
        exams.sort((a, b) => a.studentName.compareTo(b.studentName));

        if (exams.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResultsWidget();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(exams[index]);
          },
        );
      },
    );
  }

  // ==================== TAB 3: EN ATTENTE ====================
  Widget _buildPendingExamsTab() {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getProfExamsStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF4F6F52)));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error ?? 'Unknown error');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hourglass_empty,
            title: 'لا توجد اختبارات قيد الانتظار',
            subtitle: 'جميع اختبارات 10 أحزاب تم تعيينها',
          );
        }

        // Filtrer seulement les exams en attente (10 ahzab sans assignedProfId)
        List<ExamModel> pendingExams = snapshot.data!
            .where((exam) => exam.type == '10ahzab' && exam.assignedProfId == null)
            .toList();
        
        // ✅ FILTRER PAR NOM
        if (_searchQuery.isNotEmpty) {
          pendingExams = pendingExams.where((exam) {
            return exam.studentName.toLowerCase().contains(_searchQuery);
          }).toList();
        }
        
        // Tri alphabétique
        pendingExams.sort((a, b) => a.studentName.compareTo(b.studentName));

        if (pendingExams.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResultsWidget();
        }

        if (pendingExams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hourglass_empty,
            title: 'لا توجد اختبارات قيد الانتظار',
            subtitle: 'جميع اختبارات 10 أحزاب تم تعيينها',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingExams.length,
          itemBuilder: (context, index) {
            return _buildExamCard(pendingExams[index]);
          },
        );
      },
    );
  }

  // ==================== EXAM CARD ====================
  Widget _buildExamCard(ExamModel exam) {
    bool isPending = exam.status == 'pending';
    bool isGraded = exam.status == 'graded';
    
    String dateDisplay = exam.examDate != null
        ? '${exam.examDate!.day}/${exam.examDate!.month}/${exam.examDate!.year}'
        : 'غير محدد';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamDetailsPage(exam: exam),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Nom étudiant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.studentName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E2F),
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: exam.type == '10ahzab'
                                      ? Colors.purple[50]
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  exam.typeDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: exam.type == '10ahzab'
                                        ? Colors.purple[700]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge status
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isGraded
                            ? Colors.green[50]
                            : isPending
                                ? Colors.orange[50]
                                : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isGraded
                              ? Colors.green
                              : isPending
                                  ? Colors.orange
                                  : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        isGraded ? 'مكتمل' : exam.statusDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isGraded
                              ? Colors.green[700]
                              : isPending
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(height: 12),
                
                // Infos
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Text(
                      'التاريخ: $dateDisplay',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Spacer(),
                    if (exam.assignedProfName != null) ...[
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'الأستاذ المشرف: ${exam.assignedProfName}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (exam.grade != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        'النتيجة: ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${exam.grade}/20',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: exam.grade! >= 15 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[300]),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET AUCUN RÉSULTAT
  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 100, color: Colors.grey[300]),
          SizedBox(height: 24),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لا يوجد امتحان يطابق "$_searchQuery"',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}