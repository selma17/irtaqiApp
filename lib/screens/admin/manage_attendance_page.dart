// lib/screens/admin/manage_attendance_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'attendance_details_page.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ManageAttendancePage extends StatefulWidget {
  @override
  _ManageAttendancePageState createState() => _ManageAttendancePageState();
}

class _ManageAttendancePageState extends State<ManageAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? selectedProfId;
  String? selectedGroupId;
  String? selectedMonth;
  String? selectedYear;
  
  List<UserModel> professors = [];
  List<Map<String, dynamic>> groupsOfProf = [];
  
  bool isLoadingProfs = true;
  bool isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _loadProfessors();
    // Initialiser avec le mois et l'année actuels
    DateTime now = DateTime.now();
    selectedMonth = now.month.toString().padLeft(2, '0');
    selectedYear = now.year.toString();
  }

  Future<void> _loadProfessors() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'prof')
          .orderBy('firstName')
          .get();

      setState(() {
        professors = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        isLoadingProfs = false;
      });
    } catch (e) {
      print('Erreur chargement profs: $e');
      setState(() {
        isLoadingProfs = false;
      });
    }
  }

  Future<void> _loadGroupsOfProfessor(String profId) async {
    setState(() {
      isLoadingGroups = true;
      groupsOfProf = [];
      selectedGroupId = null;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('groups')
          .where('profId', isEqualTo: profId)
          .get();

      setState(() {
        groupsOfProf = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? 'مجموعة',
          };
        }).toList();
        isLoadingGroups = false;
      });
    } catch (e) {
      print('Erreur chargement groupes: $e');
      setState(() {
        isLoadingGroups = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إدارة فيش الحضور'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: Column(
          children: [
            _buildFiltersSection(),
            Expanded(child: _buildAttendanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.filter_list, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'تصفية النتائج',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Ligne 1: Professeur
          Row(
            children: [
              Expanded(child: _buildProfessorDropdown()),
            ],
          ),
          SizedBox(height: 12),

          // Ligne 2: Groupe + Mois + Année
          Row(
            children: [
              Expanded(flex: 2, child: _buildGroupDropdown()),
              SizedBox(width: 8),
              Expanded(child: _buildMonthDropdown()),
              SizedBox(width: 8),
              Expanded(child: _buildYearDropdown()),
            ],
          ),

          // Bouton réinitialiser
          if (selectedProfId != null || selectedGroupId != null)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedProfId = null;
                    selectedGroupId = null;
                    groupsOfProf = [];
                    DateTime now = DateTime.now();
                    selectedMonth = now.month.toString().padLeft(2, '0');
                    selectedYear = now.year.toString();
                  });
                },
                icon: Icon(Icons.refresh, size: 18),
                label: Text('إعادة تعيين'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF4F6F52),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfessorDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF6F3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: isLoadingProfs
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedProfId,
                hint: Text('اختر الأستاذ'),
                icon: Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('جميع الأساتذة', style: TextStyle(color: Colors.grey[600])),
                  ),
                  ...professors.map((prof) {
                    return DropdownMenuItem<String>(
                      value: prof.id,
                      child: Text(prof.fullName),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedProfId = value;
                    if (value != null) {
                      _loadGroupsOfProfessor(value);
                    } else {
                      groupsOfProf = [];
                      selectedGroupId = null;
                    }
                  });
                },
              ),
            ),
    );
  }

  Widget _buildGroupDropdown() {
    bool isDisabled = selectedProfId == null;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade200 : Color(0xFFF6F3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: isLoadingGroups
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedGroupId,
                hint: Text(
                  isDisabled ? 'اختر أستاذ أولاً' : 'اختر المجموعة',
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.black87,
                  ),
                ),
                icon: Icon(Icons.arrow_drop_down),
                items: isDisabled
                    ? null
                    : [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('جميع المجموعات', style: TextStyle(color: Colors.grey[600])),
                        ),
                        ...groupsOfProf.map((group) {
                          return DropdownMenuItem<String>(
                            value: group['id'],
                            child: Text(group['name']),
                          );
                        }).toList(),
                      ],
                onChanged: isDisabled
                    ? null
                    : (value) {
                        setState(() {
                          selectedGroupId = value;
                        });
                      },
              ),
            ),
    );
  }

  Widget _buildMonthDropdown() {
    List<String> months = [
      '01', '02', '03', '04', '05', '06',
      '07', '08', '09', '10', '11', '12'
    ];
    
    List<String> monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF6F3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedMonth,
          icon: Icon(Icons.arrow_drop_down, size: 20),
          style: TextStyle(fontSize: 13),
          items: months.asMap().entries.map((entry) {
            int idx = entry.key;
            String month = entry.value;
            return DropdownMenuItem<String>(
              value: month,
              child: Text(monthNames[idx], style: TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedMonth = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(5, (i) => (currentYear - i).toString());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF6F3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedYear,
          icon: Icon(Icons.arrow_drop_down, size: 20),
          style: TextStyle(fontSize: 13),
          items: years.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year, style: TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedYear = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    // ✅ Ne rien afficher si aucun filtre sélectionné
    if (selectedProfId == null && selectedGroupId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'اختر أستاذاً لعرض فيش الحضور',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'استخدم الفلاتر أعلاه للبحث',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        print('🔍 DEBUG StreamBuilder:');
        print('  - connectionState: ${snapshot.connectionState}');
        print('  - hasData: ${snapshot.hasData}');
        print('  - hasError: ${snapshot.hasError}');
        if (snapshot.hasData) {
          print('  - nombre de docs: ${snapshot.data!.docs.length}');
          snapshot.data!.docs.forEach((doc) {
            print('  - doc ID: ${doc.id}');
            print('  - doc data: ${doc.data()}');
          });
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4F6F52)),
                SizedBox(height: 16),
                Text(
                  'جاري تحميل البيانات...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text('حدث خطأ في تحميل البيانات'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد فيش حضور',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  selectedProfId != null 
                    ? 'لم يتم إنشاء أي فيشة لهذا الأستاذ'
                    : 'لم يتم إنشاء أي فيشة بعد',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        // ✅ Trier les documents par date côté client
        List<DocumentSnapshot> docs = snapshot.data!.docs;
        docs.sort((a, b) {
          Timestamp? aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          Timestamp? bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Plus récent en premier
        });

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildAttendanceCard(docs[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    // ✅ Si aucun filtre, retourner un stream vide
    if (selectedProfId == null && selectedGroupId == null) {
      print('🔍 DEBUG: Aucun filtre sélectionné - stream vide');
      return Stream<QuerySnapshot>.empty();
    }

    print('🔍 DEBUG: Construction requête');
    print('  - selectedProfId: $selectedProfId');
    print('  - selectedGroupId: $selectedGroupId');
    print('  - selectedMonth: $selectedMonth');
    print('  - selectedYear: $selectedYear');

    Query query = _firestore.collection('attendance');

    // Filtrer par prof - utiliser updatedBy au lieu de profId
    if (selectedProfId != null) {
      query = query.where('updatedBy', isEqualTo: selectedProfId);
      print('  - Filtre updatedBy appliqué');
    }

    // Filtrer par groupe
    if (selectedGroupId != null) {
      query = query.where('groupId', isEqualTo: selectedGroupId);
      print('  - Filtre groupId appliqué');
    }

    // Filtrer par mois/année
    if (selectedMonth != null && selectedYear != null) {
      String monthFilter = '$selectedYear-$selectedMonth';
      query = query.where('month', isEqualTo: monthFilter);
      print('  - Filtre month appliqué: $monthFilter');
    }

    return query.snapshots();
  }

  Widget _buildAttendanceCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    String groupName = data['groupName'] ?? 'مجموعة';
    String profId = data['updatedBy'] ?? data['profId'] ?? ''; // Utiliser updatedBy
    String month = data['month'] ?? '';
    Timestamp? createdAt = data['createdAt'];
    Timestamp? lastUpdated = data['updatedAt'] ?? data['lastUpdated'];

    // ✅ Compter les étudiants dans la nouvelle structure
    Map<String, dynamic> students = data['students'] ?? {};
    int studentCount = students.length;

    return FutureBuilder<String>(
      future: _getProfName(profId),
      builder: (context, profSnapshot) {
        String profName = profSnapshot.data ?? 'جاري التحميل...';

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceDetailsPage(
                    attendanceId: doc.id,
                    groupName: groupName,
                    profName: profName,
                    month: month,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.assignment, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F6F52),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatMonth(month),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 8),

                  // Infos
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.person_outline,
                        label: profName,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.people_outline,
                        label: '$studentCount طالب',
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  if (lastUpdated != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.update, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'آخر تحديث: ${_formatDate(lastUpdated.toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getProfName(String profId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(profId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
      }
    } catch (e) {
      print('Erreur récupération nom prof: $e');
    }
    return 'أستاذ';
  }

  String _formatMonth(String month) {
    if (month.isEmpty) return '';
    
    try {
      List<String> parts = month.split('-');
      if (parts.length == 2) {
        String year = parts[0];
        String monthNum = parts[1];
        
        List<String> monthNames = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        
        int monthIndex = int.parse(monthNum) - 1;
        if (monthIndex >= 0 && monthIndex < 12) {
          return '${monthNames[monthIndex]} $year';
        }
      }
    } catch (e) {
      print('Erreur format mois: $e');
    }
    
    return month;
  }

  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}