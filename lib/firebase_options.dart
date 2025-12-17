// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        // إذا عندك Android شغال بالـ google-services.json تگدر تخليه،
        // أو هم تحط خيارات أندرويد إذا تريد.
        return android;
      default:
        return ios;
    }
  }

  // iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'حط_API_KEY_من_الplist',
    appId: 'حط_GOOGLE_APP_ID_من_الplist', // مثال: 1:...:ios:...
    messagingSenderId: 'حط_GCM_SENDER_ID_من_الplist',
    projectId: 'حط_PROJECT_ID_من_الplist',
    storageBucket: 'حط_STORAGE_BUCKET_من_الplist',
    iosBundleId: 'هنا_نقرر_اي_bundle_id_راح_نستخدم',
  );

  // Android (اختياري إذا تريد)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: 'dummy',
    projectId: 'dummy',
  );
}
