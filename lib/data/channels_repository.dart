import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/channel.dart';
import '../core/m3u_parser.dart';

class ChannelsRepository {
  // الدالة العامة: تجيب قنوات من أي رابط m3u
  Future<List<Channel>> fetchChannelsFromUrl(String playlistUrl) async {
    final res = await http.get(Uri.parse(playlistUrl));
    if (res.statusCode != 200) {
      throw Exception("فشل بجلب playlist: ${res.statusCode}");
    }
    final text = utf8.decode(res.bodyBytes);
    return parseM3U(text); // يرجّع List<Channel>(name,url) من بارسرك الحالي
  }
}
