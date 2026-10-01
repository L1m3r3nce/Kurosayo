import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/file_interaction.dart';
import 'package:venera_next/foundation/log.dart';
import 'package:venera_next/foundation/translations.dart';
import 'package:venera_next/foundation/widget_utils.dart';

/// Wallpaper modes for the personalization ("装扮") feature.
///
/// - `none`: no wallpaper, fully opaque surfaces.
/// - `bili`: built-in cream-pink skin with yellow confetti (bilibili style).
/// - `kurosayo`: built-in deep blue-cyan skin.
/// - `image`: user-picked image stored under `${App.dataPath}/wallpaper/`.
class Wallpapers {
  static bool get enabled => appdata.settings['wallpaperMode'] != 'none';

  static String get mode => appdata.settings['wallpaperMode'] ?? 'none';

  /// Opacity of the surface-colored veil painted over the wallpaper so that
  /// content stays readable (the "semi-transparent" effect).
  static double get veil {
    var v = appdata.settings['wallpaperOpacity'];
    if (v is num) return v.clamp(0.0, 0.8).toDouble();
    return 0.35;
  }

  static String? get imagePath => appdata.implicitData['wallpaperImagePath'];

  static final Map<String, bool> _imageExists = {};

  static bool get hasImage {
    var path = imagePath;
    if (path == null) return false;
    return _imageExists.putIfAbsent(path, () => File(path).existsSync());
  }

  static Future<void> setMode(String mode) async {
    appdata.settings['wallpaperMode'] = mode;
    await appdata.saveData();
    App.forceRebuild();
  }

  /// Applies a full skin: wallpaper mode plus its suggested theme color.
  static Future<void> applySkin(String mode) async {
    appdata.settings['wallpaperMode'] = mode;
    if (mode == 'bili') {
      appdata.settings['color'] = 'pink';
    } else if (mode == 'kurosayo') {
      appdata.settings['color'] = 'blue';
    }
    await appdata.saveData();
    await App.init();
    App.forceRebuild();
  }

  /// Lets the user pick an image, copies it into the app data directory and
  /// enables `image` mode. Returns whether a wallpaper was set.
  static Future<bool> pickImage(BuildContext context) async {
    var res = await selectFile(ext: const ['png', 'jpg', 'jpeg', 'webp']);
    if (res == null) return false;
    try {
      var dir = Directory("${App.dataPath}/wallpaper");
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      var ext = res.path.split(".").last.toLowerCase();
      var target = "${dir.path}/current.$ext";
      await File(res.path).copy(target);
      appdata.implicitData['wallpaperImagePath'] = target;
      appdata.writeImplicitData();
      _imageExists[target] = true;
      appdata.settings['wallpaperMode'] = 'image';
      await appdata.saveData();
      App.forceRebuild();
      return true;
    } catch (e, s) {
      Log.error("Wallpaper", "Failed to set wallpaper: $e", s);
      if (context.mounted) {
        context.showMessage(message: "Failed to load wallpaper".tl);
      }
      return false;
    }
  }
}

/// The wallpaper layer (painters / image) without the readability veil.
class WallpaperLayer extends StatelessWidget {
  const WallpaperLayer({super.key, this.mode});

  /// `null` renders the current mode from settings.
  final String? mode;

  @override
  Widget build(BuildContext context) {
    return switch (mode ?? Wallpapers.mode) {
      'bili' => const CustomPaint(
        painter: BiliConfettiPainter(),
        size: Size.infinite,
      ),
      'kurosayo' => const CustomPaint(
        painter: KurosayoWavePainter(),
        size: Size.infinite,
      ),
      'image' =>
        Wallpapers.hasImage && Wallpapers.imagePath != null
            ? Image.file(
                File(Wallpapers.imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              )
            : const SizedBox(),
      _ => const SizedBox(),
    };
  }
}

/// Full wallpaper background: layer + semi-transparent veil.
/// Renders [child] directly when wallpapers are disabled.
class AppWallpaper extends StatelessWidget {
  const AppWallpaper({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!Wallpapers.enabled) {
      return child ?? const SizedBox();
    }
    return Stack(
      children: [
        const Positioned.fill(child: WallpaperLayer()),
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(
              context,
            ).colorScheme.surface.toOpacity(Wallpapers.veil),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

/// Preview used by the personalization settings page: a wallpaper layer with
/// the veil and the app mascot in a white circular badge.
class WallpaperPreview extends StatelessWidget {
  const WallpaperPreview({super.key, this.mode, this.veil});

  final String? mode;

  final double? veil;

  @override
  Widget build(BuildContext context) {
    var v = veil ?? Wallpapers.veil;
    return Stack(
      children: [
        Positioned.fill(child: WallpaperLayer(mode: mode)),
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface.toOpacity(v),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const ClipOval(
                  child: Image(
                    image: AssetImage('assets/app_icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Kurosayo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cream-pink background with scattered yellow triangle confetti,
/// in the style of bilibili's pink personal skin.
class BiliConfettiPainter extends CustomPainter {
  const BiliConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var bg = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8F9), Color(0xFFFFEAF0), Color(0xFFFFDEE8)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = bg);

    var rng = Random(42);
    for (var i = 0; i < 6; i++) {
      var c = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawCircle(
        c,
        40 + rng.nextDouble() * 90,
        Paint()..color = const Color(0xFFFFC9D9).withValues(alpha: 0.22),
      );
    }

    const yellows = [Color(0xFFFFD866), Color(0xFFF5D98A), Color(0xFFE8C458)];
    for (var i = 0; i < 36; i++) {
      var cx = rng.nextDouble() * size.width;
      var cy = rng.nextDouble() * size.height;
      var w = 6.0 + rng.nextDouble() * 9;
      var rot = rng.nextDouble() * pi * 2;
      var paint = Paint()
        ..color = yellows[i % 3].withValues(
          alpha: 0.5 + rng.nextDouble() * 0.4,
        );
      var path = Path()
        ..moveTo(0, -w)
        ..lineTo(w * 0.87, w * 0.5)
        ..lineTo(-w * 0.87, w * 0.5)
        ..close();
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    for (var i = 0; i < 14; i++) {
      var c = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawCircle(
        c,
        1.2 + rng.nextDouble() * 1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Deep blue-cyan gradient with flowing waves and starlight,
/// matching the Kurosayo brand look.
class KurosayoWavePainter extends CustomPainter {
  const KurosayoWavePainter();

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var bg = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1633), Color(0xFF0E2A52), Color(0xFF0F3D63)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = bg);

    _glow(
      canvas,
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.32,
      const Color(0xFF19C2E8).withValues(alpha: 0.30),
    );
    _glow(
      canvas,
      Offset(size.width * 0.12, size.height * 0.88),
      size.width * 0.30,
      const Color(0xFF1B4F9E).withValues(alpha: 0.35),
    );

    const waves = [Color(0xFF1FB6DE), Color(0xFF2A9FD6), Color(0xFF3E8BC9)];
    for (var i = 0; i < 3; i++) {
      var y0 = size.height * (0.58 + i * 0.13);
      var y1 = size.height * (0.66 + i * 0.11);
      var path = Path()
        ..moveTo(0, y0)
        ..cubicTo(
          size.width * 0.3,
          y0 - size.height * 0.08,
          size.width * 0.6,
          y1 + size.height * 0.06,
          size.width,
          y1,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = waves[i].withValues(alpha: 0.20 + i * 0.06),
      );
    }

    var rng = Random(7);
    for (var i = 0; i < 42; i++) {
      var c = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.8,
      );
      canvas.drawCircle(
        c,
        0.6 + rng.nextDouble() * 1.4,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.3 + rng.nextDouble() * 0.5,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
