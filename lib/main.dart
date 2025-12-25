import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'services/fcm_service.dart';

// Handler pour messages en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Message background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    await FirebaseFirestore.instance.clearPersistence();
    print("✅ Firestore persistence cleared");
  } catch (e) {
    print("⚠️ Could not clear persistence: $e");
  }
  
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  print("✅ Firebase initialized successfully!");
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await FCMService().initializeFCM();
  
  runApp(IrtaqiApp());
}

class IrtaqiApp extends StatelessWidget {
  const IrtaqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // ✅ Pas de bannière DEBUG
      title: 'إِرْتَقِ',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      locale: Locale('ar', ''),
      theme: ThemeData(
        fontFamily: 'AmiriQuran',
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF4F6F52),
      ),
      home: LoginPage(),
    );
  }
}