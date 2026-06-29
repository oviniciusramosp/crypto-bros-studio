import 'package:appflowy_editor/appflowy_editor.dart';
import 'chart_block.dart';

/// Serializes an AppFlowy `Document` into the Crypto Bros app-native ("lean")
/// content format (mirrors the app's src/types/content.ts). This is the only
/// place that touches AppFlowy's node tree — a single pass over an ordered list,
/// per the documented model (node.type / node.attributes / node.delta).
const int schemaVersion = 1;

/// Convert a node's Delta into lean inline spans. Flags are omitted when false.
List<Map<String, dynamic>> deltaToSpans(Delta? delta) {
  if (delta == null) return [];
  final spans = <Map<String, dynamic>>[];
  for (final op in delta) {
    if (op is! TextInsert) continue;
    final attrs = op.attributes ?? const {};
    final span = <String, dynamic>{'text': op.text};
    if (attrs['bold'] == true) span['bold'] = true;
    if (attrs['italic'] == true) span['italic'] = true;
    if (attrs['underline'] == true) span['underline'] = true;
    if (attrs['strikethrough'] == true) span['strikethrough'] = true;
    if (attrs['code'] == true) span['code'] = true;
    final href = attrs['href'];
    if (href is String && href.isNotEmpty) span['href'] = href;
    spans.add(span);
  }
  return spans;
}

String _plainText(Delta? delta) {
  if (delta == null) return '';
  return delta.whereType<TextInsert>().map((o) => o.text).join();
}

/// Map a single AppFlowy node to zero-or-one lean block. List grouping is
/// handled by [documentToBlocks]; this returns the per-node shape.
Map<String, dynamic>? nodeToBlock(Node node) {
  switch (node.type) {
    case 'paragraph':
      return {'type': 'p', 'spans': deltaToSpans(node.delta)};
    case 'heading':
      final level = (node.attributes['level'] as int?) ?? 1;
      return {'type': 'h', 'level': level.clamp(1, 3), 'spans': deltaToSpans(node.delta)};
    case 'quote':
      return {'type': 'quote', 'spans': deltaToSpans(node.delta)};
    case 'todo_list':
      return {
        'type': 'todo',
        'checked': node.attributes['checked'] == true,
        'spans': deltaToSpans(node.delta),
      };
    case 'divider':
      return {'type': 'divider'};
    case 'image':
      final url = node.attributes['url'] as String?;
      if (url == null) return null;
      return {'type': 'image', 'src': url};
    case 'code':
      return {
        'type': 'code',
        if (node.attributes['language'] != null) 'lang': node.attributes['language'],
        'text': _plainText(node.delta),
      };
    case chartBlockType:
      return {'type': 'chart', 'chart': chartParamsFromNode(node)};
    default:
      return {'type': 'unknown', 'original': node.type};
  }
}

/// Walk the document's top-level children into lean blocks, grouping consecutive
/// bulleted/numbered list items into a single `list` block.
List<Map<String, dynamic>> documentToBlocks(Document document) {
  final out = <Map<String, dynamic>>[];
  final children = document.root.children;

  var i = 0;
  while (i < children.length) {
    final node = children[i];
    if (node.type == 'bulleted_list' || node.type == 'numbered_list') {
      final ordered = node.type == 'numbered_list';
      final items = <List<Map<String, dynamic>>>[];
      while (i < children.length && children[i].type == node.type) {
        items.add(deltaToSpans(children[i].delta));
        i++;
      }
      out.add({'type': 'list', 'ordered': ordered, 'items': items});
      continue;
    }
    final block = nodeToBlock(node);
    if (block != null) out.add(block);
    i++;
  }
  return out;
}

/// Split blocks at the first divider: preview = blocks before it; the full body
/// keeps everything. `hasMore` is true when a divider was present.
({List<Map<String, dynamic>> preview, bool hasMore}) splitPreview(
  List<Map<String, dynamic>> blocks,
) {
  final idx = blocks.indexWhere((b) => b['type'] == 'divider');
  if (idx < 0) return (preview: blocks, hasMore: false);
  return (preview: blocks.sublist(0, idx), hasMore: true);
}
