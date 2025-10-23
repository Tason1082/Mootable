import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentPage extends StatefulWidget {
  final int postId;
  const CommentPage({super.key, required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final _text = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  // Yorumları çek
  Future<void> _fetchComments() async {
    final data = await Supabase.instance.client
        .from("comments")
        .select('content, created_at, profiles(username)')
        .eq("post_id", widget.postId)
        .order("created_at", ascending: false);

    setState(() => _comments = List<Map<String, dynamic>>.from(data));
  }

  // Yorum ekle
  Future<void> _addComment() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _text.text.trim().isEmpty) return;

    await Supabase.instance.client.from("comments").insert({
      "post_id": widget.postId,
      "user_id": user.id,
      "content": _text.text.trim(),
    });

    _text.clear();
    _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yorumlar")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, i) {
                final c = _comments[i];
                final username = c['profiles']?['username'] ?? 'Anonim';
                final content = c['content'] ?? '';
                final createdAt = c['created_at'] != null
                    ? DateTime.parse(c['created_at']).toLocal()
                    : DateTime.now();

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text("$username: $content"),
                  subtitle: Text(
                    "${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}",
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
