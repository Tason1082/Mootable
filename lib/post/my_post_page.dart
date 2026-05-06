import 'package:flutter/material.dart';
import 'package:mootable/post/post_card.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/api_client.dart';
import '../home/home_page_functions.dart';



class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => MyPostsPageState();
}

class MyPostsPageState extends State<MyPostsPage> {
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
    fetchMyPosts();
    _scrollController = ScrollController()
      ..addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      fetchMyPosts(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMyPosts({bool loadMore = false}) async {
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
      final res = await ApiClient.dio.get(
        '/api/posts/me',
        queryParameters: {
          "limit": limit,
          "offset": offset,
        },
      );

      final List rawList = res.data["data"] as List;

      final newPosts = rawList.map<Map<String, dynamic>>((p) {
        final map = Map<String, dynamic>.from(p);

        return {
          ...map,

          // 🔥 PostCard uyumu
          "votes_count": map["netScore"] ?? 0,
          "user_vote": map["userVote"] ?? 0,
          "created_at": map["createdAt"],
          "community": map["community"],
          "communityId": map["communityId"],
          "comment_count": map["commentCount"] ?? 0,
        };
      }).toList();

      if (!mounted) return;

      if (newPosts.isEmpty) {
        hasMore = false;
      } else {
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
      debugPrint("MY POSTS ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
      isLoadingMore = false;
    });
  }
  bool _isVideo(String url) {
    final lower = url.toLowerCase();

    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi') ||
        lower.contains('.mkv') ||
        lower.contains('.webm');
  }
  Widget _buildThumbnail(
      String? mediaUrl,
      String? mediaType,
      String? content,
      String? username,
      String? avatarUrl,
      ) {
    final hasText = content != null && content.trim().isNotEmpty;

    Widget mediaWidget;

    // 📝 TEXT ONLY
    if (mediaUrl == null || mediaUrl.isEmpty) {
      mediaWidget = SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          alignment: Alignment.center,
          color: Colors.grey[200],
          padding: const EdgeInsets.all(8),
          child: Text(
            hasText ? content! : "No content",
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }



    // 🎥 VIDEO
    else if (_isVideo(mediaUrl)) {
      mediaWidget = AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _VideoThumbnail(videoUrl: mediaUrl),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),

            const Center(
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white70, size: 36),
            ),

            if (hasText)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 🖼️ IMAGE
    else {
      mediaWidget = AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.black12,
                  child: const Center(
                    child: Icon(Icons.broken_image),
                  ),
                );
              },
            ),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),

            if (hasText)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      );
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👤 USER HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              if (avatarUrl != null && avatarUrl.isNotEmpty)
                CircleAvatar(
                  radius: 8,
                  backgroundImage: NetworkImage(avatarUrl),
                ),

              if (avatarUrl != null && avatarUrl.isNotEmpty)
                const SizedBox(width: 4),

              Expanded(
                child: Text(
                  username ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 📦 FIXED MEDIA AREA
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              child: mediaWidget,
            ),
          ),
        ),
      ],
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
        onRefresh: () => fetchMyPosts(),
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
            childAspectRatio: 0.75, // 🔥 EKLE
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
            String? mediaType;
            String? mediaUrl;

            if (post["medias"] != null && (post["medias"] as List).isNotEmpty) {
              mediaUrl = post["medias"][0]["url"];
              mediaType = post["medias"][0]["type"]; // image / video
            }
            final content = post["content"]; // backend'e göre değişebilir
            final username = post["username"];
            final avatarUrl = post["profileImageUrl"];
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
                  child: _buildThumbnail(
                    mediaUrl,
                    mediaType,
                    content,
                    username,
                    avatarUrl,
                  )
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
  late List<Map<String, dynamic>> posts; // State listesi
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    posts = widget.posts;
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
        title: const Text("Paylaşımların"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];

          return PostCard(
            post: post,
            parentContext: context,
            onVote: (postId, vote) {
              toggleVote(this, postId, vote);
            },

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