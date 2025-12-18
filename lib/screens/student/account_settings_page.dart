// lib/screens/student/account_settings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserModel? currentUser;
  bool isLoading = true;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUpdatingPhone = false;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
            _phoneController.text = currentUser?.phone ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePhone() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar('الرجاء إدخال رقم الهاتف', isError: true);
      return;
    }

    // Validation du format du numéro
    String phone = _phoneController.text.trim();
    if (phone.length < 8) {
      _showSnackBar('رقم الهاتف غير صحيح', isError: true);
      return;
    }

    setState(() => _isUpdatingPhone = true);

    try {
      await _firestore.collection('users').doc(currentUser!.id).update({
        'phone': phone,
      });

      await _loadUserData();
      _showSnackBar('تم تحديث رقم الهاتف بنجاح');
    } catch (e) {
      print('Erreur mise à jour téléphone: $e');
      _showSnackBar('حدث خطأ في تحديث رقم الهاتف', isError: true);
    } finally {
      setState(() => _isUpdatingPhone = false);
    }
  }

  Future<void> _updatePassword() async {
    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Validations
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('الرجاء ملء جميع الحقول', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('كلمة المرور الجديدة يجب أن تحتوي على 6 أحرف على الأقل', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('كلمة المرور الجديدة غير متطابقة', isError: true);
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        _showSnackBar('خطأ في المصادقة', isError: true);
        setState(() => _isUpdatingPassword = false);
        return;
      }

      // Ré-authentification avec l'ancien mot de passe
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Mise à jour du mot de passe
      await user.updatePassword(newPassword);

      // Effacer les champs
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSnackBar('تم تحديث كلمة المرور بنجاح');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ في تحديث كلمة المرور';
      
      if (e.code == 'wrong-password') {
        errorMessage = 'كلمة المرور الحالية غير صحيحة';
      } else if (e.code == 'weak-password') {
        errorMessage = 'كلمة المرور الجديدة ضعيفة جداً';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'الرجاء تسجيل الدخول مرة أخرى';
      }
      
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      print('Erreur mise à jour mot de passe: $e');
      _showSnackBar('حدث خطأ في تحديث كلمة المرور', isError: true);
    } finally {
      setState(() => _isUpdatingPassword = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        appBar: AppBar(
          title: Text('إعدادات الحساب'),
          backgroundColor: Color(0xFF4F6F52),
          elevation: 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUserInfoCard(),
                    SizedBox(height: 20),
                    _buildPhoneSection(),
                    SizedBox(height: 20),
                    _buildPasswordSection(),
                    SizedBox(height: 20),
                    _buildSecurityTips(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F6F52).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.fullName ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
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
                    colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: '12345678',
              prefixIcon: Icon(Icons.phone_android, color: Color(0xFF4F6F52)),
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
              fillColor: Color(0xFF4F6F52).withOpacity(0.05),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUpdatingPhone ? null : _updatePhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F6F52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isUpdatingPhone
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'حفظ رقم الهاتف',
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

  Widget _buildPasswordSection() {
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
                    colors: [Color(0xFF4F6F52), Color(0xFF6B8F71)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lock, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'تغيير كلمة المرور',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F6F52),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF4F6F52)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              fillColor: Color(0xFF4F6F52).withOpacity(0.05),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              hintText: '6 أحرف على الأقل',
              prefixIcon: Icon(Icons.lock, color: Color(0xFF4F6F52)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              fillColor: Color(0xFF4F6F52).withOpacity(0.05),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              prefixIcon: Icon(Icons.check_circle_outline, color: Color(0xFF4F6F52)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              fillColor: Color(0xFF4F6F52).withOpacity(0.05),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUpdatingPassword ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F6F52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isUpdatingPassword
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'تحديث كلمة المرور',
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

  Widget _buildSecurityTips() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'نصائح الأمان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSecurityTip(
            Icons.check_circle,
            'استخدم كلمة مرور قوية (6 أحرف على الأقل)',
          ),
          SizedBox(height: 10),
          _buildSecurityTip(
            Icons.check_circle,
            'لا تشارك كلمة المرور مع أي شخص',
          ),
          SizedBox(height: 10),
          _buildSecurityTip(
            Icons.check_circle,
            'قم بتغيير كلمة المرور بشكل دوري',
          ),
          SizedBox(height: 10),
          _buildSecurityTip(
            Icons.check_circle,
            'تأكد من رقم هاتفك للتواصل مع الإدارة',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}