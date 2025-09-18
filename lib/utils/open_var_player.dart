// lib/utils/open_var_player.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

/// يفتح VAR Player بنفس الآلية المستخدمة في ChannelsScreen
Future<void> openVarPlayer(
    BuildContext context, {
      required String url,
      required String name,
    }) async {
  const playerPackage = 'com.varplayer.app';
  const scheme = 'varplayer';
  const host = 'play';

  final token = base64Url.encode(utf8.encode(url));
  final uri = Uri(
    scheme: scheme,
    host: host,
    queryParameters: {
      't': token,
      'q': 'auto',
      'n': name,
    },
  );

  try {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: uri.toString(),
        package: playerPackage,
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      final playUrl = uri.toString();
      if (await canLaunchUrl(Uri.parse(playUrl))) {
        await launchUrl(Uri.parse(playUrl), mode: LaunchMode.externalApplication);
      } else {
        throw "VAR Player not installed";
      }
    } else {
      // منصات أخرى: جرّب الفتح الافتراضي
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تعذر فتح VAR Player")),
    );
  }
}
