import 'dart:convert';
import '../models/channel.dart';

List<Channel> parseM3U(String content) {
  final lines = const LineSplitter()
      .convert(content)
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final List<Channel> out = [];
  String? name;

  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];

    if (l.startsWith('#EXTINF')) {
      final idx = l.indexOf(',');
      name = (idx >= 0 ? l.substring(idx + 1) : 'Channel').trim();
      name = name.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      name = name.replaceAll(RegExp(r'\s+'), ' ');
    } else if (RegExp(r'^(https?|rtmp|udp)://').hasMatch(l)) {
      if (name != null) {
        out.add(Channel(name: name, url: l));
      }
      name = null;
    }
  }
  return out;
}
