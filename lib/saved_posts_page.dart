import 'package:flutter/material.dart';
import 'package:mootable/post/post_card.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/api_client.dart';
import 'package:dio/dio.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _savedPosts = [];
  bool _loading = true;

  int _limit = 15;
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchSavedPosts(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedPosts({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;

    if (!loadMore) {
      setState(() {
        _loading = true;
        _offset = 0;
        _hasMore = true;
      });
    }

    setState(() => _isLoadingMore = true);

    try {
      final token = await _storage.read(key: "jwt_token");

      final response = await ApiClient.dio.get(
        "/api/posts/save/me",
        queryParameters: {
          "limit": _limit,
          "offset": _offset,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List data = response.data;

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        final newPosts = List<Map<String, dynamic>>.from(data);

        if (loadMore) {
          _savedPosts.addAll(newPosts);
        } else {
          _savedPosts = newPosts;
        }

        _offset += _limit;
      }
    } catch (e) {
      debugPrint("SavedPosts fetch error: $e");
    }

    setState(() {
      _loading = false;
      _isLoadingMore = false;
    });
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  Widget _buildThumbnail(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (_isVideo(mediaUrl)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _VideoThumbnail(videoUrl: mediaUrl),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 36,
            ),
          ),
        ],
      );
    }

    return Image.network(
      mediaUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  // Grid içindeki PostCard toggle save durumunu güncelle
  void _updatePostSavedState(int postId, bool isSaved) {
    final index = _savedPosts.indexWhere((p) => p["id"] == postId);
    if (index != -1) {
      setState(() {
        _savedPosts[index]["is_saved"] = isSaved;
        if (!isSaved) {
          // eğer kaydı kaldırıldıysa grid’den de silebiliriz
          _savedPosts.removeAt(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.saved_posts_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
          ? Center(child: Text(l10n.no_saved_posts))
          : RefreshIndicator(
        onRefresh: () async {
          _offset = 0;
          _hasMore = true;
          await _fetchSavedPosts();
        },
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(4),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _savedPosts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _savedPosts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = _savedPosts[index];
            final mediaUrl = post["image_url"];

            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.95,
                    builder: (_, controller) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        child: PostCard(
                          post: post,
                          parentContext: context,
                          onVote: (postId, vote) {
                            // opsiyonel: burada oy işlemi handle edilebilir
                          },
                          onJoinCommunity: (communityName, index) {
                            // opsiyonel: topluluğa katılma
                          },

                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildThumbnail(mediaUrl),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _controller
          ..setVolume(0)
          ..setLooping(true)
          ..play();
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? VideoPlayer(_controller)
        : Container(color: Colors.grey[300]);
  }
}