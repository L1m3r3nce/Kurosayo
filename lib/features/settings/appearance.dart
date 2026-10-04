import 'dart:io';

import 'package:flutter/material.dart';
import 'package:venera_next/components/appbar.dart';
import 'package:venera_next/components/scroll.dart';
import 'package:venera_next/components/wallpaper.dart';
import 'package:venera_next/features/settings/setting_components.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Personalize".tl)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SkinPreviewCard(),
          ),
        ),
        SettingPartTitle(title: "Wallpaper".tl, icon: Icons.wallpaper),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SkinSelector(onChanged: () => setState(() {})),
          ),
        ),
        SliderSetting(
          title: "Semi-transparency".tl,
          settingsIndex: 'wallpaperOpacity',
          interval: 0.05,
          min: 0,
          max: 0.8,
          onChanged: () => App.forceRebuild(),
          valueFormatter: (v) => "${(v * 100).round()}%",
        ).toSliver(),
        SettingPartTitle(title: "Theme".tl, icon: Icons.palette),
        SelectSetting(
          title: "Theme Mode".tl,
          settingKey: "theme_mode",
          optionTranslation: {
            "system": "System".tl,
            "light": "Light".tl,
            "dark": "Dark".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Theme Color".tl,
          settingKey: "color",
          optionTranslation: {
            "system": "System".tl,
            "telegram": "Telegram",
            "red": "Red".tl,
            "pink": "Pink".tl,
            "purple": "Purple".tl,
            "green": "Green".tl,
            "orange": "Orange".tl,
            "blue": "Blue".tl,
          },
          onChanged: () async {
            await App.init();
            App.forceRebuild();
          },
        ).toSliver(),
      ],
    );
  }
}

class _SkinPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: const WallpaperPreview(),
      ),
    );
  }
}

class _SkinSelector extends StatelessWidget {
  const _SkinSelector({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    var current = Wallpapers.mode;
    var colors = Theme.of(context).colorScheme;

    Widget tile(String mode, String label, {Widget? preview, IconData? icon}) {
      final selected = current == mode;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: colors.surfaceContainerHighest,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (mode == 'image') {
                  var ok = await Wallpapers.pickImage(context);
                  if (!ok) return;
                } else {
                  await Wallpapers.applySkin(mode);
                }
                onChanged();
              },
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (preview != null)
                      preview
                    else
                      ColoredBox(color: colors.surface),
                    if (icon != null)
                      Center(
                        child: Icon(
                          icon,
                          size: 28,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.check_circle,
                            color: colors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('none', "None".tl, icon: Icons.format_color_reset),
        tile(
          'bili',
          "Bilibili Pink".tl,
          preview: const WallpaperLayer(mode: 'bili'),
        ),
        tile(
          'kurosayo',
          "Kurosayo Blue".tl,
          preview: const WallpaperLayer(mode: 'kurosayo'),
        ),
        tile(
          'image',
          "Custom image".tl,
          preview: Wallpapers.hasImage && Wallpapers.imagePath != null
              ? Image.file(File(Wallpapers.imagePath!), fit: BoxFit.cover)
              : null,
          icon: Icons.add_photo_alternate_outlined,
        ),
      ],
    );
  }
}
