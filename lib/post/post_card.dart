import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../TimeAgo.dart';
import '../comment/comment_page.dart';
import '../core/api_service.dart';
import '../my_community/community_detail_page.dart';
import '../profile_page.dart';
import '../quote_post_page.dart';
import 'full_screen_image.dart';
import 'inline_video_player.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final BuildContext parentContext;

  final void Function(int postId, int vote)? onVote;
  final void Function(String communityName, int index)? onJoinCommunity;

  const PostCard({
    super.key,
    required this.post,
    required this.parentContext,
    this.onVote,
    this.onJoinCommunity,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isSaved = false;
  bool _loadingSaved = true;

  bool _isJoined = false;
  bool _loadingJoin = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _currentIndex = 0; // 🔥 carousel index

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _checkIfJoined();
  }

  // ================= SAVE =================
  Future<void> _checkIfSaved() async {
    final postId = int.parse(widget.post["id"].toString());

    try {
      final isSaved = await ApiService.isPostSaved(postId);

      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _loadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_loadingSaved) return;

    final postId = int.parse(widget.post["id"].toString());

    setState(() {
      _isSaved = !_isSaved;
      _loadingSaved = true;
    });

    try {
      final saved = await ApiService.toggleSavePost(postId);

      if (mounted) {
        setState(() {
          _isSaved = saved;
          _loadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
          _loadingSaved = false;
        });
      }
    }
  }

  // ================= JOIN =================
  Future<void> _checkIfJoined() async {
    final communityId = widget.post["communityId"]?.toString();
    if (communityId == null) return;

    try {
      final joined = await ApiService.isJoined(communityId);

      if (mounted) {
        setState(() {
          _isJoined = joined;
          _loadingJoin = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  Future<void> _toggleJoin() async {
    final communityId = widget.post["communityId"]?.toString();
    if (communityId == null) return;

    setState(() => _loadingJoin = true);

    try {
      if (_isJoined) {
        await ApiService.leaveCommunity(communityId);
        _isJoined = false;
      } else {
        await ApiService.joinCommunity(communityId);
        _isJoined = true;
      }

      if (mounted) setState(() {});
    } catch (_) {
      ScaffoldMessenger.of(widget.parentContext)
          .showSnackBar(const SnackBar(content: Text("İşlem başarısız")));
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  // ================= MEDIA =================
  Widget _buildMedia(List medias) {
    if (medias.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: medias.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final media = medias[index];
              final url = media["url"];
              final type = media["type"];

              if (url == null) return const SizedBox.shrink();

              // VIDEO
              if (type == "video") {
                return InlineVideoPlayer(url: url);
              }

              // IMAGE
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(imageUrl: url),
                    ),
                  );
                },
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),

        if (medias.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(medias.length, (index) {
              return Container(
                margin: const EdgeInsets.all(3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.black
                      : Colors.grey,
                ),
              );
            }),
          ),
      ],
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final postId = post["id"];
    final medias = post["medias"] as List<dynamic>? ?? [];

    final profileImage = post["profileImageUrl"];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          ListTile(
            leading: CircleAvatar(
              child: profileImage != null && profileImage.toString().isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  profileImage,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(Icons.person),
            ),
            title: Row(
              children: [
                Text(post["username"] ?? "user",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text(post["community"] ?? "",
                    style: TextStyle(color: colors.primary)),
              ],
            ),
            subtitle: Text(
              post["created_at"] != null
                  ? TimeAgo.format(
                context,
                DateTime.parse(post["created_at"]),
              )
                  : "",
            ),
            trailing: _loadingJoin
                ? const CircularProgressIndicator(strokeWidth: 2)
                : (!_isJoined
                ? TextButton(
              onPressed: _toggleJoin,
              child: const Text("Katıl"),
            )
                : const SizedBox.shrink()),
          ),

          // 🔥 MEDIA
          if (medias.isNotEmpty) _buildMedia(medias),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(post["content"] ?? ""),
          ),

          // ACTIONS
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: post["user_vote"] == 1
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                onPressed: () => widget.onVote?.call(postId, 1),
              ),
              Text("${post["votes_count"] ?? 0}"),
              IconButton(
                icon: Icon(
                  Icons.arrow_downward,
                  color: post["user_vote"] == -1
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
                onPressed: () => widget.onVote?.call(postId, -1),
              ),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) => CommentPage(postId: postId),
                    ),
                  );
                },
              ),
              Text("${post["commentCount"] ?? 0}"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: () {
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) => QuotePostPage(post: post),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: _toggleSave,
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),

          const Divider(),
        ],
      ),
    );
  }
}