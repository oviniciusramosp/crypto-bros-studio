import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Custom "chart" block — the headline reason for the Studio. Instead of typing
/// the error-prone `{{chart:...}}` text marker, the author inserts a structured
/// chart node from the slash menu / toolbar and edits it through a form. On
/// publish it serializes to `{ "type": "chart", "chart": { ... } }` — no string
/// syntax to get wrong.
const String chartBlockType = 'chart';

Node chartNode({
  String asset = 'BTC',
  String chartType = 'line',
  String date = 'now',
  String timeRange = '6m',
}) {
  return Node(
    type: chartBlockType,
    attributes: {
      'asset': asset,
      'chartType': chartType,
      'date': date,
      'timeRange': timeRange,
    },
  );
}

/// Extract the structured chart params (matches the app's ChartEmbedParams).
Map<String, dynamic> chartParamsFromNode(Node node) {
  final a = node.attributes;
  return {
    'asset': (a['asset'] as String?) ?? 'BTC',
    'date': (a['date'] as String?) ?? 'now',
    'chartType': (a['chartType'] as String?) ?? 'line',
    if (a['timeRange'] != null) 'timeRange': a['timeRange'],
    if (a['candleInterval'] != null) 'candleInterval': a['candleInterval'],
  };
}

/// Slash-menu item that inserts a chart block.
SelectionMenuItem chartMenuItem = SelectionMenuItem(
  name: 'Chart',
  icon: (editorState, isSelected, style) => Icon(
    Icons.show_chart,
    color: isSelected ? AppTokens.bitcoinOrange : AppTokens.textSecondary,
    size: 18,
  ),
  keywords: ['chart', 'grafico', 'gráfico', 'price', 'btc'],
  handler: (editorState, _, __) => insertChartNode(editorState),
);

Future<void> insertChartNode(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) return;
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) return;
  final transaction = editorState.transaction;
  transaction.insertNode(node.path.next, chartNode());
  await editorState.apply(transaction);
}

/// Builder: Node → widget.
class ChartBlockComponentBuilder extends BlockComponentBuilder {
  ChartBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ChartBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) =>
          actionBuilder(blockComponentContext, state),
    );
  }

  @override
  bool validate(Node node) => node.attributes['asset'] is String;
}

class ChartBlockWidget extends BlockComponentStatefulWidget {
  const ChartBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<ChartBlockWidget> createState() => _ChartBlockWidgetState();
}

class _ChartBlockWidgetState extends State<ChartBlockWidget>
    with BlockComponentConfigurable {
  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  EditorState get editorState => context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    final params = chartParamsFromNode(node);
    final label =
        '${params['asset']} · ${params['chartType']} · ${params['timeRange'] ?? params['candleInterval'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.sm),
      child: GestureDetector(
        onTap: () => _editChart(context),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTokens.bitcoinOrange.withValues(alpha: 0.06),
            border: Border.all(color: AppTokens.bitcoinOrange, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart,
                  color: AppTokens.bitcoinOrange, size: 36),
              const SizedBox(height: AppTokens.sm),
              Text('Chart · $label',
                  style: const TextStyle(
                      fontFamily: AppTokens.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.textPrimary)),
              const SizedBox(height: AppTokens.xs),
              const Text('tap to edit',
                  style: TextStyle(
                      fontFamily: AppTokens.fontFamily,
                      fontSize: 12,
                      color: AppTokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editChart(BuildContext context) async {
    final assetCtrl = TextEditingController(text: node.attributes['asset'] ?? 'BTC');
    final timeCtrl =
        TextEditingController(text: node.attributes['timeRange'] ?? '6m');
    var type = (node.attributes['chartType'] as String?) ?? 'line';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: assetCtrl,
                decoration: const InputDecoration(labelText: 'Asset (BTC, ETH…)')),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (c, setLocal) => DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: const ['line', 'candle', 'rsi', 'fng', 'cycle']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setLocal(() => type = v ?? 'line'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: timeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Time range (6m, 1y…)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      final transaction = editorState.transaction;
      transaction.updateNode(node, {
        ...node.attributes,
        'asset': assetCtrl.text.trim().toUpperCase(),
        'chartType': type,
        'timeRange': timeCtrl.text.trim(),
      });
      await editorState.apply(transaction);
    }
  }
}
