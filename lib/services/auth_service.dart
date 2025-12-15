// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// LOGIN avec email et mot de passe
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Connexion Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Récupérer les données utilisateur depuis Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'المستخدم غير موجود في قاعدة البيانات'
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Vérifier si le compte est actif
      if (userData['isActive'] == false) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'الحساب معطل، يرجى التواصل مع الإدارة'
        };
      }

      return {
        'success': true,
        'user': userCredential.user,
        'userData': userData,
        'role': userData['role'],
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'البريد الإلكتروني غير مسجل';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;
        case 'user-disabled':
          message = 'الحساب معطل';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة، يرجى المحاولة لاحقاً';
          break;
        default:
          message = 'حدث خطأ: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// INSCRIPTION (pour l'admin uniquement)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
    int? age,
    int? oldHafd,
    int? newHafd,
    String? groupId,
    String? city,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Préparer les données de base
      Map<String, dynamic> userData = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Ajouter les champs spécifiques selon le rôle
      if (role == 'etudiant') {
        userData['age'] = age ?? 0;
        userData['oldHafd'] = oldHafd ?? 0;
        userData['newHafd'] = newHafd ?? 0;
        userData['totalHafd'] = (oldHafd ?? 0) + (newHafd ?? 0);
        userData['groupId'] = groupId;  // Peut être null
        userData['dateInscription'] = FieldValue.serverTimestamp();
      }

      if (city != null && city.isNotEmpty) {
        userData['city'] = city;
      }

      // Créer le document dans Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'تم إنشاء الحساب بنجاح'
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'weak-password':
          message = 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;
        default:
          message = 'حدث خطأ: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// DÉCONNEXION
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// RÉINITIALISER MOT DE PASSE
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك'
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'البريد الإلكتروني غير مسجل';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;
        default:
          message = 'حدث خطأ: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  /// VÉRIFIER SI L'UTILISATEUR EST CONNECTÉ
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// OBTENIR L'UID DE L'UTILISATEUR ACTUEL
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}