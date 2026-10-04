import 'dart:io';

import 'package:flutter/material.dart';
import 'package:venera_next/components/gesture.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/file_interaction.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';
import 'package:venera_next/features/history/history.dart';
import 'package:venera_next/features/settings/about.dart';
import 'package:venera_next/features/settings/appearance.dart';
import 'package:venera_next/features/settings/local_favorites.dart';
import 'package:venera_next/features/settings/debug.dart';
import 'package:venera_next/features/settings/network.dart';
import 'package:venera_next/features/settings/explore_settings.dart';
import 'package:venera_next/features/settings/app.dart';
import 'package:venera_next/features/settings/reader.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({this.initialPage = -1, super.key});

  final int initialPage;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int currentPage = -1;

  ColorScheme get colors => Theme.of(context).colorScheme;

  bool get enableTwoViews => context.width > 720;

  final categories = <String>[
    "Explore",
    "Reading",
    "Reading statistics",
    "Personalize",
    "Local Favorites",
    "APP",
    "Network",
    "About",
    "Debug",
  ];

  final icons = <IconData>[
    Icons.explore_outlined,
    Icons.book_outlined,
    Icons.query_stats_outlined,
    Icons.auto_awesome_outlined,
    Icons.collections_bookmark_outlined,
    Icons.apps_outlined,
    Icons.public_outlined,
    Icons.info_outlined,
    Icons.bug_report_outlined,
  ];

  /// Telegram 设置页风格:每行一个独立的彩色圆角方块图标。
  final iconColors = <Color>[
    const Color(0xFF22B8CF), // Explore
    const Color(0xFF2AABEE), // Reading
    const Color(0xFF7E5CE6), // Reading statistics
    const Color(0xFFEC407A), // Personalize
    const Color(0xFFF59E0B), // Local Favorites
    const Color(0xFF8B8D8F), // APP
    const Color(0xFF26A269), // Network
    const Color(0xFF4DA3FF), // About
    const Color(0xFFE5484D), // Debug
  ];

  @override
  void initState() {
    currentPage = widget.initialPage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(child: buildBody());
  }

  Widget buildBody() {
    if (enableTwoViews) {
      return Row(
        children: [
          SizedBox(width: 280, height: double.infinity, child: buildLeft()),
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.colorScheme.outlineVariant,
                  width: 0.6,
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return LayoutBuilder(
                  builder: (context, constrains) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        var width = constrains.maxWidth;
                        var value = animation.isForwardOrCompleted
                            ? 1 - animation.value
                            : 1;
                        var left = width * value;
                        return Stack(
                          children: [
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: left,
                              width: width,
                              child: child,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              child: buildRight(),
            ),
          ),
        ],
      );
    } else {
      return buildLeft();
    }
  }

  Widget buildLeft() {
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Tooltip(
                  message: "Back".tl,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: context.pop,
                  ),
                ),
                const SizedBox(width: 24),
                Text("Settings".tl, style: ts.s20),
              ],
            ),
          ),
          if (!enableTwoViews) const _ProfileHeader(),
          Expanded(child: buildCategories()),
        ],
      ),
    );
  }

  Widget buildCategories() {
    Widget buildItem(String name, int id) {
      final bool selected = id == currentPage;

      Widget content = AnimatedContainer(
        key: ValueKey(id),
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceContainerHigh : null,
          borderRadius: enableTwoViews ? BorderRadius.circular(10) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColors[id],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icons[id], size: 18, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(name, style: ts.s16),
            const Spacer(),
            if (!enableTwoViews)
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
          ],
        ),
      );

      return Padding(
        padding: enableTwoViews
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
            : EdgeInsets.zero,
        child: ClickInkWell(
          borderRadius: enableTwoViews ? BorderRadius.circular(10) : null,
          onTap: () {
            if (enableTwoViews) {
              setState(() => currentPage = id);
            } else {
              context.to(() => _SettingsDetailPage(pageIndex: id));
            }
          },
          child: content,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      itemBuilder: (context, index) => buildItem(categories[index].tl, index),
    );
  }

  Widget buildRight() {
    if (currentPage == -1) {
      return const SizedBox();
    }
    return Navigator(
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return _buildSettingsContent(currentPage);
          },
          transitionDuration: Duration.zero,
        );
      },
    );
  }

  Widget _buildSettingsContent(int pageIndex) {
    return switch (pageIndex) {
      0 => const ExploreSettings(),
      1 => const ReaderSettings(),
      2 => const ReadingStatsPage(),
      3 => const AppearanceSettings(),
      4 => const LocalFavoritesSettings(),
      5 => const AppSettings(),
      6 => const NetworkSettings(),
      7 => const AboutSettings(),
      8 => const DebugPage(),
      _ => throw UnimplementedError(),
    };
  }
}

/// Telegram 设置页顶部的档案头:头像 + 名称 + 状态行。
/// 点击头像可自定义(从本地选图),长按恢复默认看板娘。
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  ImageProvider? _customAvatar;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void _loadAvatar() {
    var path = appdata.implicitData['avatarImagePath'];
    if (path is String && File(path).existsSync()) {
      _customAvatar = FileImage(File(path));
    } else {
      _customAvatar = null;
    }
  }

  Future<void> _pickAvatar() async {
    var res = await selectFile(
      ext: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    if (res == null) return;
    var dir = Directory("${App.dataPath}/avatar");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    for (var entity in dir.listSync()) {
      if (entity is File) {
        try {
          entity.deleteSync();
        } catch (_) {}
      }
    }
    var ext = res.path.split(".").last.toLowerCase();
    var target = "${dir.path}/current.$ext";
    await File(res.path).copy(target);
    appdata.implicitData['avatarImagePath'] = target;
    appdata.writeImplicitData();
    await FileImage(File(target)).evict();
    if (mounted) {
      setState(() => _loadAvatar());
    }
  }

  void _resetAvatar() {
    appdata.implicitData.remove('avatarImagePath');
    appdata.writeImplicitData();
    setState(() => _loadAvatar());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            onLongPress: _resetAvatar,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: scheme.surfaceContainerHigh,
              backgroundImage:
                  _customAvatar ?? const AssetImage('assets/mascot.png'),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Kurosayo", style: ts.s18),
              const SizedBox(height: 2),
              Text(
                "v${App.version}",
                style: ts.s12.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({required this.pageIndex});

  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Material(child: _buildPage());
  }

  Widget _buildPage() {
    return switch (pageIndex) {
      0 => const ExploreSettings(),
      1 => const ReaderSettings(),
      2 => const ReadingStatsPage(),
      3 => const AppearanceSettings(),
      4 => const LocalFavoritesSettings(),
      5 => const AppSettings(),
      6 => const NetworkSettings(),
      7 => const AboutSettings(),
      8 => const DebugPage(),
      _ => throw UnimplementedError(),
    };
  }
}
