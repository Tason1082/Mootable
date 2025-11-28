import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentReplyPage extends StatefulWidget {
  final int commentId;
  const CommentReplyPage({super.key, required this.commentId});

  @override
  State<CommentReplyPage> createState() => _CommentReplyPageState();
}

class _CommentReplyPageState extends State<CommentReplyPage> {
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  Future<void> _fetchReplies() async {
    final data = await Supabase.instance.client
        .from("comment_replies")
        .select('''
          id,
          content,
          created_at,
          profiles(username),
          reply_votes(vote, user_id)
        ''')
        .eq("parent_id", widget.commentId)
        .order("created_at", ascending: true);

    setState(() => _replies = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _voteReply(int replyId, int vote) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    final old = await client
        .from("reply_votes")
        .select()
        .eq("reply_id", replyId)
        .eq("user_id", user!.id);

    if (old.isEmpty) {
      await client.from("reply_votes").insert({
        "reply_id": replyId,
        "user_id": user.id,
        "vote": vote,
      });
    } else {
      final oldVote = old[0]["vote"];

      if (oldVote == vote) {
        await client
            .from("reply_votes")
            .delete()
            .eq("reply_id", replyId)
            .eq("user_id", user.id);
      } else {
        await client
            .from("reply_votes")
            .update({"vote": vote})
            .eq("reply_id", replyId)
            .eq("user_id", user.id);
      }
    }

    _fetchReplies();
  }

  void _showReplyDialog() {
    TextEditingController text = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cevap yaz"),
        content: TextField(controller: text),
        actions: [
          TextButton(
            onPressed: () async {
              final user =
                  Supabase.instance.client.auth.currentUser;

              if (user != null && text.text.trim().isNotEmpty) {
                await Supabase.instance.client
                    .from("comment_replies")
                    .insert({
                  "parent_id": widget.commentId,
                  "user_id": user.id,
                  "content": text.text.trim(),
                });
              }

              Navigator.pop(context);
              _fetchReplies();
            },
            child: const Text("Gönder"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cevaplar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.reply),
            onPressed: _showReplyDialog,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _replies.length,
        itemBuilder: (context, i) {
          final r = _replies[i];
          final username = r['profiles']?['username'] ?? 'Anonim';
          final content = r['content'];

          final votes = r['reply_votes'] as List;
          final userId =
              Supabase.instance.client.auth.currentUser?.id;

          int score = 0;
          int userVote = 0;

          for (var v in votes) {
            score += (v['vote'] as num).toInt();
            if (v['user_id'] == userId) {
              userVote = (v['vote'] as num).toInt();
            }
          }


          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_upward,
                          color: userVote == 1
                              ? Colors.orange
                              : Colors.grey),
                      onPressed: () =>
                          _voteReply(r['id'], 1),
                    ),
                    Text(
                      score.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward,
                          color: userVote == -1
                              ? Colors.blue
                              : Colors.grey),
                      onPressed: () =>
                          _voteReply(r['id'], -1),
                    ),
                  ],
                ),

                // Reddit tarzı sol çizgi
                Container(
                  width: 3,
                  height: 70,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(content),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
