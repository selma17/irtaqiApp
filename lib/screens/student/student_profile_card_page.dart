// lib/screens/student/student_profile_card_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';

class StudentProfileCardPage extends StatefulWidget {
  @override
  _StudentProfileCardPageState createState() => _StudentProfileCardPageState();
}

class _StudentProfileCardPageState extends State<StudentProfileCardPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? currentUser;
  GroupModel? userGroup;
  String profName = 'غير محدد';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        // Charger les données de l'utilisateur
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          currentUser = UserModel.fromMap(userDoc.id, userDoc.data() as Map<String, dynamic>);

          // Charger le groupe si l'étudiant en a un
          if (currentUser!.groupId != null && currentUser!.groupId!.isNotEmpty) {
            DocumentSnapshot groupDoc = await _firestore
                .collection('groups')
                .doc(currentUser!.groupId)
                .get();
            
            if (groupDoc.exists) {
              userGroup = GroupModel.fromDoc(groupDoc);

              // Charger le nom du prof
              DocumentSnapshot profDoc = await _firestore
                  .collection('users')
                  .doc(userGroup!.profId)
                  .get();
              
              if (profDoc.exists) {
                Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
                profName = '${profData['firstName']} ${profData['lastName']}';
              }
            }
          }
        }
      }
      setState(() => isLoading = false);
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('الفيش الشخصي'),
          backgroundColor: Color(0xFF4F6F52),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: 20),
                    _buildPersonalInfoCard(),
                    SizedBox(height: 16),
                    _buildGroupInfoCard(),
                    SizedBox(height: 16),
                    _buildProgressInfoCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
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
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 50,
              color: Color(0xFF4F6F52),
            ),
          ),
          SizedBox(height: 16),
          Text(
            currentUser?.fullName ?? 'الطالب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            currentUser?.email ?? '',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
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
              Icon(Icons.person_outline, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.badge, 'الاسم الكامل', currentUser?.fullName ?? '-'),
          Divider(height: 24),
          _buildInfoRow(Icons.cake, 'العمر', '${currentUser?.age ?? '-'} سنة'),
          Divider(height: 24),
          _buildInfoRow(Icons.phone, 'الهاتف', currentUser?.phone ?? '-'),
          Divider(height: 24),
          _buildInfoRow(Icons.email, 'البريد الإلكتروني', currentUser?.email ?? '-'),
          Divider(height: 24),
          _buildInfoRow(Icons.location_city, 'المدينة', currentUser?.city ?? 'غير محدد'),
          Divider(height: 24),
          _buildInfoRow(
            Icons.calendar_today,
            'تاريخ الانضمام',
            currentUser?.dateInscription != null
                ? '${currentUser!.dateInscription!.day}/${currentUser!.dateInscription!.month}/${currentUser!.dateInscription!.year}'
                : 'غير محدد',
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    bool hasGroup = userGroup != null;

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
              Icon(Icons.groups, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'معلومات المجموعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (!hasGroup)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 60, color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'لم يتم تعيينك لمجموعة بعد',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildInfoRow(Icons.group, 'اسم المجموعة', userGroup!.name),
            Divider(height: 24),
            _buildInfoRow(Icons.person, 'الأستاذ المشرف', profName),
            Divider(height: 24),
            _buildInfoRow(
              Icons.people,
              'عدد الطلاب',
              '${userGroup!.currentStudentsCount}/${userGroup!.maxStudents}',
            ),
            Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule, color: Color(0xFF4F6F52), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أوقات الحصص',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      ...userGroup!.schedule.map((slot) => Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFF4F6F52).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Color(0xFF4F6F52)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slot.toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4F6F52),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressInfoCard() {
    int oldHafd = currentUser?.oldHafd ?? 0;
    int newHafd = currentUser?.newHafd ?? 0;
    int totalHafd = oldHafd + newHafd;
    double progress = totalHafd / 60;

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
              Icon(Icons.trending_up, color: Color(0xFF4F6F52)),
              SizedBox(width: 8),
              Text(
                'تقدم الحفظ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem('الحفظ السابق', oldHafd, Colors.grey),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              _buildProgressItem('الحفظ الجديد', newHafd, Colors.green),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              _buildProgressItem('المجموع', totalHafd, Colors.blue),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'النسبة المئوية',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F6F52)),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% من القرآن الكريم',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F6F52),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF4F6F52), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}