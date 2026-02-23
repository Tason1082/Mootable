import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';


class CommentPage extends StatefulWidget {
  final int postId;
  const CommentPage({super.key, required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  List<Map<String, dynamic>> comments = [];
  Map<int?, List<Map<String, dynamic>>> tree = {};
  final _text = TextEditingController();

  /// Yanıtları gizleyip açmak için
  Map<int, bool> replyVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await ApiClient.dio
          .get('/api/comments/post/${widget.postId}');

      comments = List<Map<String, dynamic>>.from(res.data);

      tree = {};
      for (var c in comments) {
        final pid = c["parentCommentId"];
        tree.putIfAbsent(pid, () => []);
        tree[pid]!.add(c);
      }

      setState(() {});
    } catch (e) {
      print("Yorumları çekerken hata: $e");
    }
  }

  Future<void> _addComment() async {
    final content = _text.text.trim();
    if (content.isEmpty) return;

    try {
      await ApiClient.dio.post('/api/comments', data: {
        "postId": widget.postId,
        "content": content,
      });

      _text.clear();
      await _fetchComments();
    } catch (e) {
      print("Yorum eklerken hata: $e");
    }
  }

  Future<void> _addReply(int parentId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      await ApiClient.dio.post('/api/comments', data: {
        "postId": widget.postId,
        "content": content,
        "parentId": parentId,
      });

      _fetchComments();
    } catch (e) {
      print("Yanıt eklerken hata: $e");
    }
  }

  Future<void> _voteComment(int commentId, int vote) async {
    try {
      await ApiClient.dio.post(
        '/api/comments/$commentId/vote2',
        data: {
          "vote": vote,
        },
      );

      await _fetchComments();

    } catch (e) {
      print("Oy verirken hata: $e");
    }
  }


  void _showReplyDialog(int parentId) {
    TextEditingController replyText = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yanıtla"),
        content: TextField(controller: replyText),
        actions: [
          TextButton(
            onPressed: () async {
              await _addReply(parentId, replyText.text);
              Navigator.pop(context);
            },
            child: const Text("Gönder"),
          )
        ],
      ),
    );
  }

  void _showEditDialog(int commentId, String oldContent) {
    final editor = TextEditingController(text: oldContent);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Düzenle"),
        content: TextField(controller: editor, maxLines: null),
        actions: [
          TextButton(
            onPressed: () async {
              final newText = editor.text.trim();
              if (newText.isNotEmpty) {
                await ApiClient.dio.put('/api/comments/$commentId', data: {
                  "content": newText,
                });
                _fetchComments();
              }
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> c, int depth) {
    final votes = c["votes"] ?? [];
    int score = c["netScore"] ?? 0;
    int userVote = c["userVote"] ?? 0;

    final children = tree[c["id"]] ?? [];

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c["username"] ?? "Bilinmeyen", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(c["content"] ?? ""),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_upward, color: userVote == 1 ? Colors.orange : Colors.grey),
                onPressed: () => _voteComment(c["id"], 1),
              ),
              Text(score.toString()),
              IconButton(
                icon: Icon(Icons.arrow_downward, color: userVote == -1 ? Colors.blue : Colors.grey),
                onPressed: () => _voteComment(c["id"], -1),
              ),
              TextButton(onPressed: () => _showReplyDialog(c["id"]), child: const Text("Yanıtla")),
              if (c["isOwner"] == true)
                TextButton(onPressed: () => _showEditDialog(c["id"], c["content"]), child: const Text("Düzenle")),
            ],
          ),
          if (children.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  replyVisibility[c["id"]] = !(replyVisibility[c["id"]] ?? false);
                });
              },
              child: Text(
                (replyVisibility[c["id"]] ?? false) ? "Yanıtları gizle" : "${children.length} yanıtı gör",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          if (replyVisibility[c["id"]] ?? false)
            for (var reply in children) _buildComment(reply, depth + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = tree[null] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Yorumlar")),
      body: Column(
        children: [
          Expanded(
            child: ListView(children: [for (var c in roots) _buildComment(c, 0)]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _text, decoration: const InputDecoration(hintText: "Yorum yaz..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
              ],
            ),
          )
        ],
      ),
    );
  }
}

