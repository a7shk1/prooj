import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart'; // 👈 جديد
import 'theme/app_theme.dart'; // 👈 ملف الثيم

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة Firebase
    await Firebase.initializeApp();

    // تسجيل دخول مجهول (كل جهاز يحصل UID فريد)
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint("Firebase init/auth error: $e");
  }

  runApp(const VarApp());
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // 👈 استخدام الثيم الجديد
      // ✅ الراوتات الداخلية
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(), // 👈 جديد
      },
      home: const SplashScreen(),
    );
  }
}
