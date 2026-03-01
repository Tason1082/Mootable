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
  State<SavedPostsPage> createState() => SavedPostsPageState();
}

class SavedPostsPageState extends State<SavedPostsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> posts = [];
  bool loading = true;

  int limit = 6;
  int offset = 0;
  bool isLoadingMore = false;
  bool hasMore = true;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    fetchSavedPosts();
    _scrollController = ScrollController()
      ..addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      fetchSavedPosts(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchSavedPosts({bool loadMore = false}) async {
    if (isLoadingMore) return;
    if (!hasMore && loadMore) return;

    if (!loadMore) {
      setState(() {
        loading = true;
        offset = 0;
        hasMore = true;
      });
    }

    setState(() => isLoadingMore = true);

    try {
      final token = await _storage.read(key: "jwt_token");

      final response = await ApiClient.dio.get(
        "/api/posts/save/me",
        queryParameters: {
          "limit": limit,
          "offset": offset,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final List data = response.data;

      if (!mounted) return;

      if (data.isEmpty) {
        hasMore = false;
      } else {
        final newPosts = List<Map<String, dynamic>>.from(data);

        setState(() {
          if (loadMore) {
            posts.addAll(newPosts);
          } else {
            posts = newPosts;
          }
          offset += limit;
        });
      }
    } catch (e) {
      debugPrint("SavedPosts fetch error: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
      isLoadingMore = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saved_posts_title),
      ),
      body: loading && posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => fetchSavedPosts(),
        child: posts.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 200),
            Center(child: Text(l10n.no_saved_posts)),
          ],
        )
            : GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(4),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return isLoadingMore
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
                  : const SizedBox.shrink();
            }

            final post = posts[index];
            final mediaUrl = post["imageUrl"];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SavedPostsViewer(
                      posts: posts,
                      initialIndex: index,
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
class SavedPostsViewer extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const SavedPostsViewer({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<SavedPostsViewer> createState() => _SavedPostsViewerState();
}

class _SavedPostsViewerState extends State<SavedPostsViewer> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Tıklanan posttan başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = widget.initialIndex * 500.0;
      _scrollController.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Posts"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];

          return PostCard(
            post: post,
            parentContext: context,
            onVote: (postId, vote) {},
            onJoinCommunity: (communityName, index) {},
          );
        },
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
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
    VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setVolume(0)
          ..setLooping(true)
          ..play();
        setState(() => initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return initialized
        ? FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    )
        : Container(color: Colors.grey[300]);
  }
}