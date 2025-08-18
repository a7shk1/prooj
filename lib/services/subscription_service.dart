import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final _db = FirebaseFirestore.instance;

  /// تخزين الكاش محليًا (حتى لو ماكو نت يعرف إذا عنده وصول أو لا)
  static Future<void> _cacheAccess(bool allowed) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('hasAccess', allowed);
  }

  static Future<bool?> cachedAccess() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('hasAccess');
  }

  /// فحص إذا عنده اشتراك نشط (مدفوع أو تجربة)
  static Future<bool> hasActiveAccess(String deviceId) async {
    final now = Timestamp.now();
    final q = await _db
        .collection('subscriptions')
        .where('deviceId', isEqualTo: deviceId)
        .where('active', isEqualTo: true)
        .where('endAt', isGreaterThan: now)
        .limit(1)
        .get();

    final ok = q.docs.isNotEmpty;
    await _cacheAccess(ok);
    return ok;
  }

  /// تفعيل كود مدفوع (collection: codes)
  /// كل كود يحتوي: {active: true, used:false, durationDays:30}
  static Future<String?> activateWithCode({
    required String code,
    required String deviceId,
  }) async {
    final codeRef = _db.collection('codes').doc(code);
    final codeSnap = await codeRef.get();

    if (!codeSnap.exists) return 'الكود غير موجود';
    final data = codeSnap.data()!;
    if (data['active'] != true) return 'الكود غير مفعل';
    if (data['used'] == true && data['boundDeviceId'] != deviceId) {
      return 'الكود مستخدم على جهاز آخر';
    }

    final days = (data['durationDays'] is int) ? data['durationDays'] as int : 30;
    final now = Timestamp.now();
    final endAt = Timestamp.fromDate(now.toDate().add(Duration(days: days)));

    final subRef = _db.collection('subscriptions').doc('${deviceId}_paid');
    await subRef.set({
      'deviceId': deviceId,
      'type': 'paid',
      'code': code,
      'startAt': now,
      'endAt': endAt,
      'active': true,
      'notes': '',
      'name': '',
    }, SetOptions(merge: true));

    await codeRef.set({
      'used': true,
      'boundDeviceId': deviceId,
      'active': true,
    }, SetOptions(merge: true));

    await _cacheAccess(true);
    return null;
  }

  /// تجربة مجانية 7 أيام — مرة واحدة فقط لكل جهاز
  static Future<String?> startTrialOnce(String deviceId) async {
    final prev = await _db
        .collection('subscriptions')
        .where('deviceId', isEqualTo: deviceId)
        .where('type', isEqualTo: 'trial')
        .limit(1)
        .get();

    if (prev.docs.isNotEmpty) return 'التجربة المجانية مستخدمة سابقًا لهذا الجهاز';

    final now = Timestamp.now();
    final endAt = Timestamp.fromDate(now.toDate().add(const Duration(days: 7)));

    await _db.collection('subscriptions').doc('${deviceId}_trial').set({
      'deviceId': deviceId,
      'type': 'trial',
      'code': null,
      'startAt': now,
      'endAt': endAt,
      'active': true,
      'notes': 'Free trial',
      'name': '',
    });

    await _cacheAccess(true);
    return null;
  }

  /// ستريم خاص بالأدمن لعرض الاشتراكات كلها
  static Stream<QuerySnapshot<Map<String, dynamic>>> adminStream() {
    return _db
        .collection('subscriptions')
        .orderBy('endAt', descending: true)
        .snapshots();
  }

  /// تحديث اشتراك موجود
  static Future<void> updateSub(String docId, Map<String, dynamic> data) {
    return _db
        .collection('subscriptions')
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  /// إنشاء اشتراك يدوي من الـ Admin
  static Future<void> createManual({
    required String deviceId,
    required String type, // 'paid'|'trial'
    required DateTime start,
    required DateTime end,
    String name = '',
    String notes = '',
  }) async {
    await _db.collection('subscriptions').doc('${deviceId}_$type').set({
      'deviceId': deviceId,
      'type': type,
      'code': type == 'paid' ? 'manual' : null,
      'startAt': Timestamp.fromDate(start),
      'endAt': Timestamp.fromDate(end),
      'active': true,
      'name': name,
      'notes': notes,
    });
  }
}
