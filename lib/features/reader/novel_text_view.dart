import 'package:flutter/material.dart';

import 'package:venera_next/features/reader/reader_page.dart';
import 'package:venera_next/features/reader/scaffold.dart';

/// Text chapter (light novel) view.
class NovelTextView extends StatefulWidget {
  const NovelTextView({super.key});

  @override
  State<NovelTextView> createState() => _NovelTextViewState();
}

class _NovelTextViewState extends State<NovelTextView> {
  double fontSize = 18;

  ScrollController controller = ScrollController();

  List<Widget> _buildParagraphs(String text) {
    var reader = context.reader;
    var paragraphs = text
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    var style = TextStyle(fontSize: fontSize, height: 1.75, letterSpacing: 0.3);
    var children = <Widget>[];
    if (reader.novelTitle != null && reader.novelTitle!.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            reader.novelTitle!,
            style: TextStyle(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
      );
    }
    for (var p in paragraphs) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(p, style: style),
        ),
      );
    }
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            if (reader.chapter > 1)
              FilledButton.tonal(
                onPressed: () => reader.toPrevChapter(),
                child: const Text("上一章"),
              ),
            if (reader.chapter < reader.maxChapter)
              FilledButton.tonal(
                onPressed: () => reader.toNextChapter(),
                child: const Text("下一章"),
              ),
          ],
        ),
      ),
    );
    return children;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var reader = context.reader;
    var text = reader.novelText ?? "";
    return GestureDetector(
      onTap: () {
        context.readerScaffold.openOrClose();
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: controller,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildParagraphs(text),
              ),
            ),
          ),
          if (context.readerScaffold.isOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: () {
                          setState(() {
                            fontSize = (fontSize - 1).clamp(12, 32);
                          });
                        },
                      ),
                      Text("${fontSize.toInt()}"),
                      IconButton(
                        icon: const Icon(Icons.text_increase),
                        onPressed: () {
                          setState(() {
                            fontSize = (fontSize + 1).clamp(12, 32);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
