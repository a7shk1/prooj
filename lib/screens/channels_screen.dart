import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../data/channels.dart';
import '../data/channels_repository.dart';
import '../models/channel.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final repo = ChannelsRepository();
  List<Channel> channels = [];
  bool isLoading = true;
  String? error;

  static const String _playerPackage = 'com.varplayer.app';
  static const String _scheme = 'varplayer';
  static const String _host = 'play';

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final fetched = await repo.fetchChannels();
      setState(() {
        channels = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "فشل الاتصال، حاول لاحقاً.";
        isLoading = false;
      });
    }
  }

  Map<String, String> _buildQualityLinks(String masterUrl) {
    final base = masterUrl.replaceAll("master.m3u8", "");
    return {
      "240p": "${base}stream_0/playlist.m3u8",
      "480p": "${base}stream_1/playlist.m3u8",
      "1080p": "${base}stream_2/playlist.m3u8",
    };
  }

  Future<void> _openInVarPlayer({
    required String url,
    required String quality,
    required String name,
  }) async {
    try {
      final token = base64Url.encode(utf8.encode(url));
      final uri = Uri(
        scheme: _scheme,
        host: _host,
        queryParameters: {'t': token, 'q': quality, 'n': name},
      );
      final intent = AndroidIntent(
        action: 'action_view',
        data: uri.toString(),
        package: _playerPackage,
      );
      await intent.launch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر فتح VAR Player")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(error!,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Channels"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          final logo = ChannelData.channels[index]["logo"]!;
          final name = ChannelData.channels[index]["name"]!;
          final links = _buildQualityLinks(channel.url);

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        logo,
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.tv, size: 40),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: links.entries.map((entry) {
                      return ElevatedButton(
                        onPressed: () => _openInVarPlayer(
                          url: entry.value,
                          quality: entry.key,
                          name: name,
                        ),
                        child: Text(entry.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
