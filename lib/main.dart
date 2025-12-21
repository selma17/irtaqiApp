import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ CORRECTION: Désactiver la persistence pour éviter les erreurs d'index
  // Cette ligne résout le problème "INTERNAL ASSERTION FAILED"
  try {
    await FirebaseFirestore.instance.clearPersistence();
    print("✅ Firestore persistence cleared");
  } catch (e) {
    print("⚠️ Could not clear persistence (normal on first run): $e");
  }
  
  // ✅ Configuration Firestore pour web
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false, // Désactiver la persistence
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  print("✅ Firebase initialized successfully!");
  
  runApp(IrtaqiApp());
}

class IrtaqiApp extends StatelessWidget {
  const IrtaqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إِرْتَقِ',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginPage(),
    );
  }
}