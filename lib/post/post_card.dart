import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../TimeAgo.dart';
import '../comment/comment_page.dart';

import '../core/api_service.dart';
import 'full_screen_image.dart';
import '../my_community/community_detail_page.dart';
import '../profile_page.dart';
import '../quote_post_page.dart';


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

  @override
  void initState() {
    super.initState();

    _checkIfSaved();
    _checkIfJoined(); // sayfa açılır açılmaz katılım kontrolü
  }
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
    } catch (e) {
      debugPrint("Post kaydedilmiş mi kontrol hatası: $e");
      if (mounted) {
        setState(() => _loadingSaved = false);
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_loadingSaved) return;

    final postId = int.parse(widget.post["id"].toString());

    // 1️⃣ Optimistic update: UI'yi hemen değiştir
    setState(() {
      _isSaved = !_isSaved;  // ikon anında değişir
      _loadingSaved = true;  // spinner göstermek için
    });

    try {
      // 2️⃣ API çağrısı
      final saved = await ApiService.toggleSavePost(postId);

      if (mounted) {
        setState(() {
          _isSaved = saved;       // API sonucu ile güncelle
          _loadingSaved = false;  // spinner kapat
        });
      }
    } catch (e) {
      // 3️⃣ Hata durumunda rollback
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;  // önceki duruma geri dön
          _loadingSaved = false;
        });
      }

      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text("Kaydetme hatası: $e")),
      );
    }
  }
  // ================= JOIN / LEAVE =================
  Future<void> _checkIfJoined() async {
    final String communityId = widget.post["communityId"].toString();
    if (communityId == null) return;

    setState(() => _loadingJoin = true);

    try {
      final joined = await ApiService.isJoined(communityId);

      if (mounted) {
        setState(() {
          _isJoined = joined;
          _loadingJoin = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingJoin = false);
      debugPrint("Katılım kontrol hatası: $e");
    }
  }

  Future<void> _toggleJoin() async {
    final String communityId = widget.post["communityId"].toString();
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

      widget.onJoinCommunity?.call(
        widget.post["community"],
        widget.post["id"],
      );
    } catch (e) {
      ScaffoldMessenger.of(widget.parentContext)
          .showSnackBar(SnackBar(content: Text("İşlem başarısız: $e")));
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }




  // ================= VIDEO THUMBNAIL =================


  // ================= MEDIA WIDGET =================
  Widget _buildMediaWidget(String? url) {
    if (url == null) return const SizedBox.shrink();

    final path = Uri.parse(url).path.toLowerCase();

    // ================= VIDEO =================
    if (path.endsWith(".mp4") ||
        path.endsWith(".mov") ||
        path.endsWith(".avi") ||
        path.endsWith(".webm")) {

      return InlineVideoPlayer(url: url);
    }

    // ================= IMAGE =================
    if (path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".gif")) {

      return GestureDetector(
        onTap: () {
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (_) => FullScreenImagePage(imageUrl: url),
            ),
          );
        },
        child: AspectRatio(
          aspectRatio: 7 / 8,
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image));
            },
          ),
        ),
      );
    }

    // ================= UNKNOWN =================
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(widget.parentContext).colorScheme.surfaceVariant,
      child: const Center(child: Text("Desteklenmeyen medya türü")),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final post = widget.post;
    final postId = post["id"];
    final profileImage = post["profileImageUrl"];
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
      radius: 20,
        backgroundColor: colors.surfaceVariant,
        child: ClipOval(
          child: profileImage != null && profileImage.isNotEmpty
              ? Image.network(
            profileImage,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.person),
          )
              : Icon(Icons.person, color: colors.onSurfaceVariant),
        ),
      ),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final username = post["username"];
                    if (username != null) {
                      Navigator.push(
                        widget.parentContext,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(username: username),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "${post["username"] ?? "user"} • ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    final communityName = post["community"];
                    if (communityName != null) {
                      Navigator.push(
                        widget.parentContext,
                        MaterialPageRoute(
                          builder: (_) => CommunityDetailPage(
                            communityName: communityName,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "${post["community"] ?? ""}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              post["created_at"] != null
                  ? TimeAgo.format(widget.parentContext, DateTime.parse(post["created_at"]))
                  : "",
            ),
            trailing: _loadingJoin
                ? const SizedBox(
              width: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
                : (!_isJoined
                ? TextButton(
              onPressed: _toggleJoin,
              child: const Text("Katıl"),
            )
                : const SizedBox.shrink()),
          ),

          if (post["imageUrl"] != null || post["image_url"] != null)
            _buildMediaWidget(post["imageUrl"] ?? post["image_url"]),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              post["content"] ?? "",
              style: theme.textTheme.bodyMedium,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: post["user_vote"] == 1 ? colors.primary : colors.onSurfaceVariant,
                  ),
                  onPressed: () => widget.onVote?.call(postId, 1),
                ),
                Text("${post["votes_count"] ?? 0}"),
                IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: post["user_vote"] == -1 ? colors.error : colors.onSurfaceVariant,
                  ),
                  onPressed: () => widget.onVote?.call(postId, -1),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
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
                  onPressed: _loadingSaved ? null : _toggleSave,
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: _loadingSaved
                        ? SizedBox(
                      key: ValueKey("spinner"),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _isSaved ? Colors.orange : Colors.grey,
                      ),
                    )
                        : Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      key: ValueKey("icon"),
                      color: _isSaved ? Colors.orange : Colors.grey,
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}