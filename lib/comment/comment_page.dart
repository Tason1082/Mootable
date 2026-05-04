import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';

class CommentPage extends StatefulWidget {
  final int postId;

  const CommentPage({
    super.key,
    required this.postId,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  List<Map<String, dynamic>> comments = [];

  Map<int?, List<Map<String, dynamic>>> tree = {};

  final _text = TextEditingController();

  /// replies açık/kapalı
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
      final res = await ApiClient.dio.get(
        '/api/comments/post/${widget.postId}',
      );

      final body = res.data;

      debugPrint("COMMENTS RESPONSE: ${res.data.runtimeType}");
      debugPrint("COMMENTS BODY: ${res.data}");

      if (body is! Map || body["success"] != true) {
        comments = [];
        tree = {};

        setState(() {});

        return;
      }

      final List raw = body["data"] ?? [];

      comments = raw.map((item) {
        final c = Map<String, dynamic>.from(item);

        return {
          ...c,

          "votes_count": c["netScore"] ?? 0,
          "user_vote": c["userVote"] ?? 0,

          "created_at": c["createdAt"],

          "replyCount": c["replyCount"] ?? 0,
        };
      }).toList();

      tree = {};

      for (var c in comments) {
        final pid = c["parentCommentId"];

        tree.putIfAbsent(pid, () => []);

        tree[pid]!.add(c);
      }

      setState(() {});
    } on DioException catch (e) {
      debugPrint("Yorumları çekerken hata: ${e.response?.data}");
    } catch (e) {
      debugPrint("Yorumları çekerken hata: $e");
    }
  }
  Future<void> _addComment() async {
    final content = _text.text.trim();

    if (content.isEmpty) return;

    try {
      final response = await ApiClient.dio.post(
        "/api/comments",
        data: {
          "postId": widget.postId,
          "content": content,
        },
      );

      final data = response.data;

      debugPrint("ADD COMMENT RESPONSE: ${response.data.runtimeType}");
      debugPrint("ADD COMMENT BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      _text.clear();

      await _fetchComments();
    } catch (e) {
      debugPrint("ADD COMMENT ERROR: $e");
    }
  }
  Future<void> _addReply(
      int parentId,
      String content,
      ) async {
    final text = content.trim();

    if (text.isEmpty) return;

    try {
      final response = await ApiClient.dio.post(
        "/api/comments",
        data: {
          "postId": widget.postId,
          "content": text,
          "parentId": parentId,
        },
      );

      final data = response.data;

      debugPrint("ADD REPLY RESPONSE: ${response.data.runtimeType}");
      debugPrint("ADD REPLY BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("ADD REPLY ERROR: $e");
    }
  }
  Future<void> _voteComment(
      int commentId,
      int vote,
      ) async {
    try {
      final response = await ApiClient.dio.post(
        "/api/comments/$commentId/vote2",
        data: {
          "vote": vote,
        },
      );

      final data = response.data;

      debugPrint("VOTE RESPONSE: ${response.data.runtimeType}");
      debugPrint("VOTE BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("VOTE COMMENT ERROR: $e");
    }
  }
  Future<void> _editComment(
      int commentId,
      String content,
      ) async {
    try {
      final response = await ApiClient.dio.put(
        "/api/comments/$commentId",
        data: {
          "content": content,
        },
      );

      final data = response.data;

      debugPrint("EDIT COMMENT RESPONSE: ${response.data.runtimeType}");
      debugPrint("EDIT COMMENT BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("EDIT COMMENT ERROR: $e");
    }
  }

  void _showReplyDialog(int parentId) {
    final replyText = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Yanıtla"),
          content: TextField(
            controller: replyText,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _addReply(
                  parentId,
                  replyText.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Gönder"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      int commentId,
      String oldContent,
      ) {
    final editor = TextEditingController(
      text: oldContent,
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Düzenle"),
          content: TextField(
            controller: editor,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final text = editor.text.trim();

                if (text.isNotEmpty) {
                  await _editComment(
                    commentId,
                    text,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComment(
      Map<String, dynamic> c,
      int depth,
      ) {
    final int score = c["netScore"] ?? 0;
    final int userVote = c["userVote"] ?? 0;

    final children = tree[c["id"]] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 20,
        top: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c["username"] ?? "Unknown",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(c["content"] ?? ""),

          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: userVote == 1
                      ? Colors.orange
                      : Colors.grey,
                ),
                onPressed: () {
                  _voteComment(c["id"], 1);
                },
              ),

              Text(score.toString()),

              IconButton(
                icon: Icon(
                  Icons.arrow_downward,
                  color: userVote == -1
                      ? Colors.blue
                      : Colors.grey,
                ),
                onPressed: () {
                  _voteComment(c["id"], -1);
                },
              ),

              TextButton(
                onPressed: () {
                  _showReplyDialog(c["id"]);
                },
                child: const Text("Yanıtla"),
              ),

              if (c["isOwner"] == true)
                TextButton(
                  onPressed: () {
                    _showEditDialog(
                      c["id"],
                      c["content"] ?? "",
                    );
                  },
                  child: const Text("Düzenle"),
                ),
            ],
          ),

          if (children.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  replyVisibility[c["id"]] =
                  !(replyVisibility[c["id"]] ?? false);
                });
              },
              child: Text(
                (replyVisibility[c["id"]] ?? false)
                    ? "Yanıtları gizle"
                    : "${children.length} yanıtı gör",
                style: const TextStyle(fontSize: 13),
              ),
            ),

          if (replyVisibility[c["id"]] ?? false)
            for (var reply in children)
              _buildComment(reply, depth + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = tree[null] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yorumlar"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var c in roots)
                  _buildComment(c, 0),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: "Yorum yaz...",
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

