// lib/models/matches_models.dart
class TodayResponse {
  final String date;
  final String? sourceUrl;
  final List<MatchItem> matches;

  TodayResponse({
    required this.date,
    this.sourceUrl,
    required this.matches,
  });

  factory TodayResponse.fromJson(Map<String, dynamic> json) {
    final rawList = (json['matches'] as List? ?? []);
    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map(MatchItem.fromJson)
        .toList();

    return TodayResponse(
      date: json['date']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString(),
      matches: list,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'source_url': sourceUrl,
    'matches': matches.map((m) => m.toJson()).toList(),
  };
}

class MatchItem {
  /// ملاحظة: الحقول التالية مكيّفة مع JSON الذي أرسلته:
  /// home_team/away_team, kickoff_baghdad, channels_raw, status_text/result_text, *_logo, competition
  final String id;
  final String home;
  final String away;
  final String? homeLogo;
  final String? awayLogo;

  /// "HH:mm"
  final String timeBaghdad;

  /// كود الحالة (NS/LIVE/FT) إن وجد. إذا غير موجود نتركه 'NS' ونستخدم statusText للعرض.
  final String status;

  /// نص عربي مثل "جارية الان" / "انتهت" / "لم تبدأ بعد"
  final String? statusText;

  /// "2-1" أو "0-0"
  final String? resultText;

  /// قناة مفردة إذا توفّرت في المصدر (احتياطي)
  final String? channel;

  /// معلق إن وجد
  final String? commentator;

  final String? competition;

  /// القنوات كقائمة (تُملأ من channels_raw أو channels أو channel)
  final List<String> channelsRaw;

  MatchItem({
    required this.id,
    required this.home,
    required this.away,
    required this.homeLogo,
    required this.awayLogo,
    required this.timeBaghdad,
    required this.status,
    required this.statusText,
    required this.resultText,
    required this.channel,
    required this.commentator,
    required this.competition,
    required this.channelsRaw,
  });

  /// قناة أولى ملائمة للعرض السريع
  String? get firstChannel => channelsRaw.isNotEmpty ? channelsRaw.first : channel;

  factory MatchItem.fromJson(Map<String, dynamic> j) {
    // أسماء الحقول بين المصدرين:
    final home = (j['home_team'] ?? j['home'] ?? '').toString();
    final away = (j['away_team'] ?? j['away'] ?? '').toString();

    final timeBaghdad = (j['kickoff_baghdad'] ??
        j['time_baghdad'] ??
        '')
        .toString();

    // حاول ملء القنوات من أكثر من شكل
    final channelsRaw = _parseChannels(j);

    // قناة مفردة (للرجوع الاحتياطي)
    final singleChannel = (j['channel'] ?? '').toString().trim();
    final channel = singleChannel.isEmpty ? null : singleChannel;

    // كوّن id إذا مو موجود
    final id = (j['id'] ??
        '${home.isNotEmpty ? home : 'home'}-'
            '${away.isNotEmpty ? away : 'away'}-'
            '${timeBaghdad.isNotEmpty ? timeBaghdad : 'time'}')
        .toString();

    return MatchItem(
      id: id,
      home: home,
      away: away,
      homeLogo: _nullIfEmpty(j['home_logo']),
      awayLogo: _nullIfEmpty(j['away_logo']),
      timeBaghdad: timeBaghdad,
      status: (j['status'] ?? 'NS').toString(),
      statusText: _nullIfEmpty(j['status_text']),
      resultText: _nullIfEmpty(j['result_text']),
      channel: channel,
      commentator: _nullIfEmpty(j['commentator']),
      competition: _nullIfEmpty(j['competition']),
      channelsRaw: channelsRaw,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'home': home,
    'away': away,
    'home_logo': homeLogo,
    'away_logo': awayLogo,
    'time_baghdad': timeBaghdad,
    'status': status,
    'status_text': statusText,
    'result_text': resultText,
    'channel': channel,
    'commentator': commentator,
    'competition': competition,
    'channels_raw': channelsRaw,
  };

  // ======= Helpers =======

  static List<String> _parseChannels(Map<String, dynamic> j) {
    final out = <String>[];

    // 1) channels_raw (القائمة الأساسية في JSON الجديد)
    final cr = j['channels_raw'];
    if (cr is List) {
      for (final c in cr) {
        final s = c?.toString().trim();
        if (s != null && s.isNotEmpty) out.add(s);
      }
    } else if (cr is String && cr.trim().isNotEmpty) {
      out.addAll(_splitChannels(cr));
    }

    // 2) channels (لو موجودة)
    final chs = j['channels'];
    if (chs is List) {
      for (final c in chs) {
        final s = c?.toString().trim();
        if (s != null && s.isNotEmpty) out.add(s);
      }
    } else if (chs is String && chs.trim().isNotEmpty) {
      out.addAll(_splitChannels(chs));
    }

    // 3) channel المفرد (fallback)
    final ch = j['channel']?.toString().trim();
    if (ch != null && ch.isNotEmpty) out.add(ch);

    // إزالة التكرار مع الحفاظ على الترتيب (case-insensitive)
    final seen = <String>{};
    final unique = <String>[];
    for (final c in out) {
      final key = c.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(c);
      }
    }
    return unique;
  }

  static List<String> _splitChannels(String raw) {
    final parts = raw.split(RegExp(r'\s*(?:,|،|/|\||&| و | and )\s*', caseSensitive: false));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static String? _nullIfEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
