import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../core/m3u_parser.dart';

class ChannelsRepository {
  static const playlistUrl =
      'https://cdn.jsdelivr.net/gh/a7shk1/m3u-broadcast@main/playlist.m3u';

  Future<List<Channel>> fetchChannels() async {
    final res = await http.get(Uri.parse(playlistUrl));
    if (res.statusCode != 200) {
      throw Exception("فشل بجلب playlist: ${res.statusCode}");
    }
    final text = utf8.decode(res.bodyBytes);
    return parseM3U(text);
  }
}
