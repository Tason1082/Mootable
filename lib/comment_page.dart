import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comment_reply_page.dart';

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

  Future<void> _fetchComments() async {
    final data = await Supabase.instance.client
        .from("comments")
        .select('''
          id,
          content,
          created_at,
          profiles(username, id),
          comment_votes(vote, user_id),
          comment_replies(id)
        ''')
        .eq("post_id", widget.postId)
        .order("created_at", ascending: false);

    setState(() => _comments = List<Map<String, dynamic>>.from(data));
  }

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

  void _showReplyDialog(int commentId) {
    TextEditingController replyText = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cevap yaz"),
        content: TextField(controller: replyText),
        actions: [
          TextButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;

              if (user != null && replyText.text.trim().isNotEmpty) {
                await Supabase.instance.client
                    .from("comment_replies")
                    .insert({
                  "parent_id": commentId,
                  "user_id": user.id,
                  "content": replyText.text.trim(),
                });
              }

              Navigator.pop(context);
              _fetchComments();
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  void _openReplyList(int commentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentReplyPage(commentId: commentId),
      ),
    );
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
                final content = c['content'];

                final votes = c['comment_votes'] as List;
                int score = 0;
                int userVote = 0;

                final userId =
                    Supabase.instance.client.auth.currentUser?.id;

                for (var v in votes) {
                  score += (v['vote'] as num).toInt();
                  if (v['user_id'] == userId) {
                    userVote = (v['vote'] as num).toInt();
                  }
                }


                final replies = c['comment_replies'].length;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kullanıcı adı + içerik
                        Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(content),
                        const SizedBox(height: 12),

                        // -------- REDDIT STYLE ACTION BAR --------
                        Row(
                          children: [
                            // UPVOTE
                            IconButton(
                              icon: Icon(Icons.arrow_upward,
                                  color: userVote == 1 ? Colors.orange : Colors.grey),
                              onPressed: () => _voteComment(c['id'], 1),
                            ),

                            // SCORE
                            Text(
                              score.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            // DOWNVOTE
                            IconButton(
                              icon: Icon(Icons.arrow_downward,
                                  color: userVote == -1 ? Colors.blue : Colors.grey),
                              onPressed: () => _voteComment(c['id'], -1),
                            ),

                            const SizedBox(width: 6),

                            // SAVE (Kaydet)
                            IconButton(
                              icon: Icon(Icons.bookmark_border),
                              onPressed: () {
                                // Kaydetme kodu buraya
                              },
                            ),

                            const SizedBox(width: 6),

                            // YORUM YAPMA (Cevap)
                            IconButton(
                              icon: const Icon(Icons.mode_comment_outlined),
                              onPressed: () => _showReplyDialog(c['id']),
                            ),

                            const Spacer(),

                            // Cevap sayısı
                            if (replies > 0)
                              InkWell(
                                onTap: () => _openReplyList(c['id']),
                                child: Text(
                                  "$replies cevap →",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
