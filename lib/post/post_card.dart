import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../TimeAgo.dart';
import '../comment/comment_page.dart';
import '../core/api_client.dart';
import '../core/api_service.dart';
import '../my_community/community_detail_page.dart';
import '../quote_post_page.dart';
import '../video_player_widget.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
  Uint8List? videoThumbnail;
  bool _isSaved = false;
  bool _loadingSaved = true;
  bool _isJoined = false;
  bool _loadingJoin = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _generateVideoThumbnail();
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
  Future<void> _generateVideoThumbnail() async {
    final url = widget.post["imageUrl"] ?? widget.post["image_url"];
    if (url == null) return;
    final path = Uri.parse(url).path.toLowerCase();

    if (path.endsWith(".mp4") ||
        path.endsWith(".mov") ||
        path.endsWith(".avi") ||
        path.endsWith(".webm")) {
      final thumb = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );
      if (!mounted) return;
      setState(() => videoThumbnail = thumb);
    }
  }

  // ================= MEDIA WIDGET =================
  Widget _buildMediaWidget(String? url) {
    if (url == null) return const SizedBox.shrink();
    final path = Uri.parse(url).path.toLowerCase();

    if (path.endsWith(".mp4") ||
        path.endsWith(".mov") ||
        path.endsWith(".avi") ||
        path.endsWith(".webm")) {
      if (videoThumbnail == null) {
        return const AspectRatio(
          aspectRatio: 1,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (_) => VideoPlayerWidget(videoUrl: url),
            ),
          );
        },
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.memory(
                videoThumbnail!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".gif")) {
      return AspectRatio(
        aspectRatio: 7 / 8,
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image));
          },
        ),
      );
    }

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

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.surfaceVariant,
              child: Icon(Icons.groups, color: colors.onSurfaceVariant),
            ),
            title: Row(
              children: [
                Text("${post["username"] ?? "user"} • "),

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
                Text("${post["comment_count"] ?? 0}"),
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