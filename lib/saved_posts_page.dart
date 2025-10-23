import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class SavedPostsPage extends StatefulWidget {
  final String userId;
  const SavedPostsPage({super.key, required this.userId});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  List<Map<String, dynamic>> _savedPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
  }

  Future<void> _fetchSavedPosts() async {
    final saves = await Supabase.instance.client
        .from("saves")
        .select("post_id")
        .eq("user_id", widget.userId);

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
      _savedPosts = posts;
      _loading = false;
    });
  }

  bool _isVideo(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kaydedilen Gönderiler")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
          ? const Center(child: Text("Henüz kaydedilen gönderi yok."))
          : ListView.builder(
        itemCount: _savedPosts.length,
        itemBuilder: (context, index) {
          final post = _savedPosts[index];
          final profile = post["profiles"];
          final imageUrl = post["image_url"];

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profile?["avatar_url"] != null
                        ? NetworkImage(profile["avatar_url"])
                        : null,
                    child: profile?["avatar_url"] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(profile?["username"] ?? "Anonim"),
                  subtitle:
                  Text(post["created_at"].toString().substring(0, 16)),
                ),

                // 🔍 Görsel veya video kontrolü
                if (imageUrl != null && imageUrl.isNotEmpty)
                  _isVideo(imageUrl)
                      ? _VideoPlayerWidget(videoUrl: imageUrl)
                      : ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      fit: BoxFit.contain,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(post["content"] ?? ""),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true; // 🔇 Başlangıçta sessiz

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _controller.setVolume(0.0); // sessiz başlat
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

          // ▶️ / ⏸️ Oynatma butonu
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

          // 🔊 Ses aç/kapa butonu (sağ alt köşede)
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
