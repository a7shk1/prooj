// lib/services/subscription_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const MethodChannel _platform = MethodChannel('var_app/device');

  static const String _devicesCollection = 'devices';
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _codesCollection = 'codes';

  static final _uuid = const Uuid();

  // ===== Helpers =====

  static String _generateDeviceId() => 'ANDR_${_uuid.v4()}';

  static Future<String?> _getAndroidIdFromPlatform() async {
    try {
      final id = await _platform.invokeMethod<String>('getAndroidId');
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
  }

  static Future<String> _getRawDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      final candidate = (a.id != null && a.id!.isNotEmpty)
          ? a.id!
          : '${a.brand ?? 'android'}_${a.model ?? 'unknown'}_${a.device ?? 'dev'}';
      return candidate;
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? (i.name ?? 'ios_unknown');
    } else {
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static Future<String> _deviceFingerprint() async {
    try {
      final info = DeviceInfoPlugin();
      String raw = '';

      if (Platform.isAndroid) {
        final androidId = await _getAndroidIdFromPlatform();
        if (androidId != null && androidId.isNotEmpty) {
          raw = 'android|$androidId';
        } else {
          final a = await info.androidInfo;
          final fallbackId = (a.id != null && a.id!.isNotEmpty)
              ? a.id!
              : '${a.brand ?? ''}_${a.model ?? ''}_${a.device ?? ''}';
          raw = 'android|$fallbackId|${a.brand ?? ''}|${a.model ?? ''}';
        }
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        final idfv = (i.identifierForVendor != null && i.identifierForVendor!.isNotEmpty)
            ? i.identifierForVendor!
            : (i.name ?? '');
        raw = 'ios|$idfv|${i.utsname.machine ?? ''}';
      } else {
        raw = 'unknown|${DateTime.now().millisecondsSinceEpoch}';
      }

      return sha256.convert(utf8.encode(raw)).toString();
    } catch (_) {
      return sha256
          .convert(utf8.encode('fallback_${DateTime.now().millisecondsSinceEpoch}'))
          .toString();
    }
  }

  static Future<String?> _getMappedDeviceId(String fingerprint) async {
    try {
      final doc = await _db.collection(_devicesCollection).doc(fingerprint).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['deviceId'] is String) {
          return data['deviceId'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _createMapping(
      String fingerprint,
      String deviceId,
      Transaction? tx,
      ) async {
    final docRef = _db.collection(_devicesCollection).doc(fingerprint);
    final payload = {
      'deviceId': deviceId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (tx != null) {
      tx.set(docRef, payload, SetOptions(merge: false));
    } else {
      await docRef.set(payload, SetOptions(merge: false));
    }
  }

  static Future<bool> _subscriptionExistsForDevice(String deviceId) async {
    try {
      final now = Timestamp.now();
      final candidates = [
        deviceId,
        '${deviceId}_trial',
        '${deviceId}_paid',
        'ANDR_$deviceId',
      ];
      for (final docId in candidates) {
        final snap = await _db.collection(_subscriptionsCollection).doc(docId).get();
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;
        if (data['active'] == true && data['endAt'] is Timestamp) {
          final endAt = data['endAt'] as Timestamp;
          if (endAt.compareTo(now) == 1) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ===== Small public utilities =====

  static Future<String?> getResolvedDeviceId() async {
    final fp = await _deviceFingerprint();
    return _getMappedDeviceId(fp);
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?>
  getActiveSubscriptionByDeviceId(String deviceId) async {
    final now = DateTime.now();
    final qs = await _db
        .collection(_subscriptionsCollection)
        .where('deviceId', isEqualTo: deviceId)
        .limit(25)
        .get();

    DocumentSnapshot<Map<String, dynamic>>? bestPaid;
    DocumentSnapshot<Map<String, dynamic>>? bestTrial;

    for (final doc in qs.docs) {
      final data = doc.data();
      if (data['active'] != true) continue;
      final ts = data['endAt'];
      if (ts is! Timestamp) continue;
      final end = ts.toDate();
      if (!end.isAfter(now)) continue;

      final type = data['type'] as String?;
      if (type == 'paid') {
        if (bestPaid == null ||
            ((bestPaid!.data()!['endAt'] as Timestamp).toDate().isBefore(end))) {
          bestPaid = doc;
        }
      } else if (type == 'trial') {
        if (bestTrial == null ||
            ((bestTrial!.data()!['endAt'] as Timestamp).toDate().isBefore(end))) {
          bestTrial = doc;
        }
      }
    }
    return bestPaid ?? bestTrial;
  }

  // ===== Main public API =====

  static Future<bool> hasActiveAccess() async {
    try {
      final doc = await getActiveSubscriptionDoc();
      return doc != null;
    } catch (_) {
      return false;
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?>
  getActiveSubscriptionDoc() async {
    try {
      final fingerprint = await _deviceFingerprint();
      final mapped = await _getMappedDeviceId(fingerprint);
      final now = Timestamp.now();

      final List<String> candidates = [];

      if (mapped != null && mapped.isNotEmpty) {
        candidates.add(mapped);
        candidates.add('${mapped}_paid');
        candidates.add('${mapped}_trial');
        candidates.add('ANDR_$mapped');
      }

      final raw = await _getRawDeviceId();
      if (raw.isNotEmpty) {
        candidates.add(raw);
        candidates.add('ANDR_$raw');
        candidates.add('${raw}_paid');
        candidates.add('${raw}_trial');
      }

      for (final docId in candidates) {
        if (docId.isEmpty) continue;
        final doc =
        await _db.collection(_subscriptionsCollection).doc(docId).get();
        if (!doc.exists) continue;
        final data = doc.data();
        if (data == null) continue;
        if (data['active'] == true && data['endAt'] is Timestamp) {
          final endAt = data['endAt'] as Timestamp;
          if (endAt.compareTo(now) == 1) return doc;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> activateWithCode({required String code}) async {
    final codeTrim = code.trim();
    final codeRef = _db.collection(_codesCollection).doc(codeTrim);

    try {
      await _db.runTransaction((tx) async {
        final codeSnap = await tx.get(codeRef);
        if (!codeSnap.exists) throw 'الكود غير موجود';
        final data = codeSnap.data() ?? {};
        if (data['active'] != true) throw 'الكود غير مفعل';
        final used = data['used'] == true;
        final bound = (data['boundDeviceId'] as String?);
        if (used && bound != null && bound.isNotEmpty) {
          throw 'الكود مستخدم على جهاز آخر';
        }

        final fingerprint = await _deviceFingerprint();
        String? deviceResolved = await _getMappedDeviceId(fingerprint);

        if (deviceResolved == null) {
          deviceResolved = _generateDeviceId();
          tx.set(
            _db.collection(_devicesCollection).doc(fingerprint),
            {
              'deviceId': deviceResolved,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': 'activateWithCode',
            },
            SetOptions(merge: false),
          );
        }

        final activeExists = await _subscriptionExistsForDevice(deviceResolved);
        if (activeExists) {
          final trialDocId = '${deviceResolved}_trial';
          final trialSnap =
          await tx.get(_db.collection(_subscriptionsCollection).doc(trialDocId));
          if (trialSnap.exists) {
            final trialData = trialSnap.data() ?? {};
            if (trialData['active'] == true) {
              tx.set(
                _db.collection(_subscriptionsCollection).doc(trialDocId),
                {
                  'active': false,
                  'notes':
                  '${trialData['notes'] ?? ''} (deactivated on paid activation)',
                  'endedBy': 'upgrade_to_paid',
                  'endedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            } else {
              throw 'يوجد اشتراك نشط لهذا الجهاز';
            }
          } else {
            throw 'يوجد اشتراك نشط لهذا الجهاز';
          }
        }

        final days =
        (data['durationDays'] is int) ? data['durationDays'] as int : 30;
        final now = Timestamp.now();
        final endAt =
        Timestamp.fromDate(DateTime.now().add(Duration(days: days)));

        tx.set(
          codeRef,
          {
            'used': true,
            'boundDeviceId': deviceResolved,
            'active': true,
            'boundAt': now,
          },
          SetOptions(merge: true),
        );

        final subRef =
        _db.collection(_subscriptionsCollection).doc('${deviceResolved}_paid');
        tx.set(
          subRef,
          {
            'deviceId': deviceResolved,
            'type': 'paid',
            'code': codeTrim,
            'startAt': now,
            'endAt': endAt,
            'active': true,
            'notes': '',
            'name': '',
            'createdAt': now,
          },
          SetOptions(merge: false),
        );
      });

      return null;
    } catch (err) {
      if (err is String) return err;
      return 'خطأ أثناء تفعيل الكود: $err';
    }
  }

  static Future<String?> startTrialOnce() async {
    try {
      final fingerprint = await _deviceFingerprint();
      final mapped = await _getMappedDeviceId(fingerprint);

      if (mapped != null) {
        final already = await _subscriptionExistsForDevice(mapped);
        if (already) return 'التجربة المجانية مستخدمة سابقًا لهذا الجهاز';
        return 'التجربة المجانية مستخدمة سابقًا لهذا الجهاز';
      }

      final newDeviceId = _generateDeviceId();
      final docId = '${newDeviceId}_trial';

      await _db.runTransaction((tx) async {
        final deviceDocRef = _db.collection(_devicesCollection).doc(fingerprint);
        final deviceDocSnap = await tx.get(deviceDocRef);
        if (deviceDocSnap.exists) {
          throw 'التجربة المجانية مستخدمة سابقًا لهذا الجهاز';
        }

        tx.set(
          deviceDocRef,
          {
            'deviceId': newDeviceId,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: false),
        );

        final now = Timestamp.now();
        final endAt =
        Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)));
        final subRef = _db.collection(_subscriptionsCollection).doc(docId);
        tx.set(
          subRef,
          {
            'deviceId': newDeviceId,
            'type': 'trial',
            'code': null,
            'startAt': now,
            'endAt': endAt,
            'active': true,
            'notes': 'Free trial (device-mapped)',
            'name': '',
            'createdAt': now,
          },
          SetOptions(merge: false),
        );
      });

      return null;
    } catch (err) {
      if (err is String) return err;
      return 'خطأ أثناء تفعيل التجربة: $err';
    }
  }

  // ===== Admin helpers =====

  static Stream<QuerySnapshot<Map<String, dynamic>>> adminStream() {
    return _db
        .collection(_subscriptionsCollection)
        .orderBy('endAt', descending: true)
        .snapshots();
  }

  static Future<void> updateSub(String docId, Map<String, dynamic> data) {
    return _db
        .collection(_subscriptionsCollection)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  static Future<void> createManual({
    required String deviceId,
    required String type, // 'paid' | 'trial'
    required DateTime start,
    required DateTime end,
    String name = '',
    String notes = '',
  }) async {
    await _db.collection(_subscriptionsCollection).doc('${deviceId}_$type').set({
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
