import 'dart:convert';
import '../models/channel.dart';

List<Channel> parseM3U(String content) {
  final lines = const LineSplitter()
      .convert(content)
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  List<Channel> out = [];
  String? name;

  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];

    if (l.startsWith('#EXTINF')) {
      // نجيب الاسم بعد الفاصلة
      final idx = l.indexOf(',');
      if (idx >= 0) {
        name = l.substring(idx + 1).trim();
        // نشيل [H265] إذا موجودة
        name = name.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      }
    } else if (l.startsWith('http')) {
      if (name != null) {
        out.add(Channel(name: name, url: l));
      }
      name = null;
    }
  }
  return out;
}
