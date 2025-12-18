// lib/screens/student/student_profile_card_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  UserModel? currentUser;
  GroupModel? userGroup;
  String profName = 'غير محدد';
  bool isLoading = true;
  bool isUploadingPhoto = false;

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

  Future<void> _pickAndUploadImage() async {
    try {
      // Afficher un dialogue pour choisir la source
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'اختر مصدر الصورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F6F52),
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.camera_alt, color: Color(0xFF4F6F52)),
                  ),
                  title: Text('الكاميرا'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF4F6F52).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library, color: Color(0xFF4F6F52)),
                  ),
                  title: Text('المعرض'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      setState(() => isUploadingPhoto = true);

      XFile? image;
      try {
        image = await _picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
      } catch (e) {
        print('Erreur lors de la sélection de l\'image: $e');
        setState(() => isUploadingPhoto = false);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في اختيار الصورة'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      if (image == null) {
        setState(() => isUploadingPhoto = false);
        return;
      }

      // Upload vers Firebase Storage
      String userId = currentUser!.id;
      String fileName = 'profile_$userId.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Lire les bytes de l'image
      final bytes = await image.readAsBytes();
      
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      String downloadURL = await storageRef.getDownloadURL();

      // Mettre à jour Firestore
      await _firestore.collection('users').doc(userId).update({
        'profileImage': downloadURL,
      });

      // Recharger les données
      await _loadData();

      setState(() => isUploadingPhoto = false);

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الصورة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() => isUploadingPhoto = false);
      print('Erreur upload image: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل الصورة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPersonalInfoCard(),
                          SizedBox(height: 16),
                          _buildGroupInfoCard(),
                          SizedBox(height: 16),
                          _buildProgressInfoCard(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF4F6F52),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Stack(
                children: [
                  // Photo de profil avec bordure animée
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 57,
                        backgroundColor: Color(0xFF4F6F52).withOpacity(0.1),
                        backgroundImage: currentUser?.profileImage != null
                            ? NetworkImage(currentUser!.profileImage!)
                            : null,
                        child: currentUser?.profileImage == null
                            ? Icon(
                                Icons.person,
                                size: 55,
                                color: Color(0xFF4F6F52),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Bouton pour changer la photo
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: isUploadingPhoto ? null : _pickAndUploadImage,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[100]!],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isUploadingPhoto
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4F6F52),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Color(0xFF4F6F52),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  currentUser?.fullName ?? 'الطالب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F6F52),
                      Color(0xFF6B8F71),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(Icons.badge, 'الاسم الكامل', currentUser?.fullName ?? '-'),
          SizedBox(height: 16),
          _buildInfoRow(Icons.cake, 'العمر', '${currentUser?.age ?? '-'} سنة'),
          SizedBox(height: 16),
          _buildInfoRow(Icons.phone, 'الهاتف', currentUser?.phone ?? '-'),
          SizedBox(height: 16),
          _buildInfoRow(Icons.location_city, 'المدينة', currentUser?.city ?? 'غير محدد'),
          SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F6F52),
                      Color(0xFF6B8F71),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'معلومات المجموعة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (!hasGroup)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لم يتم تعيينك لمجموعة بعد',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سيتم إضافتك قريباً',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildInfoRow(Icons.group, 'اسم المجموعة', userGroup!.name),
            SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'الأستاذ المشرف', profName),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.people,
              'عدد الطلاب',
              '${userGroup!.currentStudentsCount}/${userGroup!.maxStudents}',
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4F6F52).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF4F6F52).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Color(0xFF4F6F52),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'أوقات الحصص',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F6F52),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...userGroup!.schedule.map((slot) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Color(0xFF4F6F52),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slot.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F6F52),
                      Color(0xFF6B8F71),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'تقدم الحفظ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem('الحفظ السابق', oldHafd, Colors.grey),
              Container(
                width: 2,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildProgressItem('الحفظ الجديد', newHafd, Colors.green),
              Container(
                width: 2,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildProgressItem('المجموع', totalHafd, Colors.blue),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F6F52).withOpacity(0.1),
                  Color(0xFF6B8F71).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'النسبة المئوية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6F52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: MediaQuery.of(context).size.width * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4F6F52),
                              Color(0xFF6B8F71),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4F6F52).withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'من القرآن الكريم',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
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
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF4F6F52).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF4F6F52).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4F6F52).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF4F6F52), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}