import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final data = await Supabase.instance.client
        .from("comments")
        .select('''
          id,
          content,
          created_at,
          comment_edited,
          parent_id,
          profiles(id, username),
          comment_votes(vote, user_id)
        ''')
        .eq("post_id", widget.postId)
        .order("created_at", ascending: true);

    comments = List<Map<String, dynamic>>.from(data);

    tree = {};
    for (var c in comments) {
      final pid = c["parent_id"];
      tree.putIfAbsent(pid, () => []);
      tree[pid]!.add(c);
    }

    setState(() {});
  }

  Future<void> _addComment() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _text.text.trim().isEmpty) return;

    await Supabase.instance.client.from("comments").insert({
      "post_id": widget.postId,
      "user_id": user.id,
      "content": _text.text.trim(),
      "parent_id": null,
    });

    _text.clear();
    _fetchComments();
  }

  Future<void> _addReply(int parentId, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || content.trim().isEmpty) return;

    await Supabase.instance.client.from("comments").insert({
      "post_id": widget.postId,
      "user_id": user.id,
      "content": content.trim(),
      "parent_id": parentId,
    });

    _fetchComments();
  }

  Future<void> _voteComment(int commentId, int vote) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final existing = await client
        .from("comment_votes")
        .select()
        .eq("comment_id", commentId)
        .eq("user_id", user.id);

    if (existing.isEmpty) {
      await client.from("comment_votes").insert({
        "comment_id": commentId,
        "user_id": user.id,
        "vote": vote,
      });
    } else {
      final oldVote = existing[0]["vote"];
      if (oldVote == vote) {
        await client
            .from("comment_votes")
            .delete()
            .eq("comment_id", commentId)
            .eq("user_id", user.id);
      } else {
        await client
            .from("comment_votes")
            .update({"vote": vote})
            .eq("comment_id", commentId)
            .eq("user_id", user.id);
      }
    }

    _fetchComments();
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
        content: TextField(
          controller: editor,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newText = editor.text.trim();
              if (newText.isNotEmpty) {
                await Supabase.instance.client
                    .from("comments")
                    .update({
                  "content": newText,
                  "comment_edited": DateTime.now().toIso8601String()
                })
                    .eq("id", commentId);
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
    final currentUser = Supabase.instance.client.auth.currentUser?.id;

    final votes = (c["comment_votes"] as List?) ?? [];
    int score = 0;
    int userVote = 0;

    for (var v in votes) {
      score += (v["vote"] as num).toInt();
      if (v["user_id"] == currentUser) userVote = v["vote"];
    }

    final children = tree[c["id"]] ?? [];

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c["profiles"]["username"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),
          Text(c["content"]),

          if (c["edited_at"] != null)
            const Text("(düzenlendi)",
                style: TextStyle(fontSize: 11, color: Colors.grey)),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_upward,
                    color: userVote == 1 ? Colors.orange : Colors.grey),
                onPressed: () => _voteComment(c["id"], 1),
              ),
              Text(score.toString()),
              IconButton(
                icon: Icon(Icons.arrow_downward,
                    color: userVote == -1 ? Colors.blue : Colors.grey),
                onPressed: () => _voteComment(c["id"], -1),
              ),

              TextButton(
                onPressed: () => _showReplyDialog(c["id"]),
                child: const Text("Yanıtla"),
              ),

              if (c["profiles"]["id"] == currentUser)
                TextButton(
                  onPressed: () =>
                      _showEditDialog(c["id"], c["content"]),
                  child: const Text("Düzenle"),
                ),
            ],
          ),

          // Recursive child comments
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
            child: ListView(
              children: [
                for (var c in roots) _buildComment(c, 0),
              ],
            ),
          ),

          // Add new comment
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration:
                    const InputDecoration(hintText: "Yorum yaz..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}