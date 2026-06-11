import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.initializeFirebase();
}

class NotificationService {
  const NotificationService._();

  static bool _firebaseReady = false;

  static Future<void> initializeFirebase() async {
    if (_firebaseReady || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;
    } catch (error) {
      debugPrint('[Solex] Firebase nao configurado: $error');
    }
  }

  static Future<void> registerDevice({
    required ApiClient apiClient,
    required String token,
  }) async {
    await initializeFirebase();

    if (!_firebaseReady) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final deviceToken = await messaging.getToken();

      if (deviceToken == null || deviceToken.isEmpty) {
        return;
      }

      await apiClient.registerNotificationDevice(
        token: token,
        deviceToken: deviceToken,
        platform: defaultTargetPlatform.name,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        apiClient
            .registerNotificationDevice(
              token: token,
              deviceToken: newToken,
              platform: defaultTargetPlatform.name,
            )
            .catchError((error) {
          debugPrint('[Solex] Falha ao atualizar token FCM: $error');
        });
      });
    } catch (error) {
      debugPrint('[Solex] Falha ao registrar notificacoes: $error');
    }
  }
}
