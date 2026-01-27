import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'comment/comment_page.dart';

class UserPostsPage extends StatefulWidget {
  final String userId;
  final String username;

  const UserPostsPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  // Video controllers keyed by post id
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoMuted = {};
  final Set<int> _initializingVideos = {};

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.pause();
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  bool _looksLikeVideoUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.ogg');
  }

  Future<void> _initializeVideoForPost(int postId, String url) async {
    if (_videoControllers.containsKey(postId) || _initializingVideos.contains(postId)) return;
    _initializingVideos.add(postId);

    try {
      final controller = VideoPlayerController.network(url);
      _videoControllers[postId] = controller;
      _videoMuted[postId] = true; // start muted

      await controller.initialize();
      controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (mounted) setState(() {});
    } catch (e) {
      // initialization failed - remove any partial controller
      _videoControllers.remove(postId)?.dispose();
      // ignore error; UI will fall back to showing nothing or a placeholder
      debugPrint('Video init error for post $postId: $e');
    } finally {
      _initializingVideos.remove(postId);
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final posts = await Supabase.instance.client
          .from('posts')
          .select('id, content, image_url, created_at')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> postsWithExtras = [];

      for (var post in posts) {
        final votes = await Supabase.instance.client
            .from("votes")
            .select("vote")
            .eq("post_id", post["id"]);

        final upvotes = votes.where((v) => v["vote"] == 1).length;
        final downvotes = votes.where((v) => v["vote"] == -1).length;

        final comments = await Supabase.instance.client
            .from("comments")
            .select("id")
            .eq("post_id", post["id"]);

        postsWithExtras.add({
          ...post,
          "votes_count": upvotes - downvotes,
          "comment_count": comments.length,
        });
      }

      setState(() {
        _posts = postsWithExtras;
        _loading = false;
      });

      // Initialize video controllers for posts that look like videos (optional: do this lazily)
      for (var post in _posts) {
        final url = post['image_url'] as String?;
        if (_looksLikeVideoUrl(url)) {
          final id = post['id'] as int;
          _initializeVideoForPost(id, url!);
        }
      }
    } catch (e) {
      print("User posts error: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      await Supabase.instance.client.from("posts").delete().eq("id", postId);
      setState(() {
        _posts.removeWhere((p) => p["id"] == postId);
      });
      // dispose video controller if existed
      _videoControllers.remove(postId)?.dispose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gönderi silindi")),
      );
    } catch (e) {
      print("Silme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silme işlemi başarısız!")),
      );
    }
  }

  void _editPostDialog(Map<String, dynamic> post) {
    final TextEditingController controller =
    TextEditingController(text: post["content"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gönderiyi Düzenle"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Yeni içeriği yazın...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from("posts")
                    .update({"content": controller.text})
                    .eq("id", post["id"]);
                Navigator.pop(context);
                _fetchUserPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gönderi güncellendi")),
                );
              } catch (e) {
                print("Düzenleme hatası: $e");
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget(Map<String, dynamic> post) {
    final url = post['image_url'] as String?;
    final id = post['id'] as int;

    if (url == null || url.isEmpty) return const SizedBox.shrink();

    if (_looksLikeVideoUrl(url)) {
      final controller = _videoControllers[id];

      if (controller == null || !controller.value.isInitialized) {
        // still initializing or failed
        return SizedBox(
          height: 200,
          child: Center(
            child: _initializingVideos.contains(id)
                ? const CircularProgressIndicator()
                : const Icon(Icons.videocam, size: 48, color: Colors.grey),
          ),
        );
      }

      final isMuted = _videoMuted[id] ?? true;

      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(controller),
            // Play/pause on tap
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                  setState(() {});
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // Sound toggle button (bottom-right)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: () async {
                    final newMuted = !(isMuted);
                    _videoMuted[id] = newMuted;
                    await controller.setVolume(newMuted ? 0 : 1);
                    setState(() {});
                  },
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // regular image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.username} • Paylaşımların"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text("Henüz bir paylaşım yapmadın."))
          : RefreshIndicator(
        onRefresh: _fetchUserPosts,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post["created_at"].toString(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == "edit") {
                              _editPostDialog(post);
                            } else if (value == "delete") {
                              _deletePost(post["id"]);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "edit",
                              child: Text("Düzenle"),
                            ),
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("Sil"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post["content"] ?? "",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildMediaWidget(post),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward,
                            color: Colors.green, size: 20),
                        const Icon(Icons.arrow_downward,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "${post["votes_count"] ?? 0} oy",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.comment_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "${post["comment_count"] ?? 0} yorum",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommentPage(postId: post["id"]),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
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
    );
  }
}

