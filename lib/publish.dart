import 'dart:convert';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'lean.dart';

/// Publishes the current document to the crypto-bros-content GitHub repo in the
/// app-native format: writes `posts/<id>.<locale>.json` (full body) and updates
/// the bilingual `index.json` (card metadata + preview, split at the first
/// divider). Uses the GitHub Contents API over HTTPS — ordinary app code.
const String kOwner = 'oviniciusramosp';
const String kRepo = 'crypto-bros-content';
const String kBranch = 'main';

const _storage = FlutterSecureStorage();
const _tokenKey = 'github_pat';

class PostMetadata {
  String id;
  String locale;
  String slug;
  String title;
  String excerpt;
  String category;
  String coverUrl;
  List<String> tags;
  PostMetadata({
    required this.id,
    required this.locale,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.coverUrl,
    required this.tags,
  });
}

Future<void> publishFlow(BuildContext context, EditorState editorState) async {
  final meta = await _askMetadata(context);
  if (meta == null) return;

  var token = await _storage.read(key: _tokenKey);
  if (token == null || token.isEmpty) {
    if (!context.mounted) return;
    token = await _askToken(context);
    if (token == null || token.isEmpty) return;
    await _storage.write(key: _tokenKey, value: token);
  }

  final blocks = documentToBlocks(editorState.document);
  final split = splitPreview(blocks);
  final now = DateTime.now().toUtc().toIso8601String();

  final common = {
    'id': meta.id,
    'locale': meta.locale,
    'slug': meta.slug,
    'date': now,
    'updated': now,
    'categories': [meta.category],
    'tags': meta.tags.map((t) => {'name': t, 'color': 'blue'}).toList(),
    'author': {'id': 'studio', 'name': 'Crypto Bros', 'avatar': null},
    'cover': meta.coverUrl.isEmpty ? null : meta.coverUrl,
    'thumbnail': null,
    'title': [
      {'text': meta.title}
    ],
    'excerpt': meta.excerpt,
  };

  final postDoc = {
    'schemaVersion': schemaVersion,
    ...common,
    'blocks': blocks,
  };
  final summary = {
    ...common,
    'hasMore': split.hasMore,
    'preview': split.preview,
  };

  try {
    // 1. Write the full post body.
    await _putFile(
      'posts/${meta.id}.${meta.locale}.json',
      _pretty(postDoc),
      'Publish ${meta.slug} (${meta.locale})',
      token,
    );
    // 2. Merge into the index (replace any existing id+locale entry).
    final index = await _getIndex(token);
    final posts = (index['posts'] as List).cast<Map<String, dynamic>>();
    posts.removeWhere((p) => p['id'] == meta.id && p['locale'] == meta.locale);
    posts.add(summary);
    index['posts'] = posts;
    index['generatedAt'] = now;
    index['schemaVersion'] = schemaVersion;
    await _putFile('index.json', _pretty(index),
        'Update index for ${meta.slug} (${meta.locale})', token);

    if (context.mounted) {
      _toast(context, 'Published ${meta.slug} (${meta.locale}) ✓');
    }
  } catch (e) {
    if (context.mounted) _toast(context, 'Publish failed: $e');
  }
}

String _pretty(Object o) => const JsonEncoder.withIndent('  ').convert(o);

Map<String, String> _headers(String token) => {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };

Future<Map<String, dynamic>> _getIndex(String token) async {
  final res = await http.get(
    Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/index.json?ref=$kBranch'),
    headers: _headers(token),
  );
  if (res.statusCode == 404) {
    return {'schemaVersion': schemaVersion, 'generatedAt': '', 'posts': []};
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final content = utf8.decode(base64.decode((body['content'] as String).replaceAll('\n', '')));
  return jsonDecode(content) as Map<String, dynamic>;
}

Future<void> _putFile(String path, String content, String message, String token) async {
  // GET current sha (if the file exists) so we can update it.
  String? sha;
  final getRes = await http.get(
    Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path?ref=$kBranch'),
    headers: _headers(token),
  );
  if (getRes.statusCode == 200) {
    sha = (jsonDecode(getRes.body) as Map<String, dynamic>)['sha'] as String?;
  }

  final putRes = await http.put(
    Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path'),
    headers: _headers(token),
    body: jsonEncode({
      'message': message,
      'content': base64.encode(utf8.encode(content)),
      'branch': kBranch,
      if (sha != null) 'sha': sha,
    }),
  );
  if (putRes.statusCode != 200 && putRes.statusCode != 201) {
    throw Exception('${putRes.statusCode} ${putRes.body}');
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<PostMetadata?> _askMetadata(BuildContext context) {
  final titleCtrl = TextEditingController();
  final slugCtrl = TextEditingController();
  final excerptCtrl = TextEditingController();
  final coverCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  var locale = 'pt';
  var category = 'Mercado';

  return showDialog<PostMetadata>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Publish post'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: slugCtrl, decoration: const InputDecoration(labelText: 'Slug (e.g. bitcoin-novo-topo)')),
              TextField(controller: excerptCtrl, decoration: const InputDecoration(labelText: 'Excerpt')),
              TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: 'Cover image URL (optional)')),
              TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (c, setLocal) => Row(
                  children: [
                    const Text('Locale:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: locale,
                      items: const ['pt', 'en']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setLocal(() => locale = v ?? 'pt'),
                    ),
                    const SizedBox(width: 16),
                    const Text('Category:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: category,
                      items: const ['Mercado', 'Estudos', 'Altcoins', 'Trade', 'Video', 'ATH']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setLocal(() => category = v ?? 'Mercado'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final slug = slugCtrl.text.trim();
            if (slug.isEmpty) return;
            Navigator.pop(
              ctx,
              PostMetadata(
                id: slug,
                locale: locale,
                slug: slug,
                title: titleCtrl.text.trim(),
                excerpt: excerptCtrl.text.trim(),
                category: category,
                coverUrl: coverCtrl.text.trim(),
                tags: tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              ),
            );
          },
          child: const Text('Publish'),
        ),
      ],
    ),
  );
}

Future<String?> _askToken(BuildContext context) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('GitHub token'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('A fine-grained PAT with Contents: read & write on '
              '$kOwner/$kRepo. Stored in the OS keychain.'),
          const SizedBox(height: 8),
          TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'ghp_… / github_pat_…')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}
