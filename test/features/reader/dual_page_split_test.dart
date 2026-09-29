import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera_next/features/reader/comic_image.dart';

void main() {
  group('dual page split helpers', () {
    test('detects wide images only', () {
      expect(shouldSplitWideImage(const Size(1200, 800)), isTrue);
      expect(shouldSplitWideImage(const Size(800, 1200)), isFalse);
      expect(shouldSplitWideImage(const Size(1000, 1000)), isFalse);
    });

    test('uses vertical display size for wide images', () {
      expect(
        splitWideImageDisplaySize(const Size(1200, 800)),
        const Size(600, 1600),
      );
      expect(
        splitWideImageDisplaySize(const Size(800, 1200)),
        const Size(800, 1200),
      );
    });

    test('puts right half first by default', () {
      expect(splitWideImageSourceRects(const Size(1200, 800), invert: false), [
        const Rect.fromLTWH(600, 0, 600, 800),
        const Rect.fromLTWH(0, 0, 600, 800),
      ]);
    });

    test('swaps split order when inverted', () {
      expect(splitWideImageSourceRects(const Size(1200, 800), invert: true), [
        const Rect.fromLTWH(0, 0, 600, 800),
        const Rect.fromLTWH(600, 0, 600, 800),
      ]);
    });
  });
}
