import 'dart:async';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'chart_block.dart';
import 'lean.dart';
import 'preview.dart';
import 'publish.dart';
import 'tokens.dart';

void main() => runApp(const StudioApp());

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Bros Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppTokens.bitcoinOrange,
        fontFamily: AppTokens.fontFamily,
      ),
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorState editorState;
  late final Map<String, BlockComponentBuilder> builders;
  StreamSubscription<dynamic>? _sub;
  List<Map<String, dynamic>> _preview = [];

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank(withInitialText: true);
    builders = {
      ...standardBlockComponentBuilderMap,
      chartBlockType: ChartBlockComponentBuilder(),
    };
    _sub = editorState.transactionStream.listen((_) => _refresh());
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _preview = documentToBlocks(editorState.document));
  }

  @override
  void dispose() {
    _sub?.cancel();
    editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Crypto Bros Studio',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTokens.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => insertChartNode(editorState),
            icon: const Icon(Icons.show_chart, color: AppTokens.bitcoinOrange),
            label: const Text('Insert chart'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTokens.bitcoinOrange),
            onPressed: () => publishFlow(context, editorState),
            icon: const Icon(Icons.cloud_upload, size: 18),
            label: const Text('Publish'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editor
          Expanded(
            child: Container(
              color: Colors.white,
              child: AppFlowyEditor(
                editorState: editorState,
                blockComponentBuilders: builders,
                editorStyle: EditorStyle.desktop(
                  textStyleConfiguration: const TextStyleConfiguration(
                    text: TextStyle(
                        fontSize: 15,
                        fontFamily: AppTokens.fontFamily,
                        color: AppTokens.textPrimary),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Live preview (app-styled)
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.sm),
                    color: AppTokens.backgroundTertiary,
                    child: const Text('Preview (app)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppTokens.textSecondary)),
                  ),
                  Expanded(child: LeanPreview(blocks: _preview)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
