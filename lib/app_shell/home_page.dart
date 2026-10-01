import 'package:flutter/material.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/features/comic_source/comic_source.dart';
import 'package:venera_next/foundation/consts.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/features/history/history.dart';
import 'package:venera_next/features/favorites/favorites.dart';
import 'package:venera_next/features/local_comics/local_comics.dart';
import 'package:venera_next/features/follow_updates/follow_updates.dart';
import 'package:venera_next/features/image_favorites/image_favorites.dart';
import 'package:venera_next/features/search/search.dart';
import 'package:venera_next/features/sync/sync.dart';
import 'package:venera_next/foundation/widget_utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var widget = SmoothCustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: context.padding.top)),
        const SearchEntry(),
        const HomeMascot(),
        const SyncStatusSummary(),
        const HistorySummary(),
        const ReadLaterSummary(),
        const LocalComicsSummary(),
        const FollowUpdatesWidget(),
        const ComicSourceSummary(),
        const ImageFavoritesSummary(),
        SliverPadding(padding: EdgeInsets.only(top: context.padding.bottom)),
      ],
    );
    return context.width > changePoint ? widget.paddingHorizontal(8) : widget;
  }
}

/// The mascot figure ("看板娘") shown at the top of the home page,
/// in the style of bilibili's personalized skin.
class HomeMascot extends StatefulWidget {
  const HomeMascot({super.key});

  @override
  State<HomeMascot> createState() => _HomeMascotState();
}

class _HomeMascotState extends State<HomeMascot>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var dy = (controller.value * 2 - 1) * 6;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Image.asset('assets/mascot.png', height: 170),
        ),
      ),
    );
  }
}
