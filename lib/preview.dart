import 'package:flutter/material.dart';
import 'tokens.dart';

/// Visual preview that renders the lean blocks using the app's design tokens —
/// an approximation of how the post looks in the mobile app. Keep the styling in
/// lock-step with the RN renderer (src/components/notion/*) as it evolves.
class LeanPreview extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;
  const LeanPreview({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.screenHorizontalPadding),
      children: blocks.map(_block).toList(),
    );
  }

  Widget _block(Map<String, dynamic> b) {
    switch (b['type']) {
      case 'p':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.xs),
          child: _spans(b['spans'], 15),
        );
      case 'h':
        final level = (b['level'] as int?) ?? 1;
        final size = level == 1 ? 24.0 : (level == 2 ? 20.0 : 17.0);
        return Padding(
          padding: const EdgeInsets.only(top: AppTokens.md, bottom: AppTokens.xs),
          child: _spans(b['spans'], size, weight: FontWeight.w700),
        );
      case 'list':
        final items = (b['items'] as List).cast<List>();
        final ordered = b['ordered'] == true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ordered ? '${i + 1}. ' : '•  ',
                        style: const TextStyle(fontFamily: AppTokens.fontFamily)),
                    Expanded(
                        child: _spans((items[i]).cast<Map<String, dynamic>>(), 15)),
                  ],
                ),
              ),
          ],
        );
      case 'quote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppTokens.sm),
          padding: const EdgeInsets.only(left: AppTokens.md),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppTokens.bitcoinOrange, width: 3)),
          ),
          child: _spans(b['spans'], 15, italic: true, color: AppTokens.textSecondary),
        );
      case 'callout':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppTokens.sm),
          padding: const EdgeInsets.all(AppTokens.md),
          decoration: BoxDecoration(
            color: AppTokens.backgroundTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${b['icon'] ?? '💡'}  ',
                  style: const TextStyle(fontSize: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ((b['blocks'] as List?) ?? const [])
                      .cast<Map<String, dynamic>>()
                      .map(_block)
                      .toList(),
                ),
              ),
            ],
          ),
        );
      case 'code':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: AppTokens.sm),
          padding: const EdgeInsets.all(AppTokens.sm),
          color: const Color(0xFF1E1E1E),
          child: Text(b['text'] ?? '',
              style: const TextStyle(
                  fontFamily: 'monospace', color: Color(0xFFE6E6E6), fontSize: 13)),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(b['src'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder('image')),
          ),
        );
      case 'video':
        return _card('▶  YouTube video', AppTokens.video);
      case 'chart':
        final c = (b['chart'] as Map?) ?? const {};
        return _card(
            '📈  ${c['asset']} · ${c['chartType']} · ${c['timeRange'] ?? c['candleInterval'] ?? ''}',
            AppTokens.bitcoinOrange);
      case 'divider':
        return const Divider(height: AppTokens.lg);
      default:
        return _placeholder('unknown: ${b['type']}');
    }
  }

  Widget _spans(dynamic rawSpans, double size,
      {FontWeight weight = FontWeight.w400, bool italic = false, Color? color}) {
    final spans = (rawSpans as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return Text.rich(
      TextSpan(
        children: spans.map((s) {
          return TextSpan(
            text: s['text'] as String? ?? (s['emoji'] != null ? '🖼️' : ''),
            style: TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: size,
              color: (s['href'] != null) ? AppTokens.mercado : (color ?? AppTokens.textPrimary),
              fontWeight: s['bold'] == true ? FontWeight.w700 : weight,
              fontStyle: (s['italic'] == true || italic) ? FontStyle.italic : FontStyle.normal,
              decoration: s['href'] != null ? TextDecoration.underline : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _card(String label, Color color) => Container(
        height: 140,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppTokens.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontFamily: AppTokens.fontFamily, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _placeholder(String label) => Container(
        padding: const EdgeInsets.all(AppTokens.sm),
        margin: const EdgeInsets.symmetric(vertical: AppTokens.xs),
        color: AppTokens.backgroundTertiary,
        child: Text(label, style: const TextStyle(color: AppTokens.textSecondary)),
      );
}
