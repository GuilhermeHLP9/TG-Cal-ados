import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.initializeFirebase();
}

class NotificationService {
  const NotificationService._();

  static const _channel = AndroidNotificationChannel(
    'solex_orders',
    'Pedidos e clientes',
    description: 'Avisos sobre pedidos, clientes e atualizacoes do Solex.',
    importance: Importance.high,
  );

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _firebaseReady = false;
  static bool _localReady = false;
  static bool _listenersReady = false;

  static Future<void> initializeFirebase() async {
    if (_firebaseReady || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      await _initializeLocalNotifications();
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _listenForegroundMessages();
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

  static Future<void> _initializeLocalNotifications() async {
    if (_localReady) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(settings: initializationSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    _localReady = true;
  }

  static void _listenForegroundMessages() {
    if (_listenersReady) {
      return;
    }

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();

      if (title == null && body == null) {
        return;
      }

      _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title ?? 'Solex',
        body: body ?? 'Voce tem uma nova atualizacao.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'solex_orders',
            'Pedidos e clientes',
            channelDescription:
                'Avisos sobre pedidos, clientes e atualizacoes do Solex.',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });

    _listenersReady = true;
  }
}
