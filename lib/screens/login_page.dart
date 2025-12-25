// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';  // ⭐ AJOUTÉ
import 'admin/admin_page.dart';
import 'teacher_page.dart';
import 'student_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validation
    if (emailController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال البريد الإلكتروني', isError: true);
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال كلمة المرور', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tentative de connexion
      final result = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result['success']) {
        // ⭐ SAUVEGARDER LE FCM TOKEN ⭐
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FCMService().saveTokenToFirestore(user.uid);
          print('✅ FCM Token sauvegardé pour: ${user.uid}');
        }

        // Succès - Navigation selon le rôle
        String role = result['role'];
        
        if (!mounted) return;
        
        Widget page;
        switch (role) {
          case 'admin':
            page = AdminPage();
            break;
          case 'prof':
            page = TeacherPage();
            break;
          case 'etudiant':
            page = StudentPage();
            break;
          default:
            _showSnackBar('دور غير معروف', isError: true);
            setState(() => _isLoading = false);
            return;
        }

        // Navigation avec remplacement (pas de retour possible)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      } else {
        // Échec - Afficher le message d'erreur
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      print('❌ Erreur lors du login: $e');
      _showSnackBar('حدث خطأ أثناء تسجيل الدخول', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleForgotPassword() {
    if (emailController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال البريد الإلكتروني أولاً', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إعادة تعيين كلمة المرور',
          textAlign: TextAlign.right,
        ),
        content: Text(
          'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى:\n${emailController.text.trim()}',
          textAlign: TextAlign.right,
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
              Navigator.pop(ctx);
              final result = await _authService.resetPassword(
                emailController.text.trim(),
              );
              _showSnackBar(
                result['message'],
                isError: !result['success'],
              );
            },
            child: Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF6F3EE),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Titre
                Text(
                  'إِرْتَقِ',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F6F52),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'برنامج حفظ القرآن الكريم',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 50),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4F6F52), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(color: Color(0xFF4F6F52)),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Bouton Login
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F6F52),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
                        : Text(
                            'دخول',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}