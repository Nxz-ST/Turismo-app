import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../legal_info.dart';

/// Muestra un documento legal empacado en la app (funciona sin conexión).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.asset,
  });

  const LegalDocumentScreen.terms({super.key})
    : title = 'Términos y condiciones',
      asset = LegalInfo.termsAsset;

  const LegalDocumentScreen.privacy({super.key})
    : title = 'Política de privacidad',
      asset = LegalInfo.privacyAsset;

  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo abrir el documento.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: MarkdownLite.render(snapshot.data!, skipTitle: true),
            ),
          );
        },
      ),
    );
  }
}

/// Renderizador mínimo para los textos legales: títulos, párrafos, listas,
/// citas, tablas (como tarjetas) y **negritas**. Evita sumar una dependencia.
class MarkdownLite {
  const MarkdownLite._();

  static List<Widget> render(String source, {bool skipTitle = false}) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];
    final paragraph = <String>[];
    final table = <List<String>>[];
    String? listItem;

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(_inline(paragraph.join(' ')), style: _body),
        ),
      );
      paragraph.clear();
    }

    void flushList() {
      if (listItem == null) return;
      final item = listItem!;
      final numbered = RegExp(r'^(\d+)\.\s+').firstMatch(item);
      final text = numbered != null
          ? item.substring(numbered.end)
          : item.replaceFirst(RegExp(r'^-\s+'), '');
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  numbered != null ? '${numbered.group(1)}.' : '•',
                  style: _body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(child: Text.rich(_inline(text), style: _body)),
            ],
          ),
        ),
      );
      listItem = null;
    }

    void flushTable() {
      if (table.isEmpty) return;
      final header = table.first;
      for (final row in table.skip(1)) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E3DA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  _inline(row.first),
                  style: _body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                for (var i = 1; i < row.length && i < header.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_plain(header[i])}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                          _inline(row[i]),
                        ],
                      ),
                      style: _body.copyWith(fontSize: 13.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 8));
      table.clear();
    }

    void flushAll() {
      flushParagraph();
      flushList();
      flushTable();
    }

    var titleSkipped = !skipTitle;
    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();
      if (trimmed.startsWith('|')) {
        flushParagraph();
        flushList();
        if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(trimmed)) continue;
        table.add(
          trimmed
              .substring(1, trimmed.length - 1)
              .split('|')
              .map((cell) => cell.trim())
              .toList(),
        );
        continue;
      }
      flushTable();
      if (trimmed.isEmpty) {
        flushParagraph();
        flushList();
        continue;
      }
      final heading = RegExp(r'^(#{1,4})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        flushAll();
        final level = heading.group(1)!.length;
        if (level == 1 && !titleSkipped) {
          titleSkipped = true;
          continue;
        }
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: level <= 2 ? 18 : 12, bottom: 8),
            child: Text(
              _plain(heading.group(2)!),
              style: TextStyle(
                fontSize: level <= 1 ? 24 : (level == 2 ? 19 : 16),
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
          ),
        );
        continue;
      }
      if (trimmed.startsWith('>')) {
        flushAll();
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              _inline(trimmed.replaceFirst(RegExp(r'^>\s?'), '')),
              style: _body,
            ),
          ),
        );
        continue;
      }
      if (RegExp(r'^(-|\d+\.)\s+').hasMatch(trimmed)) {
        flushParagraph();
        flushList();
        listItem = trimmed;
        continue;
      }
      if (listItem != null && raw.startsWith('  ')) {
        listItem = '$listItem $trimmed';
        continue;
      }
      flushList();
      paragraph.add(trimmed);
    }
    flushAll();
    return widgets;
  }

  static const _body = TextStyle(
    fontSize: 14.5,
    height: 1.5,
    color: Color(0xFF33463F),
  );

  static String _plain(String text) => text
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!);

  static TextSpan _inline(String text) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\([^)]*\)');
    var index = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        );
      }
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return TextSpan(children: spans);
  }
}
