import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        // androidId مناسب للربط بجهاز
        return info.id ?? info.fingerprint ?? 'unknown-android';
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return info.identifierForVendor ?? 'unknown-ios';
      } else {
        final info = await _plugin.deviceInfo;
        return info.toMap().toString().hashCode.toString();
      }
    } catch (_) {
      return 'unknown-device';
    }
  }
}
