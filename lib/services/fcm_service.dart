import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handler pour les messages en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Message reçu en background: ${message.notification?.title}');
}

class FCMService {
  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Instance de FirebaseMessaging
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialiser FCM
  Future<void> initializeFCM() async {
    try {
      print('🔍 Initialisation FCM...');

      // Demander la permission pour les notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔍 Authorization status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permission notifications accordée');
        
        // Récupérer et afficher le FCM Token
        String? token = await _messaging.getToken();
        print('=================================');
        print('📱 FCM TOKEN: $token');
        print('=================================');

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen((newToken) {
          print('🔄 Nouveau FCM Token: $newToken');
        });

        // Écouter les messages en foreground (app ouverte)
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handler pour les messages en background
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Configurer les options de présentation en foreground
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permission notifications provisoire');
      } else {
        print('❌ Permission notifications refusée');
      }

      print('✅ FCMService initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation FCM: $e');
    }
  }

  /// Gérer les messages reçus en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Message reçu en foreground:');
    print('  Titre: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    // Ici vous pouvez afficher un dialogue, une snackbar, etc.
    // Exemple:
    // showDialog(...);
    // ScaffoldMessenger.of(context).showSnackBar(...);
  }

  /// Récupérer le token FCM actuel
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  /// Supprimer le token FCM
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('✅ Token FCM supprimé');
    } catch (e) {
      print('❌ Erreur suppression token: $e');
    }
  }

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      print('❌ Erreur abonnement topic: $e');
    }
  }

  /// Sauvegarder le FCM Token dans Firestore
Future<void> saveTokenToFirestore(String userId) async {
  try {
    // Récupérer le token actuel
    String? token = await _messaging.getToken();
    
    if (token != null) {
      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'platform': 'android',
          }, SetOptions(merge: true)); // merge: true = ne pas écraser les autres champs
      
      print('✅ FCM Token sauvegardé pour l\'utilisateur: $userId');
    } else {
      print('❌ Token FCM null');
    }
  } catch (e) {
    print('❌ Erreur sauvegarde token: $e');
  }
}

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      print('❌ Erreur désabonnement topic: $e');
    }
  }
}