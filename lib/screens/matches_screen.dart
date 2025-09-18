// lib/screens/matches_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/matches_service.dart';
import '../models/matches_models.dart';

// 🔗 نستخدم المابر ليتعرف على القناة
import '../utils/channel_mapper.dart';
// 🎬 نفس آلية الفتح المستخدمة في ChannelsScreen
import '../utils/open_var_player.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<TodayResponse> _future;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _future = MatchesService.fetch(); // يجلب دائمًا من RAW
    // تحديث تلقائي (تقدر تغيّرها إلى 5 دقائق إن تحب)
    _autoTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      setState(() => _future = MatchesService.fetch());
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final f = MatchesService.fetch();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<TodayResponse>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 12),
                Center(child: Text('خطأ في التحميل: ${snap.error}')),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _future = MatchesService.fetch()),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            );
          }

          final data = snap.data!;
          final list = data.matches;

          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Icon(Icons.sports_soccer, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('لا توجد مباريات لهذا اليوم')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _MatchCard(m: list[i]),
          );
        },
      ),
    );
  }
}

/// =======================
/// تطبيع الحالة + اللابل
/// =======================
String normalizeStatus(MatchItem m) {
  final raw = (m.status ?? '').trim().toUpperCase();
  final st = (m.statusText ?? '').trim();

  // لو النص العربي متوفّر، نعتمد عليه
  if (st.isNotEmpty) {
    if (st.contains('جارية')) return 'LIVE';
    if (st.contains('انتهت')) return 'FT';
    if (st.contains('لم تبدأ') || st.contains('لم تبدا')) return 'NS';
  }

  // وإلا نستخدم القيمة الخام إن كانت واحدة من المعروفة
  if (raw == 'LIVE' || raw == 'FT' || raw == 'NS') return raw;

  // افتراضي
  return raw.isNotEmpty ? raw : 'NS';
}

String statusLabel(MatchItem m) {
  // اعرض النص العربي إن موجود
  if ((m.statusText ?? '').isNotEmpty) return m.statusText!;
  switch ((m.status ?? '').toUpperCase()) {
    case 'LIVE':
      return 'جارية الآن';
    case 'FT':
      return m.resultText ?? 'انتهت';
    default:
      return 'لم تبدأ بعد';
  }
}

/// =======================
/// قنوات المباراة (يدعم channel / channels / channelsRaw)
/// =======================
List<String> getChannels(MatchItem m) {
  final out = <String>[];

  // نستخدم dynamic حتى ما نكسر الكومبايل لو الحقل غير موجود بالموديل
  final dyn = m as dynamic;

  try {
    final chs = dyn.channels;
    if (chs is List) {
      for (final c in chs) {
        final s = (c ?? '').toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
  } catch (_) {}

  try {
    final chsRaw = dyn.channelsRaw;
    if (chsRaw is List) {
      for (final c in chsRaw) {
        final s = (c ?? '').toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
  } catch (_) {}

  // fallback: channel المفرد
  if ((m.channel ?? '').trim().isNotEmpty) {
    out.add(m.channel!.trim());
  }

  // إزالة المكرر مع الحفاظ على الترتيب (case-insensitive)
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

String bestChannelLabel(MatchItem m) {
  final list = getChannels(m);
  if (list.isEmpty) return 'غير معروف';
  if (list.length == 1) return list.first;
  return '${list.first} +${list.length - 1}';
}

class _MatchCard extends StatelessWidget {
  final MatchItem m;
  const _MatchCard({required this.m});

  Future<void> _onOpen(BuildContext context) async {
    final channels = getChannels(m);

    // ماكو أي قناة → نفتح fallback مباشرة
    if (channels.isEmpty) {
      final playUrl = ChannelMapper.findUrl(m.channel) ?? ChannelMapper.fallback;
      await openVarPlayer(
        context,
        url: playUrl,
        name: m.channel ?? m.competition ?? 'Match',
      );
      return;
    }

    // قناة واحدة → نفس السلوك القديم
    if (channels.length == 1) {
      final ch = channels.first;
      final playUrl = ChannelMapper.findUrl(ch) ?? ChannelMapper.fallback;
      await openVarPlayer(
        context,
        url: playUrl,
        name: ch,
      );
      return;
    }

    // أكثر من قناة → اعرض قائمة اختيار (Bottom Sheet)
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 8,
            left: 8,
            right: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                'اختر القناة',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: channels.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ch = channels[i];
                    final resolved = ChannelMapper.findUrl(ch);
                    return ListTile(
                      leading: const Icon(Icons.tv),
                      title: Text(ch, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: resolved == null
                          ? const Text('لنك افتراضي', style: TextStyle(fontSize: 12))
                          : null,
                      trailing: const Icon(Icons.play_arrow_rounded),
                      onTap: () => Navigator.of(ctx).pop(ch),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.of(ctx).pop(null),
                icon: const Icon(Icons.close),
                label: const Text('إلغاء'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;

    final playUrl = ChannelMapper.findUrl(chosen) ?? ChannelMapper.fallback;
    await openVarPlayer(
      context,
      url: playUrl,
      name: chosen,
    );
  }

  Widget _centerStatus(MatchItem m, ThemeData theme) {
    final norm = normalizeStatus(m);

    if (norm == 'LIVE') {
      // ✅ شارة "مباشر" + نتيجة تحتها إذا متوفرة
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'مباشر',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if ((m.resultText ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              m.resultText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      );
    }

    if (norm == 'FT') {
      // ✅ شارة "انتهت" فوق + النتيجة الرقمية تحتها (إن وُجدت)
      final score = (m.resultText ?? '').trim();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'انتهت',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (score.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              score,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      );
    }

    // NS أو غيرها
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.timeBaghdad,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          statusLabel(m),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _onOpen(context),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ===== الصف العلوي: فريق | حالة | فريق =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamCol(
                      name: m.home,
                      logo: m.homeLogo,
                      alignEnd: false,
                    ),
                  ),
                  Flexible(
                    flex: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(child: _centerStatus(m, theme)),
                    ),
                  ),
                  Expanded(
                    child: _TeamCol(
                      name: m.away,
                      logo: m.awayLogo,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // ===== الصف السفلي: القناة | البطولة =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.tv,
                      text: bestChannelLabel(m),
                      // القناة عادة قصيرة؛ نخليها سطر واحد مع +N
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.emoji_events_outlined,
                      text: m.competition ?? '',
                      // ✅ البطولة تظهر كاملة وتلف لحد 3 أسطر بدون قص
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCol extends StatelessWidget {
  final String name;
  final String? logo;
  final bool alignEnd;
  const _TeamCol({required this.name, this.logo, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    final avatar = (logo == null || (logo?.isEmpty ?? true))
        ? const CircleAvatar(radius: 20, child: Icon(Icons.shield_outlined))
        : CircleAvatar(
      radius: 20,
      backgroundColor: Colors.transparent,
      backgroundImage: CachedNetworkImageProvider(logo!),
    );

    final text = Expanded(
      child: Text(
        name,
        maxLines: 2, // ✅ اسم الفريق يظهر كامل حتى سطرين
        softWrap: true,
        overflow: TextOverflow.visible,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment:
      alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [text, const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), text],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  final bool softWrap;
  final TextOverflow overflow;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
    this.softWrap = false,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: maxLines,
            softWrap: softWrap,
            overflow: overflow,
          ),
        ),
      ],
    );
  }
}
