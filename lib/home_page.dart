import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart'; // ✅ Video oynatıcı eklendi
import 'login_page.dart';
import 'comment_page.dart';
import 'post_page.dart';
import 'user_posts_page.dart';
import 'saved_posts_page.dart';
import 'TimeAgo.dart';

// ✅ Yeni doğru import
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// 🔹 Profil Düzenleme Sayfası
class EditProfilePage extends StatefulWidget {
  final String userId;
  final String? initialUsername;
  final String? initialBio;

  const EditProfilePage({
    super.key,
    required this.userId,
    this.initialUsername,
    this.initialBio,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername ?? '');
    _bioController = TextEditingController(text: widget.initialBio ?? '');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      }).eq('id', widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla güncellendi ✅")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil güncellenemedi ❌")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profilini Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Kullanıcı Adı",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Kullanıcı adını gir",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? "Kullanıcı adı boş olamaz" : null,
              ),
              const SizedBox(height: 20),
              const Text("Hakkında (isteğe bağlı)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Kendini kısaca tanıt...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _saveProfile,
                  icon: const Icon(Icons.save),
                  label: _saving
                      ? const Text("Kaydediliyor...", style: TextStyle(color: Colors.white))
                      : const Text("Kaydet", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Ana Sayfa
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  final user = Supabase.instance.client.auth.currentUser;
  String? username;
  String? bio;
  String? profileImageUrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from("profiles")
        .select("username, bio, avatar_url")
        .eq("id", user!.id)
        .maybeSingle();

    setState(() {
      username = profile?["username"] ?? "Anonim";
      bio = profile?["bio"];
      profileImageUrl = profile?["avatar_url"];
    });
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final file = File(picked.path);
      final fileName = "${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await Supabase.instance.client.storage.from('avatars').upload(fileName, file);
      final publicUrl =
      Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user!.id);

      setState(() => profileImageUrl = publicUrl);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profil fotoğrafı güncellendi ✅")));
    } catch (e) {
      print("Profil yükleme hatası: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profil yüklenemedi!")));
    }
  }

  Future<void> _fetchPosts() async {
    final posts = await Supabase.instance.client
        .from("posts")
        .select("id, content, image_url, created_at, user_id")
        .order("created_at", ascending: false);

    List<Map<String, dynamic>> postsWithExtras = [];
    for (var post in posts) {
      final profile = await Supabase.instance.client
          .from("profiles")
          .select("username, avatar_url")
          .eq("id", post["user_id"])
          .maybeSingle();

      final votes = await Supabase.instance.client
          .from("votes")
          .select("user_id, vote")
          .eq("post_id", post["id"]);

      final comments =
      await Supabase.instance.client.from("comments").select("id").eq("post_id", post["id"]);

      final saved = await Supabase.instance.client
          .from("saves")
          .select("id")
          .eq("post_id", post["id"])
          .eq("user_id", user!.id)
          .maybeSingle();

      final upvotes = votes.where((v) => v["vote"] == 1).length;
      final downvotes = votes.where((v) => v["vote"] == -1).length;
      final userVote = votes.firstWhere((v) => v["user_id"] == user?.id,
          orElse: () => {"vote": 0})["vote"];

      postsWithExtras.add({
        ...post,
        "profiles": profile,
        "votes_count": upvotes - downvotes,
        "user_vote": userVote,
        "comment_count": comments.length,
        "is_saved": saved != null,
      });
    }

    setState(() {
      _posts = postsWithExtras;
      _loading = false;
    });
  }

  Future<void> _toggleVote(int postId, int vote) async {
    final userId = user?.id;
    if (userId == null) return;

    // 🔹 Hemen UI'da tepki verelim
    setState(() {
      final index = _posts.indexWhere((p) => p["id"] == postId);
      if (index != -1) {
        final post = _posts[index];
        int currentVote = post["user_vote"];
        int currentCount = post["votes_count"];

        if (currentVote == vote) {
          // Aynı oy -> kaldır
          post["user_vote"] = 0;
          post["votes_count"] = currentCount - vote;
        } else {
          // Farklı oy -> güncelle
          post["votes_count"] = currentCount - currentVote + vote;
          post["user_vote"] = vote;
        }
      }
    });

    // 🔹 Supabase güncellemesi arka planda
    try {
      final existingVote = await Supabase.instance.client
          .from("votes")
          .select("vote")
          .eq("post_id", postId)
          .eq("user_id", userId)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote["vote"] == vote) {
          await Supabase.instance.client
              .from("votes")
              .delete()
              .eq("post_id", postId)
              .eq("user_id", userId);
        } else {
          await Supabase.instance.client
              .from("votes")
              .update({"vote": vote})
              .eq("post_id", postId)
              .eq("user_id", userId);
        }
      } else {
        await Supabase.instance.client
            .from("votes")
            .insert({"post_id": postId, "user_id": userId, "vote": vote});
      }
    } catch (e) {
      print("Vote error: $e");
    }
  }

  Future<void> _toggleSave(int postId, bool currentlySaved) async {
    final userId = user?.id;
    if (userId == null) return;

    // 🔹 UI'da anında tepki
    setState(() {
      final index = _posts.indexWhere((p) => p["id"] == postId);
      if (index != -1) {
        _posts[index]["is_saved"] = !currentlySaved;
      }
    });

    // 🔹 Arka planda Supabase isteği
    try {
      if (currentlySaved) {
        await Supabase.instance.client
            .from("saves")
            .delete()
            .eq("post_id", postId)
            .eq("user_id", userId);
      } else {
        await Supabase.instance.client
            .from("saves")
            .insert({"post_id": postId, "user_id": userId});
      }
    } catch (e) {
      print("Save error: $e");
    }
  }


  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PostAddPage()))
          .then((_) => _fetchPosts());
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // ✅ FOTO/VIDEO otomatik ayırıcı
  Widget _buildMediaWidget(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.endsWith(".mp4") ||
        lowerUrl.endsWith(".mov") ||
        lowerUrl.endsWith(".avi") ||
        lowerUrl.endsWith(".webm")) {
      return AspectRatio(
        aspectRatio: 1,
        child: VideoPlayerWidget(videoUrl: url),
      );
    } else if (lowerUrl.endsWith(".jpg") ||
        lowerUrl.endsWith(".jpeg") ||
        lowerUrl.endsWith(".png") ||
        lowerUrl.endsWith(".gif")) {
      return Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade200,
        child: const Center(child: Text("Desteklenmeyen medya türü.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text("Mootable"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                child: profileImageUrl == null ? const Icon(Icons.person, size: 22) : null,
              ),
            ),
          ),
        ],
      ),

      endDrawer: FractionallySizedBox(
        widthFactor: 0.55,
        child: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    AppLocalizations.of(context)!.profile,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Divider(),
                Center(
                  child: GestureDetector(
                    onTap: _uploadProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                      profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                      child: profileImageUrl == null
                          ? const Icon(Icons.add_a_photo, size: 30)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    username != null
                        ? "@$username"
                        : AppLocalizations.of(context)!.loadingUser,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (bio != null && bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(AppLocalizations.of(context)!.editProfile),
                  onTap: () async {
                    if (user != null) {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            userId: user!.id,
                            initialUsername: username,
                            initialBio: bio,
                          ),
                        ),
                      );
                      if (updated == true) _fetchUserProfile();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(AppLocalizations.of(context)!.yourPosts),
                  onTap: () {
                    if (user != null && username != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPostsPage(
                            userId: user!.id,
                            username: username!,
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(AppLocalizations.of(context)!.savedPosts),
                  onTap: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SavedPostsPage(userId: user!.id),
                        ),
                      );
                    }
                  },
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),


      // 🔹 Gönderiler
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchPosts,
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            final profile = post["profiles"];
            final postId = post["id"];
            final isSaved = post["is_saved"] == true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile?["avatar_url"] != null
                          ? NetworkImage(profile["avatar_url"])
                          : null,
                      child: profile?["avatar_url"] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(profile?["username"] ?? "Anonim"),
                    subtitle: Text(
                      TimeAgo.format(DateTime.parse(post["created_at"])),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  if (post["image_url"] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMediaWidget(post["image_url"]), // ✅ yeni kısım
                    ),
                  Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(post["content"] ?? "")),
                  Row(children: [
                    IconButton(
                        icon: Icon(Icons.arrow_upward,
                            color: post["user_vote"] == 1 ? Colors.green : Colors.grey),
                        onPressed: () => _toggleVote(postId, 1)),
                    Text("${post["votes_count"] ?? 0}"),
                    IconButton(
                        icon: Icon(Icons.arrow_downward,
                            color: post["user_vote"] == -1 ? Colors.red : Colors.grey),
                        onPressed: () => _toggleVote(postId, -1)),
                    const SizedBox(width: 10),
                    IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CommentPage(postId: postId)));
                        }),
                    Text("${post["comment_count"] ?? 0}"),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.blue : Colors.grey,
                      ),

                      onPressed: () => _toggleSave(postId, isSaved),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ),

      // 🔹 Alt Navigasyon Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_3_outlined), label: "Topluluklar"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: "Oluştur"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Sohbet"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Gelen Kutusu"),
        ],
      ),
    );
  }
}



class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Cihaz türüne göre boyutlandırma (örnek)
    double containerHeight;
    if (screenWidth >= 1000) {
      // 💻 Masaüstü
      containerHeight = screenHeight * 0.6;
    } else if (screenWidth >= 600) {
      // 📱 Tablet
      containerHeight = screenHeight * 0.5;
    } else {
      // 📱 Telefon
      containerHeight = screenHeight * 0.5;
    }

    return Center(
      child: Container(
        width: screenWidth * 0.7, // biraz kenarlık bırakalım
        height: containerHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              if (_showControls)
                Positioned(
                  bottom: 12,
                  right: 12,
                  left: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
