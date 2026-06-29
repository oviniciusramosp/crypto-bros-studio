import 'package:flutter/material.dart';
import 'tokens.dart';

/// 1:1 preview of how a post renders in the app. Every size/spacing/color is
/// ported from the RN renderer (src/components/notion/blocks/*). Dark mode.
class LeanPreview extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;
  const LeanPreview({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2E),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          width: AppTokens.phoneWidth,
          decoration: BoxDecoration(
            color: AppTokens.bg,
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenPadding, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blocks.map(_block).toList(),
          ),
        ),
      ),
    );
  }

  // ---- inline spans ----
  TextSpan _spans(dynamic raw, TextStyle base) {
    final spans = (raw as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return TextSpan(
      children: spans.map((s) {
        if (s['emoji'] != null) return const TextSpan(text: '🖼️');
        var style = base;
        if (s['bold'] == true) style = style.copyWith(fontWeight: FontWeight.w600);
        if (s['italic'] == true) style = style.copyWith(fontStyle: FontStyle.italic);
        var decos = <TextDecoration>[];
        if (s['strikethrough'] == true) decos.add(TextDecoration.lineThrough);
        if (s['underline'] == true) decos.add(TextDecoration.underline);
        if (s['code'] == true) {
          style = style.copyWith(
            fontFamily: 'monospace',
            background: Paint()..color = AppTokens.inlineCodeBg,
          );
        }
        if (s['href'] != null) {
          style = style.copyWith(color: AppTokens.accent);
          decos.add(TextDecoration.underline);
          style = style.copyWith(decorationColor: AppTokens.linkUnderline);
        }
        if (decos.isNotEmpty) style = style.copyWith(decoration: TextDecoration.combine(decos));
        return TextSpan(text: s['text'] as String? ?? '', style: style);
      }).toList(),
    );
  }

  Widget _richText(dynamic spans, TextStyle base) => Text.rich(_spans(spans, base));

  // ---- blocks ----
  Widget _block(Map<String, dynamic> b) {
    switch (b['type']) {
      case 'p':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _richText(b['spans'], AppTokens.inter(size: 14, lineHeight: 22)),
        );
      case 'h':
        final level = (b['level'] as int?) ?? 1;
        final spec = level == 1
            ? [20.0, 26.0, FontWeight.w700, 24.0, 8.0]
            : level == 2
                ? [18.0, 24.0, FontWeight.w600, 20.0, 6.0]
                : [16.0, 22.0, FontWeight.w600, 16.0, 4.0];
        return Padding(
          padding: EdgeInsets.only(top: spec[3] as double, bottom: spec[4] as double),
          child: _richText(b['spans'], AppTokens.inter(size: spec[0] as double, lineHeight: spec[1] as double, weight: spec[2] as FontWeight)),
        );
      case 'list':
        final items = (b['items'] as List).cast<List>();
        final ordered = b['ordered'] == true;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: ordered ? 24 : 20,
                      height: 22,
                      child: Text(ordered ? '${i + 1}.' : '•', style: AppTokens.inter(size: 14, lineHeight: 22)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: _richText((items[i]).cast<Map<String, dynamic>>(), AppTokens.inter(size: 14, lineHeight: 22))),
                  ],
                ),
            ],
          ),
        );
      case 'todo':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20, height: 22,
                child: Icon(b['checked'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18, color: b['checked'] == true ? AppTokens.todoChecked : AppTokens.textTertiary),
              ),
              const SizedBox(width: 4),
              Expanded(child: _richText(b['spans'], AppTokens.inter(size: 14, lineHeight: 22))),
            ],
          ),
        );
      case 'quote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppTokens.accent, width: 3)),
          ),
          child: _richText(b['spans'], AppTokens.inter(size: 14, lineHeight: 22, italic: true, color: AppTokens.textSecondary)),
        );
      case 'callout':
        final inner = ((b['blocks'] as List?) ?? const []).cast<Map<String, dynamic>>();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTokens.calloutBg, borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: Text(b['icon'] as String? ?? '💡', style: const TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: inner.map(_block).toList())),
            ],
          ),
        );
      case 'code':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppTokens.codeHeaderBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(b['lang'] as String? ?? 'code', style: AppTokens.inter(size: 12, lineHeight: 16, color: AppTokens.textSecondary)),
              ),
              Container(
                color: AppTokens.codeBodyBg,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(b['text'] as String? ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 20 / 14, color: AppTokens.text)),
              ),
            ],
          ),
        );
      case 'divider':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(height: 1, child: ColoredBox(color: AppTokens.border)),
        );
      case 'image':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(b['src'] as String? ?? '', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTokens.surface)),
            ),
          ),
        );
      case 'video':
        return _mediaCard('▶  YouTube', AppTokens.textSecondary);
      case 'chart':
        final c = (b['chart'] as Map?) ?? const {};
        return _chartCard('${c['asset']} · ${c['chartType']} · ${c['timeRange'] ?? c['candleInterval'] ?? ''}');
      case 'price':
        final p = (b['price'] as Map?) ?? const {};
        return _chartCard('Preço · ${p['asset']}');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _chartCard(String label) => Container(
        height: 160,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTokens.accent.withValues(alpha: 0.06),
          border: Border.all(color: AppTokens.accent, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.show_chart, color: AppTokens.accent, size: 32),
          const SizedBox(height: 8),
          Text(label, style: AppTokens.inter(size: 13, lineHeight: 18, weight: FontWeight.w600, color: AppTokens.accent)),
        ]),
      );

  Widget _mediaCard(String label, Color color) => Container(
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppTokens.surface, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(label, style: AppTokens.inter(size: 14, lineHeight: 20, color: color)),
      );
}
