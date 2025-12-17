// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/notifications_service.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';

import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شغّل الواجهة فوراً
  runApp(const VarApp());

  // سوّي التهيئة بالخلفية بدون ما توقف التطبيق على شاشة سودة
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_postStartInit());
  });
}

Future<void> _postStartInit() async {
  // 1) Firebase init (بـ timeout حتى ما يعلّگ)
  bool firebaseOk = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    firebaseOk = true;
  } catch (_) {
    firebaseOk = false;
  }

  if (!firebaseOk) return;

  // 2) Background message handler (بعد Firebase)
  try {
    FirebaseMessaging.onBackgroundMessage(
      NotificationsService.firebaseMessagingBackgroundHandler,
    );
  } catch (_) {}

  // 3) Auth + Notifications (لا تخليها تمنع فتح الواجهة)
  try {
    await FirebaseAuth.instance.signInAnonymously()
        .timeout(const Duration(seconds: 8));
  } catch (_) {}

  // خلي الإشعارات غير حاجزة (حتى لو iOS ما يقبل Push بالسيدلود)
  unawaited(_initNotificationsSafely());
}

Future<void> _initNotificationsSafely() async {
  try {
    await NotificationsService.init()
        .timeout(const Duration(seconds: 6));
    await NotificationsService.requestPermission()
        .timeout(const Duration(seconds: 6));
    await NotificationsService.subscribeToMatchesTopic()
        .timeout(const Duration(seconds: 6));
    await NotificationsService.getToken()
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    // حتى لو فشلت، ما نوقف التطبيق
  }
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
