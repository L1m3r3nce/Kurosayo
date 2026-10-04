import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:venera_next/components/gesture.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/features/comic_details/comic_details.dart';
import 'package:venera_next/features/comic_source/comic_source.dart';
import 'package:venera_next/features/comic_widgets/comic_widgets.dart';
import 'package:venera_next/features/favorites/favorites.dart';
import 'package:venera_next/features/follow_updates/follow_updates.dart';
import 'package:venera_next/features/history/history.dart';
import 'package:venera_next/features/image_favorites/image_favorites.dart';
import 'package:venera_next/features/local_comics/local_comics.dart';
import 'package:venera_next/features/search/search.dart';
import 'package:venera_next/features/settings/settings.dart';
import 'package:venera_next/features/sync/sync.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/consts.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget widget = SmoothCustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: context.padding.top)),
        const SliverToBoxAdapter(child: _TelegramSearchBar()),
        const _QuickAccess(),
        const _ContinueReading(),
        const SyncStatusSummary(),
        SliverPadding(padding: EdgeInsets.only(top: context.padding.bottom)),
      ],
    );
    if (context.width > changePoint) {
      widget = widget.paddingHorizontal(8);
    }
    return Stack(
      children: [
        Positioned.fill(child: widget),
        const MascotPet(),
      ],
    );
  }
}

/// 可拖动的看板娘桌宠:待机时上下浮动,点击有果冻弹跳和随机台词。
class MascotPet extends StatefulWidget {
  const MascotPet({super.key});

  @override
  State<MascotPet> createState() => _MascotPetState();
}

class _MascotPetState extends State<MascotPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  AnimationController? jelly;

  Offset? position;

  String? bubbleText;

  Timer? bubbleTimer;

  static const petSize = Size(110, 124);

  static const lines = [
    '今天要看什么漫画呀?',
    '嘿嘿,又见面啦~',
    '喜欢的漫画记得加收藏哦',
    '探索页右上角可以换源了',
    '别盯着我看啦,快去看漫画',
    '可以把我拖到顺手的位置哦',
  ];

  @override
  void initState() {
    super.initState();
    var saved = appdata.implicitData['mascotPosition'];
    if (saved is List && saved.length == 2) {
      position = Offset(
        (saved[0] as num).toDouble(),
        (saved[1] as num).toDouble(),
      );
    }
  }

  @override
  void dispose() {
    idle.dispose();
    jelly?.dispose();
    bubbleTimer?.cancel();
    super.dispose();
  }

  void onTap() {
    jelly?.dispose();
    jelly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    setState(() {
      bubbleText = lines[math.Random().nextInt(lines.length)];
    });
    bubbleTimer?.cancel();
    bubbleTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => bubbleText = null);
      }
    });
  }

  void onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      var pos =
          (position ?? _defaultPosition(constraints)) + details.delta;
      position = Offset(
        pos.dx.clamp(0, constraints.maxWidth - petSize.width),
        pos.dy.clamp(0, constraints.maxHeight - petSize.height),
      );
    });
  }

  void onPanEnd(BoxConstraints constraints) {
    var pos = position ?? _defaultPosition(constraints);
    appdata.implicitData['mascotPosition'] = [
      pos.dx.clamp(0, constraints.maxWidth - petSize.width),
      pos.dy.clamp(0, constraints.maxHeight - petSize.height),
    ];
    appdata.writeImplicitData();
  }

  Offset _defaultPosition(BoxConstraints constraints) {
    return Offset(
      constraints.maxWidth - petSize.width - 12,
      constraints.maxHeight * 0.48,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pos = position ?? _defaultPosition(constraints);
        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              width: petSize.width,
              child: GestureDetector(
                onPanUpdate: (d) => onPanUpdate(d, constraints),
                onPanEnd: (_) => onPanEnd(constraints),
                onTap: onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bubbleText != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: petSize.width + 60,
                        ),
                        child: Text(
                          bubbleText!,
                          style: ts.s12.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    AnimatedBuilder(
                      animation: Listenable.merge([idle, jelly ?? idle]),
                      builder: (context, child) {
                        var dy = (idle.value * 2 - 1) * 6;
                        var scaleY = 1.0;
                        var j = jelly;
                        if (j != null && j.isAnimating) {
                          scaleY = 1 + 0.14 * math.sin(j.value * math.pi * 3) * (1 - j.value);
                        }
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: Transform.scale(
                            scaleX: 1 / scaleY,
                            scaleY: scaleY,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/mascot.png',
                        height: petSize.height,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Telegram 风格的搜索胶囊,替代原先的搜索入口卡片。
class _TelegramSearchBar extends StatelessWidget {
  const _TelegramSearchBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClickInkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.to(() => const SearchPage()),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                'Search'.tl,
                style: ts.s14.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Icon(Icons.tune, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 扁平快速入口磁贴,替代原先堆叠的摘要卡片。
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    final manager = LocalFavoritesManager();
    return SliverToBoxAdapter(
      child: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final readLaterReady = manager.readLaterFolder != null;
          final tiles = [
            (
              icon: Icons.history,
              color: const Color(0xFF2AABEE),
              label: 'History'.tl,
              onTap: () => context.to(() => const HistoryPage()),
            ),
            (
              icon: Icons.watch_later_outlined,
              color: const Color(0xFF7E5CE6),
              label: 'Read later'.tl,
              onTap: readLaterReady
                  ? () => context.to(() => const ReadLaterPage())
                  : null,
            ),
            (
              icon: Icons.folder_outlined,
              color: const Color(0xFFF59E0B),
              label: 'Local'.tl,
              onTap: () => context.to(() => const LocalComicsPage()),
            ),
            (
              icon: Icons.update,
              color: const Color(0xFF26A269),
              label: 'Follow Updates'.tl,
              onTap: () => context.to(() => FollowUpdatesPage()),
            ),
            (
              icon: Icons.image_outlined,
              color: const Color(0xFFEC407A),
              label: 'Gallery'.tl,
              onTap: () => context.to(() => const ImageFavoritesPage()),
            ),
            (
              icon: Icons.extension_outlined,
              color: const Color(0xFF22B8CF),
              label: 'Sources'.tl,
              onTap: () => context.to(() => const ComicSourcePage()),
            ),
            (
              icon: Icons.settings_outlined,
              color: const Color(0xFF8B8D8F),
              label: 'Settings'.tl,
              onTap: () => context.to(() => const SettingsPage()),
            ),
          ];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 0,
              runSpacing: 14,
              children: [
                for (final tile in tiles)
                  _QuickTile(
                    icon: tile.icon,
                    color: tile.color,
                    label: tile.label,
                    onTap: tile.onTap,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return SizedBox(
      width: (context.width - 32) / 4,
      child: ClickInkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: ts.s12.copyWith(color: scheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "继续阅读"横向封面条,直接读取历史记录,不再套卡片容器。
class _ContinueReading extends StatefulWidget {
  const _ContinueReading();

  @override
  State<_ContinueReading> createState() => _ContinueReadingState();
}

class _ContinueReadingState extends State<_ContinueReading> {
  late List<History> history;

  void onChange() {
    if (mounted) {
      setState(() {
        history = HistoryManager().getRecent();
      });
    }
  }

  @override
  void initState() {
    history = HistoryManager().getRecent();
    HistoryManager().addListener(onChange);
    LocalFavoritesManager().addListener(onChange);
    super.initState();
  }

  @override
  void dispose() {
    HistoryManager().removeListener(onChange);
    LocalFavoritesManager().removeListener(onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    final scheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Continue Reading'.tl.toUpperCase(),
                  style: ts.s12
                      .copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      )
                      .copyWith(letterSpacing: 1.2),
                ),
                const Spacer(),
                ClickInkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.to(() => const HistoryPage()),
                  child: Row(
                    children: [
                      Text(
                        '${HistoryManager().count()}',
                        style: ts.s12.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 148,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final heroID = history[index].id.hashCode;
                return SimpleComicTile(
                  comic: history[index],
                  heroID: heroID,
                  gaplessPlayback: true,
                  onTap: () {
                    context.to(
                      () => ComicPage(
                        id: history[index].id,
                        sourceKey: history[index].type.sourceKey,
                        cover: history[index].cover,
                        title: history[index].title,
                        heroID: heroID,
                      ),
                    );
                  },
                ).paddingHorizontal(6);
              },
            ),
          ),
        ],
      ),
    );
  }
}
