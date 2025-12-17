// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notifications_service.dart';
import 'services/subscription_service.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';

import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا نخلي أي await يوقف رسم الواجهة
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    runApp(const VarApp());

    // نكمل التهيئة بعد ما ترسم أول فريم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAfterFirstFrame();
    });
  }, (error, stack) {
    debugPrint('ZONED ERROR: $error');
    debugPrint('$stack');
  });
}

Future<void> _bootstrapAfterFirstFrame() async {
  // 1) Firebase init بمهلة (Timeout) حتى ما يعلق iOS
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));

    // background handler (خليه بعد ما Firebase يجهز)
    FirebaseMessaging.onBackgroundMessage(
      NotificationsService.firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    debugPrint('Firebase init failed/timeout: $e');
    // نكمل بدون ما نعلّق المستخدم
  }

  // 2) تسجيل دخول مجهول
  try {
    await FirebaseAuth.instance.signInAnonymously()
        .timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('Anonymous sign-in failed/timeout: $e');
  }

  // 3) Notifications
  try {
    await NotificationsService.init().timeout(const Duration(seconds: 6));
    await NotificationsService.requestPermission();
    await NotificationsService.subscribeToMatchesTopic();
    await NotificationsService.getToken();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  // 4) Subscription check + navigation
  try {
    final hasAccess = await SubscriptionService.hasActiveAccess()
        .timeout(const Duration(seconds: 10));

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (hasAccess) {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
  } catch (e) {
    debugPrint('Subscription check failed/timeout: $e');
    // خليه يبقى على SplashScreen (بس لازم Splash تكون بيها UI مو سودة فارغة)
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
