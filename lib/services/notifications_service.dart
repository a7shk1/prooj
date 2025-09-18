// lib/services/notifications_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'matches_channel',
    'Matches',
    description: 'Live match notifications',
    importance: Importance.high,
  );

  /// لازم تكون Top-level أو موسومة بهالـ pragma عشان تشتغل بالخلفية
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // ممكن تضيف لوج لو تحب
    if (kDebugMode) {
      print('📥 [BG] ${message.notification?.title} - ${message.notification?.body}');
    }
  }

  static Future<void> init() async {
    // Local notifications init
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: initAndroid);
    await _local.initialize(initSettings);

    // قناة أندرويد
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // فورجراوند: اعرض إشعار محلي
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final ntf = msg.notification;
      if (ntf != null) {
        await _local.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ntf.title ?? 'Notification',
          ntf.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'matches_channel',
              'Matches',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      if (kDebugMode) {
        print('📥 [FG] ${ntf?.title} - ${ntf?.body}');
      }
    });

    // فتح الإشعار من الخلفية/المغلّق (اختياري للتعامل مع الضغط)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (kDebugMode) {
        print('🔁 onMessageOpenedApp: ${msg.notification?.title}');
      }
    });
  }

  static Future<void> requestPermission() async {
    // iOS + Android 13+
    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (kDebugMode) print('🔐 permission: ${settings.authorizationStatus}');
  }

  static Future<String?> getToken() => _messaging.getToken();

  static Future<void> subscribeToMatchesTopic() async {
    await _messaging.subscribeToTopic('matches');
    if (kDebugMode) print('✅ subscribed to topic: matches');
  }

  static Future<void> unsubscribeFromMatchesTopic() async {
    await _messaging.unsubscribeFromTopic('matches');
  }
}
