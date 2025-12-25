// lib/utils/validators.dart

class Validators {
  /// Validation email complète avec regex
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    
    // Regex pour valider le format email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    return null;
  }
  
  /// Validation téléphone (format tunisien)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    
    // Enlever les espaces
    String cleanPhone = value.trim().replaceAll(' ', '');
    
    // Regex pour numéro tunisien : +216XXXXXXXX ou 00216XXXXXXXX ou XXXXXXXX (8 chiffres)
    final phoneRegex = RegExp(r'^(\+216|00216)?[2-9]\d{7}$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'رقم الهاتف غير صالح';
    }
    
    return null;
  }
  
  /// Validation mot de passe
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    
    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تحتوي على $minLength أحرف على الأقل';
    }
    
    return null;
  }
  
  /// Validation mot de passe fort (pour les admins)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل';
    }
    
    // Vérifier qu'il y a au moins une lettre et un chiffre
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف واحد على الأقل';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    
    return null;
  }
  
  /// Validation nom/prénom
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName يجب أن يحتوي على حرفين على الأقل';
    }
    
    return null;
  }
  
  /// Validation âge
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال العمر';
    }
    
    int? age = int.tryParse(value);
    if (age == null) {
      return 'الرجاء إدخال رقم صحيح';
    }
    
    if (age < 5 || age > 100) {
      return 'العمر يجب أن يكون بين 5 و 100';
    }
    
    return null;
  }
  
  /// Validation nombre de حفظ
  static String? validateHafd(String? value, String type) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال $type';
    }
    
    int? hafd = int.tryParse(value);
    if (hafd == null) {
      return 'الرجاء إدخال رقم صحيح';
    }
    
    if (hafd < 0 || hafd > 30) {
      return '$type يجب أن يكون بين 0 و 30';
    }
    
    return null;
  }
}

// Fonction pour validation des entrées de jour (existante)
bool validateDayEntry(int from, int to, int maxAyah) {
  if (from < 1 || to < 1) return false;
  if (from > maxAyah || to > maxAyah) return false;
  if (to < from) return false;
  return true;
}