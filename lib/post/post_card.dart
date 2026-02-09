import 'package:flutter/material.dart';
import 'package:mootable/quote_post_page.dart';
import '../../TimeAgo.dart';
import '../../video_player_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../comment/comment_page.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool showActions;

  const PostCard({
    super.key,
    required this.post,
    this.showActions = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> post;

  @override
  void initState() {
    super.initState();
    post = widget.post;

    debugPrint("POST DATA => $post");
    debugPrint("IMAGE URL => ${post["imageUrl"]}");
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith(".mp4") ||
        lower.endsWith(".mov") ||
        lower.endsWith(".avi") ||
        lower.endsWith(".webm");
  }

  Widget _buildMedia(String url) {
    if (_isVideo(url)) {
      return AspectRatio(
        aspectRatio: 1,
        child: VideoPlayerWidget(videoUrl: url),
      );
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Center(child: Icon(Icons.broken_image)),
    );
  }

  // 🟢 BAĞIMSIZ POST İŞLEMLERİ



  Future<void> _toggleSave() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (post["is_saved"] == true) {
        await Supabase.instance.client
            .from('saved_posts')
            .delete()
            .eq('post_id', post["id"])
            .eq('user_id', user.id);
      } else {
        await Supabase.instance.client
            .from('saved_posts')
            .insert({'post_id': post["id"], 'user_id': user.id});
      }

      setState(() {
        post["is_saved"] = !(post["is_saved"] == true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kaydedilemedi")));
      }
    }
  }
  Future<void> _toggleVote(int vote) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final int previousVote = post["user_vote"] ?? 0;
    final int previousCount = post["votes_count"] ?? 0;

    // Local update
    setState(() {
      if (previousVote == vote) {
        post["user_vote"] = 0;
        post["votes_count"] = previousCount - vote;
      } else {
        post["user_vote"] = vote;
        post["votes_count"] = previousCount - previousVote + vote;
      }
    });

    try {
      final existingVote = await Supabase.instance.client
          .from("votes")
          .select("vote")
          .eq("post_id", post["id"])
          .eq("user_id", user.id)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote["vote"] == vote) {
          await Supabase.instance.client
              .from("votes")
              .delete()
              .eq("post_id", post["id"])
              .eq("user_id", user.id);
          setState(() => post["user_vote"] = 0);
        } else {
          await Supabase.instance.client
              .from("votes")
              .update({"vote": vote})
              .eq("post_id", post["id"])
              .eq("user_id", user.id);
          setState(() => post["user_vote"] = vote);
        }
      } else {
        await Supabase.instance.client.from("votes").insert({
          "post_id": post["id"],
          "user_id": user.id,
          "vote": vote,
        });
        setState(() => post["user_vote"] = vote);
      }
    } catch (e) {
      // hata durumunda geri al
      setState(() {
        post["user_vote"] = previousVote;
        post["votes_count"] = previousCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oy verilemedi")),
        );
      }
    }
  }

  Future<void> _joinCommunity() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('community_members')
          .insert({'community_id': post["community"], 'user_id': user.id});

      setState(() {
        post["is_member"] = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Topluluğa katılamadı")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP BAR
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups)),
            title: Text(
              post["community_name"] ?? "",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              TimeAgo.format(
                context,
                DateTime.parse(post["created_at"]),
              ),
            ),
          ),

          /// MEDIA
          if (post["imageUrl"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMedia(post["imageUrl"]),
            ),

          /// CONTENT
          if ((post["content"] ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(post["content"]),
            ),

          /// ACTIONS
          if (widget.showActions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      /// ⬆️ UPVOTE
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: post["user_vote"] == 1
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        onPressed: () => _toggleVote(1),
                      ),

                      Text("${post["votes_count"] ?? 0}"),

                      /// ⬇️ DOWNVOTE
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: post["user_vote"] == -1
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                        onPressed: () => _toggleVote(-1),
                      ),

                      const SizedBox(width: 8),

                      /// 💬 COMMENT
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {
                          // COMMENT sayfası
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommentPage(postId: post["id"]),
                            ),
                          );

//


                        },
                      ),

                      Text("${post["comment_count"] ?? 0}"),

                      const Spacer(),

                      /// 🔁 QUOTE
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuotePostPage(post: post),
                            ),
                          );
                        },
                      ),

                      /// 💾 SAVE
                      IconButton(
                        icon: Icon(
                          post["is_saved"] == true
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        onPressed: _toggleSave,
                      ),
                    ],
                  ),

                  /// 👥 JOIN COMMUNITY
                  if (post["is_member"] == false)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _joinCommunity,
                        child: const Text("Topluluğa Katıl"),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


