import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../TimeAgo.dart';
import '../comment/comment_page.dart';
import '../core/api_client.dart';
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _generateVideoThumbnail();
    _checkIfSaved(); // ekran açılır açılmaz backend kontrolü
  }

  // Backend ile kaydedilmiş mi kontrol et
  Future<void> _checkIfSaved() async {
    final postId = int.parse(widget.post["id"].toString());

    try {
      final token = await _storage.read(key: "jwt_token");
      final response = await ApiClient.dio.get(
        "/api/posts/save/is_saved/$postId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final isSaved = response.data?["isSaved"] ?? false;

      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _loadingSaved = false;
        });
      }
    } catch (e) {
      debugPrint("Post kaydedilmiş mi kontrol hatası: $e");
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  // Video thumbnail üretme
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

  // Kaydetme / kaydı kaldırma
  Future<void> _toggleSave() async {
    if (_loadingSaved) return; // toggle sırasında tekrar tıklanmasın
    final postId = int.parse(widget.post["id"].toString());
    setState(() => _loadingSaved = true);

    try {
      final token = await _storage.read(key: "jwt_token");
      final response = await ApiClient.dio.post(
        "/api/posts/save",
        data: {"postId": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final saved = response.data?["saved"] ?? false;

      if (mounted) {
        setState(() {
          _isSaved = saved;
          _loadingSaved = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSaved = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text("Kaydetme hatası: $e")),
      );
    }
  }

  // Medya widget
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(
              videoThumbnail!,
              width: double.infinity,
              height: 200,
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
      );
    }

    if (path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".gif")) {
      return Image.network(
        url,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image));
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(widget.parentContext).colorScheme.surfaceVariant,
      child: const Center(child: Text("Desteklenmeyen medya türü")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final post = widget.post;
    final postId = post["id"];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.surfaceVariant,
              child: Icon(Icons.groups, color: colors.onSurfaceVariant),
            ),
            title: Text(
              post["community"] ?? "",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              post["created_at"] != null
                  ? TimeAgo.format(
                  widget.parentContext, DateTime.parse(post["created_at"]))
                  : "",
            ),
            trailing: post["is_member"] != true
                ? TextButton(
              onPressed: () =>
                  widget.onJoinCommunity?.call(post["community"], 0),
              child: const Text("Katıl"),
            )
                : null,
          ),
          if (post["imageUrl"] != null || post["image_url"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(post["imageUrl"] ?? post["image_url"]),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                _loadingSaved
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved
                        ? Colors.orange
                        : colors.onSurfaceVariant,
                  ),
                  onPressed: _toggleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}