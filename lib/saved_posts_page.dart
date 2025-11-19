import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class SavedPostsPage extends StatefulWidget {
  final String userId;
  const SavedPostsPage({super.key, required this.userId});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  List<Map<String, dynamic>> _savedPosts = [];
  bool _loading = true;

  // ✅ Sayfalama değişkenleri
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchSavedPosts(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedPosts({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;

    if (!loadMore) setState(() => _loading = true);
    setState(() => _isLoadingMore = true);

    // 🔹 15'er 15'er kaydedilen post ID'lerini çekiyoruz
    final saves = await Supabase.instance.client
        .from("saves")
        .select("post_id")
        .eq("user_id", widget.userId)
        .range(_offset, _offset + _limit - 1)
        .order("id", ascending: false);

    if (saves.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
        _loading = false;
      });
      return;
    }

    List<Map<String, dynamic>> posts = [];

    for (var save in saves) {
      final post = await Supabase.instance.client
          .from("posts")
          .select("id, content, image_url, created_at, user_id")
          .eq("id", save["post_id"])
          .maybeSingle();

      if (post != null) {
        final profile = await Supabase.instance.client
            .from("profiles")
            .select("username, avatar_url")
            .eq("id", post["user_id"])
            .maybeSingle();
        posts.add({...post, "profiles": profile});
      }
    }

    setState(() {
      if (loadMore) {
        _savedPosts.addAll(posts);
      } else {
        _savedPosts = posts;
      }
      _offset += _limit;
      _isLoadingMore = false;
      _loading = false;
    });
  }

  bool _isVideo(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm');
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (_isVideo(imageUrl)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Küçük video önizlemesi
          _VideoThumbnail(videoUrl: imageUrl),
          const Center(
            child: Icon(Icons.play_circle_fill,
                color: Colors.white70, size: 36),
          ),
        ],
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, color: Colors.grey),
      );
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
            crossAxisCount: 3, // ✅ 3 sütun
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _savedPosts.length + 1,
          itemBuilder: (context, index) {
            if (index == _savedPosts.length) {
              if (_hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            final post = _savedPosts[index];
            final imageUrl = post["image_url"];
            return GestureDetector(
              onTap: () {
                // 🔹 İstersen burada tıklanınca gönderiyi detaylı gösterebilirsin
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding:
                    const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _isVideo(imageUrl)
                            ? _VideoPlayerWidget(videoUrl: imageUrl)
                            : Image.network(imageUrl,
                            fit: BoxFit.contain),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildThumbnail(imageUrl),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 🔹 Küçük video thumbnail (önizleme) için sessiz video widget
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
        _controller.setVolume(0);
        _controller.play();
        _controller.setLooping(true);
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

// 🔹 Tam video oynatma widget (diyalog içinde)
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _controller.setVolume(0.0);
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleMute,
            ),
          ),
        ],
      ),
    );
  }
}

