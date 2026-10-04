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
import 'package:venera_next/foundation/consts.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var widget = SmoothCustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: context.padding.top)),
        const SliverToBoxAdapter(child: _TelegramSearchBar()),
        const _QuickAccess(),
        const _ContinueReading(),
        const SyncStatusSummary(),
        SliverPadding(padding: EdgeInsets.only(top: context.padding.bottom)),
      ],
    );
    return context.width > changePoint ? widget.paddingHorizontal(8) : widget;
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
                  'Continue Reading'.tl,
                  style: ts.s12
                      .copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      )
                      .copyWith(letterSpacing: 0.2),
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
