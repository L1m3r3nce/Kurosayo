import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:venera_next/components/appbar.dart';
import 'package:venera_next/components/button.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/log.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';
import 'package:venera_next/network/app_dio.dart';

const _afdianUrl = "https://ifdian.net/a/cyril";

const _sources = [
  "https://cdn.jsdelivr.net/gh/CyrilPeng/venera-next@main/sponsors.json",
  "https://raw.githubusercontent.com/CyrilPeng/venera-next/main/sponsors.json",
];

enum SponsorKind { monthly, oneTime }

enum SponsorSection { featured, current, historical }

class Sponsor {
  const Sponsor({required this.name, required this.tier, required this.kind});

  factory Sponsor.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException("Sponsor must be an object");
    }
    var name = value["name"];
    var tier = value["tier"];
    var kind = value["kind"] ?? "monthly";
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException("Sponsor name must be a non-empty string");
    }
    if (tier is! int || !const {30, 80, 200}.contains(tier)) {
      throw const FormatException("Sponsor tier is invalid");
    }
    if (kind != "monthly" && kind != "oneTime") {
      throw const FormatException("Sponsor kind is invalid");
    }
    return Sponsor(
      name: name.trim(),
      tier: tier,
      kind: kind == "oneTime" ? SponsorKind.oneTime : SponsorKind.monthly,
    );
  }

  final String name;

  final int tier;

  final SponsorKind kind;
}

class SponsorCatalog {
  const SponsorCatalog({
    required this.featured,
    required this.current,
    required this.historical,
  });

  factory SponsorCatalog.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException("Sponsor catalog must be an object");
    }
    var sections = value["sections"];
    if (sections != null) {
      if (sections is! Map) {
        throw const FormatException("Sponsor sections must be an object");
      }
      return SponsorCatalog(
        featured: _parseList(sections["featured"], "featured"),
        current: _parseList(sections["current"], "current"),
        historical: _parseList(sections["historical"], "historical"),
      );
    }

    // Older published data used one flat list. Treat tier 200 as featured and
    // the remaining entries as current until the sectioned payload is loaded.
    var legacy = _parseList(value["sponsors"], "sponsors");
    return SponsorCatalog(
      featured: List.unmodifiable(
        legacy.where((sponsor) => sponsor.tier == 200),
      ),
      current: List.unmodifiable(
        legacy.where((sponsor) => sponsor.tier != 200),
      ),
      historical: const [],
    );
  }

  final List<Sponsor> featured;

  final List<Sponsor> current;

  final List<Sponsor> historical;

  bool get isEmpty => featured.isEmpty && current.isEmpty && historical.isEmpty;

  List<Sponsor> section(SponsorSection section) {
    return switch (section) {
      SponsorSection.featured => featured,
      SponsorSection.current => current,
      SponsorSection.historical => historical,
    };
  }

  static List<Sponsor> _parseList(Object? value, String field) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw FormatException("Sponsor section $field must be a list");
    }
    return List.unmodifiable(value.map(Sponsor.fromJson));
  }
}

class _TierStyle {
  const _TierStyle({required this.bold, required this.crown});

  final bool bold;

  final bool crown;
}

const _tierStyles = <int, _TierStyle>{
  200: _TierStyle(bold: true, crown: true),
  80: _TierStyle(bold: true, crown: false),
  30: _TierStyle(bold: false, crown: false),
};

typedef SponsorsLoader = Future<SponsorCatalog> Function();

class SponsorsPage extends StatefulWidget {
  const SponsorsPage({super.key, this.loader});

  final SponsorsLoader? loader;

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  late Future<SponsorCatalog> _sponsors;

  @override
  void initState() {
    super.initState();
    _sponsors = _loadSponsors();
  }

  Future<SponsorCatalog> _loadSponsors() {
    return widget.loader?.call() ?? _fetchSponsors();
  }

  Future<SponsorCatalog> _fetchSponsors() async {
    Object? lastError;
    for (var url in _sources) {
      try {
        var res = await AppDio().get(
          url,
          options: Options(headers: {"cache-time": "long"}),
        );
        if (res.statusCode == 200) {
          var data = res.data is String ? jsonDecode(res.data) : res.data;
          return SponsorCatalog.fromJson(data);
        }
      } catch (error, stackTrace) {
        lastError = error;
        Log.error(
          "Sponsors",
          "Failed to fetch sponsors from $url: $error",
          stackTrace,
        );
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    throw const FormatException("No sponsor source returned a valid response");
  }

  void _retry() {
    setState(() {
      _sponsors = _loadSponsors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Sponsors".tl)),
        FutureBuilder<SponsorCatalog>(
          future: _sponsors,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Failed to load sponsors".tl),
                      const SizedBox(height: 12),
                      Button.text(onPressed: _retry, child: Text("Retry".tl)),
                    ],
                  ),
                ),
              );
            }
            return SliverToBoxAdapter(
              child: _buildContent(
                snapshot.data ??
                    const SponsorCatalog(
                      featured: [],
                      current: [],
                      historical: [],
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(SponsorCatalog catalog) {
    var children = <Widget>[
      Text(
        "Thanks to all sponsors who support the continuous maintenance of VeneraNext."
            .tl,
        style: const TextStyle(fontSize: 14),
      ).paddingHorizontal(16).paddingTop(8),
    ];

    if (catalog.isEmpty) {
      children.add(Center(child: Text("No sponsors yet".tl).paddingAll(32)));
    } else {
      for (var section in SponsorSection.values) {
        var sponsors = catalog.section(section);
        if (sponsors.isEmpty) {
          continue;
        }
        children.add(_buildSectionHeader(section));
        children.add(_buildSponsorChips(sponsors));
      }
    }

    children.add(
      Center(
        child: Button.filled(
          onPressed: () => launchUrlString(_afdianUrl),
          child: Text("Support on Afdian".tl),
        ).paddingVertical(24),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ).paddingBottom(16);
  }

  Widget _buildSectionHeader(SponsorSection section) {
    var title = switch (section) {
      SponsorSection.featured => "Featured Sponsors",
      SponsorSection.current => "Current Sponsors",
      SponsorSection.historical => "Past Sponsors",
    };
    return Text(
      title.tl,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ).paddingHorizontal(16).paddingTop(20).paddingBottom(8);
  }

  Widget _buildSponsorChips(List<Sponsor> sponsors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var sponsor in sponsors)
              _buildChip(sponsor, constraints.maxWidth),
          ],
        );
      },
    ).paddingHorizontal(16);
  }

  Widget _buildChip(Sponsor sponsor, double maxWidth) {
    var colorScheme = context.colorScheme;
    var style =
        _tierStyles[sponsor.tier] ??
        const _TierStyle(bold: false, crown: false);
    var detail = sponsor.kind == SponsorKind.oneTime
        ? "One-time".tl
        : "Tier ¥@amount".tlParams({"amount": sponsor.tier.toString()});
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: style.crown
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (style.crown) const Text("👑"),
            Text(
              sponsor.name,
              style: TextStyle(
                fontWeight: style.bold ? FontWeight.w700 : FontWeight.normal,
                color: style.crown ? colorScheme.onPrimaryContainer : null,
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                fontSize: 12,
                color: style.crown
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
