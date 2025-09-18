// main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notifications_service.dart';
import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart'; // GlobalBackground

// ✅ هاندلر الإشعارات بالخلفية لازم يكون Top-level ومعلّم entry-point
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // لازم تهيئة Firebase على الآيزوليت الخلفي
    await Firebase.initializeApp();
    // إذا عندك منطق إضافي، خلّه بسيط وبدون UI
    await NotificationsService.onBackgroundMessage(message);
  } catch (e, s) {
    debugPrint('BG handler error: $e\n$s');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 إظهار الأخطاء بدل السواد (مؤقتًا مفيد للتشخيص، تقدر تشيله بعد ما تضبط كلشي)
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.empty,
    );
  };

  ErrorWidget.builder = (FlutterErrorDetails d) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Flutter error:\n${d.exception}\n\n${d.stack}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
      );

  // (اختياري) قفل الاتجاه إن تحب
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ✅ تهيئة Firebase قبل استخدام أي خدمة
  try {
    await Firebase.initializeApp();
  } catch (e, s) {
    debugPrint('Firebase init error: $e\n$s');
  }

  // ✅ تسجيل الهاندلر الخلفي (لا تنتظر)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🚀 شغّل الواجهة فورًا
  runApp(const VarApp());

  // ⚡️ بعد أول فريم: شغّل الأشياء الشبكية حتى ما تعرقل الإقلاع
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anon sign-in error: $e');
    }

    try {
      await NotificationsService.init();
    } catch (e) {
      debugPrint('Notifications init error: $e');
    }

    try {
      await NotificationsService.requestPermission();
    } catch (e) {
      debugPrint('Notifications permission error: $e');
    }

    try {
      await NotificationsService.subscribeToMatchesTopic();
    } catch (e) {
      debugPrint('Subscribe topic error: $e');
    }

    try {
      final token = await NotificationsService.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Get token error: $e');
    }
  });
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // 👇 خلفية متحركة عالمية خلف كل الشاشات
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },

      // ✅ الراوتات الداخلية
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },

      // شاشة البداية
      home: const SplashScreen(),
    );
  }
}
