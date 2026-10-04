import 'dart:async';

import 'package:flutter/material.dart';
import 'package:venera_next/components/loading.dart';
import 'package:venera_next/components/navigation_bar.dart';
import 'package:venera_next/components/pull_to_refresh.dart';
import 'package:venera_next/components/pop_up_widget.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/components/wallpaper.dart';
import 'package:venera_next/features/comic_widgets/comic_widgets.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/features/comic_source/comic_source.dart';
import 'package:venera_next/foundation/global_state.dart';
import 'package:venera_next/foundation/res.dart';
import 'package:venera_next/routing/page_jump_target.dart';
import 'package:venera_next/foundation/extensions.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';
import 'package:venera_next/features/settings/settings.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin<ExplorePage> {
  /// 当前展示的探索页标题,通过右上角按钮打开选择页切换。
  String? current;

  List<String> get allExplorePages => ComicSource.all()
      .map((e) => e.explorePages.map((e) => e.title).toList())
      .expand((e) => e)
      .toList();

  String currentDefault(List<String> all) {
    var explorePages = List<String>.from(appdata.settings["explore_pages"]);
    explorePages = explorePages.where((e) => all.contains(e)).toList();
    if (explorePages.isNotEmpty) return explorePages.first;
    return all.first;
  }

  void onSettingsChanged() {
    var all = allExplorePages;
    if (current != null && !all.contains(current)) {
      setState(() {
        current = all.isEmpty ? null : currentDefault(all);
      });
    }
  }

  void onNaviItemTapped(int index) {
    if (index == 2 && current != null) {
      GlobalState.find<_SingleExplorePageState>(current!).toTop();
    }
  }

  NaviPaneState? naviPane;

  @override
  void initState() {
    var all = allExplorePages;
    if (all.isNotEmpty) {
      current = currentDefault(all);
    }
    appdata.settings.addListener(onSettingsChanged);
    NaviPane.of(context).addNaviItemTapListener(onNaviItemTapped);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    naviPane = NaviPane.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    appdata.settings.removeListener(onSettingsChanged);
    naviPane?.removeNaviItemTapListener(onNaviItemTapped);
    super.dispose();
  }

  void refresh() {
    if (current != null) {
      GlobalState.find<_SingleExplorePageState>(current!).refresh();
    }
  }

  Widget buildBody(String i) => Material(
    color: Wallpapers.enabled ? Colors.transparent : null,
    child: _SingleExplorePage(i, key: PageStorageKey(i)),
  );

  Widget buildEmpty() {
    var msg = "No Explore Pages".tl;
    msg += '\n';
    msg += "Please add some sources".tl;
    return NetworkError(
      message: msg,
      retry: () {
        context.to(() => const ComicSourcePage());
      },
      withAppbar: false,
      buttonText: "Manage".tl,
    );
  }

  void openSelector() {
    showPopUpWidget(
      App.rootContext,
      _ExplorePageSelector(
        current: current,
        onSelect: (title) {
          if (mounted) {
            setState(() => current = title);
          }
        },
      ),
    );
  }

  Widget buildTopBar() {
    final scheme = Theme.of(context).colorScheme;
    var source = ComicSource.all().firstWhere(
      (e) => e.explorePages.any((e) => e.title == current),
    );
    return Material(
      color: Wallpapers.enabled ? Colors.transparent : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              width: 0.6,
            ),
          ),
        ),
        padding: EdgeInsets.only(top: context.padding.top),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 6),
              Tooltip(
                message: "Select Page".tl,
                child: IconButton(
                  icon: const Icon(Icons.dashboard_outlined),
                  onPressed: openSelector,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current!.ts(source.key),
                  style: ts.s18.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var all = allExplorePages;
    if (all.isEmpty) {
      return buildEmpty();
    }
    current ??= currentDefault(all);

    return Column(
      children: [
        buildTopBar(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: buildBody(current!),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 探索页选择器:列出所有源的探索页面,点选切换。
class _ExplorePageSelector extends StatelessWidget {
  const _ExplorePageSelector({required this.current, required this.onSelect});

  final String? current;

  final void Function(String title) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var sources = ComicSource.all()
        .where((e) => e.explorePages.isNotEmpty)
        .toList();
    return PopUpWidgetScaffold(
      title: "Explore".tl,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final source in sources) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                source.name.toUpperCase(),
                style: ts.s12
                    .copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    )
                    .copyWith(letterSpacing: 1.2),
              ),
            ),
            for (final page in source.explorePages)
              ListTile(
                title: Text(page.title.ts(source.key)),
                trailing: page.title == current
                    ? Icon(Icons.check, color: scheme.primary, size: 20)
                    : null,
                onTap: () {
                  onSelect(page.title);
                  context.pop();
                },
              ),
          ],
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text("Explore Settings".tl),
            onTap: () {
              context.pop();
              context.to(() => const SettingsPage(initialPage: 0));
            },
          ),
        ],
      ),
    );
  }
}

class _SingleExplorePage extends StatefulWidget {
  const _SingleExplorePage(this.title, {super.key});

  final String title;

  @override
  State<_SingleExplorePage> createState() => _SingleExplorePageState();
}

class _SingleExplorePageState extends AutomaticGlobalState<_SingleExplorePage>
    with AutomaticKeepAliveClientMixin<_SingleExplorePage> {
  late final ExplorePageData data;

  late final String comicSourceKey;

  bool _wantKeepAlive = true;

  var scrollController = ScrollController();

  VoidCallback? refreshHandler;

  VoidCallback? reloadHandler;

  void onDataChanged() {
    reloadHandler?.call();
  }

  @override
  void initState() {
    super.initState();
    for (var source in ComicSource.all()) {
      for (var d in source.explorePages) {
        if (d.title == widget.title) {
          data = d;
          comicSourceKey = source.key;
          data.changeListenable?.addListener(onDataChanged);
          return;
        }
      }
    }
    throw "Explore Page ${widget.title} Not Found!";
  }

  @override
  void dispose() {
    data.changeListenable?.removeListener(onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget body;
    if (data.loadMultiPart != null) {
      body = _MultiPartExplorePage(
        key: const PageStorageKey("comic_list"),
        data: data,
        controller: scrollController,
        comicSourceKey: comicSourceKey,
        refreshHandlerCallback: (c) {
          refreshHandler = c;
        },
      );
    } else if (data.loadPage != null || data.loadNext != null) {
      body = ComicList(
        enablePageStorage: true,
        loadPage: data.loadPage,
        loadNext: data.loadNext,
        key: const PageStorageKey("comic_list"),
        controller: scrollController,
        refreshHandlerCallback: (c) {
          refreshHandler = c;
        },
        reloadHandlerCallback: (c) {
          reloadHandler = c;
        },
      );
    } else if (data.loadMixed != null) {
      body = _MixedExplorePage(
        data,
        comicSourceKey,
        key: const PageStorageKey("comic_list"),
        controller: scrollController,
        refreshHandlerCallback: (c) {
          refreshHandler = c;
        },
      );
    } else {
      return Center(child: Text("Empty Page".tl));
    }
    return PullToRefresh(onRefresh: _onRefresh, child: body);
  }

  @override
  Object? get key => widget.title;

  Future<void> _onRefresh() async {
    final onRefresh = data.onRefresh;
    if (onRefresh == null) {
      refreshHandler?.call();
      await Future.delayed(const Duration(milliseconds: 350));
      return;
    }
    await onRefresh();
    reloadHandler?.call();
  }

  @override
  void refresh() {
    unawaited(_onRefresh());
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  void toTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
}

class _MixedExplorePage extends StatefulWidget {
  const _MixedExplorePage(
    this.data,
    this.sourceKey, {
    super.key,
    this.controller,
    required this.refreshHandlerCallback,
  });

  final ExplorePageData data;

  final String sourceKey;

  final ScrollController? controller;

  final void Function(VoidCallback c) refreshHandlerCallback;

  @override
  State<_MixedExplorePage> createState() => _MixedExplorePageState();
}

class _MixedExplorePageState
    extends MultiPageLoadingState<_MixedExplorePage, Object> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.refreshHandlerCallback(refresh);
  }

  void refresh() {
    reset();
  }

  Iterable<Widget> buildSlivers(BuildContext context, List<Object> data) sync* {
    List<Comic> cache = [];
    for (var part in data) {
      if (part is ExplorePagePart) {
        if (cache.isNotEmpty) {
          yield SliverGridComics(comics: (cache));
          yield const SliverToBoxAdapter(child: Divider());
          cache.clear();
        }
        yield* _buildExplorePagePart(part, widget.sourceKey);
        yield const SliverToBoxAdapter(child: Divider());
      } else {
        cache.addAll(part as List<Comic>);
      }
    }
    if (cache.isNotEmpty) {
      yield SliverGridComics(comics: (cache));
    }
  }

  @override
  Widget buildContent(BuildContext context, List<Object> data) {
    return SmoothCustomScrollView(
      controller: widget.controller,
      slivers: [
        ...buildSlivers(context, data),
        const SliverListLoadingIndicator(),
      ],
    );
  }

  @override
  Future<Res<List<Object>>> loadData(int page) async {
    var res = await widget.data.loadMixed!(page);
    if (res.error) {
      return res;
    }
    for (var element in res.data) {
      if (element is! ExplorePagePart && element is! List<Comic>) {
        return const Res.error("function loadMixed return invalid data");
      }
    }
    return res;
  }
}

Iterable<Widget> _buildExplorePagePart(
  ExplorePagePart part,
  String sourceKey,
) sync* {
  Widget buildTitle(ExplorePagePart part) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
          child: Row(
            children: [
              Text(
                part.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (part.viewMore != null)
                TextButton(
                  onPressed: () {
                    var context = App.mainNavigatorKey!.currentContext!;
                    part.viewMore!.jump(context);
                  },
                  child: Text("View more".tl),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildComics(ExplorePagePart part) {
    return SliverGridComics(comics: part.comics);
  }

  yield buildTitle(part);
  yield buildComics(part);
}

class _MultiPartExplorePage extends StatefulWidget {
  const _MultiPartExplorePage({
    super.key,
    required this.data,
    required this.controller,
    required this.comicSourceKey,
    required this.refreshHandlerCallback,
  });

  final ExplorePageData data;

  final ScrollController controller;

  final String comicSourceKey;

  final void Function(VoidCallback c) refreshHandlerCallback;

  @override
  State<_MultiPartExplorePage> createState() => _MultiPartExplorePageState();
}

class _MultiPartExplorePageState extends State<_MultiPartExplorePage> {
  late final ExplorePageData data;

  List<ExplorePagePart>? parts;

  bool loading = true;

  String? message;

  Map<String, dynamic> get state => {
    "loading": loading,
    "message": message,
    "parts": parts,
  };

  void restoreState(dynamic state) {
    if (state == null) return;
    loading = state["loading"];
    message = state["message"];
    parts = state["parts"];
  }

  void storeState() {
    PageStorage.of(context).writeState(context, state);
  }

  void refresh() {
    setState(() {
      loading = true;
      message = null;
      parts = null;
    });
    storeState();
  }

  @override
  void initState() {
    super.initState();
    data = widget.data;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    restoreState(PageStorage.of(context).readState(context));
    widget.refreshHandlerCallback(refresh);
  }

  void load() async {
    var res = await data.loadMultiPart!();
    loading = false;
    if (mounted) {
      setState(() {
        if (res.error) {
          message = res.errorMessage;
        } else {
          parts = res.data;
        }
      });
      storeState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      load();
      return const Center(child: CircularProgressIndicator());
    } else if (message != null) {
      return NetworkError(
        message: message!,
        retry: () {
          setState(() {
            loading = true;
            message = null;
          });
        },
        withAppbar: false,
      );
    } else {
      return buildPage();
    }
  }

  Widget buildPage() {
    return SmoothCustomScrollView(
      key: const PageStorageKey('scroll'),
      controller: widget.controller,
      slivers: _buildPage().toList(),
    );
  }

  Iterable<Widget> _buildPage() sync* {
    for (var part in parts!) {
      yield* _buildExplorePagePart(part, widget.comicSourceKey);
    }
  }
}
