import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../community_explore_page.dart';
import '../login_page.dart';
import '../comment_page.dart';
import '../post_page.dart';
import '../user_posts_page.dart';
import '../saved_posts_page.dart';
import '../TimeAgo.dart';
import 'dart:typed_data' as typed_data;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../video_player_widget.dart';
import '../community/CreateCommunityPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../edit_profile_page.dart';
import '../settings_page.dart';

// YENİ MENÜ DOSYALARI
import 'left_menu.dart';
import 'right_profile_drawer.dart';

// 🔹 Fonksiyonları import ediyoruz
import 'home_page_functions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> posts = [];
  bool loading = true;
  final user = Supabase.instance.client.auth.currentUser;
  String? username;
  String? bio;
  String? profileImageUrl;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;

  // Sayfalama
  int limit = 5;
  int offset = 0;
  bool isLoadingMore = false;
  bool hasMore = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    fetchPosts(this); // 🔹 Fonksiyon dosyasından çağırıyoruz
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        fetchPosts(this, loadMore: true);
      }
    });
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      final fileName =
          "${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user!.id);

      setState(() => profileImageUrl = publicUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil fotoğrafı güncellendi ✅")),
      );
    } catch (e) {
      print("Profil yükleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil yüklenemedi!")),
      );
    }
  }

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
      key: scaffoldKey,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => openLeftSideSheet(context),
        ),
        title: Image.asset(
          'assets/logoTansparent.png',
          height: 40,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => scaffoldKey.currentState?.openEndDrawer(),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, size: 22)
                    : null,
              ),
            ),
          ),
        ],
      ),

      endDrawer: RightProfileDrawer(
        profileImageUrl: profileImageUrl,
        username: username,
        bio: bio,
        onUploadProfileImage: _uploadProfileImage,
        refreshProfile: _fetchUserProfile,
      ),

      body: loading && posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => fetchPosts(this),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              if (isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            final post = posts[index];
            final profile = post["profiles"];
            final postId = post["id"];
            final isSaved = post["is_saved"] == true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    subtitle: Text(
                      TimeAgo.format(
                        context,
                        DateTime.parse(post["created_at"]),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (post["image_url"] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMediaWidget(post["image_url"]),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(post["content"] ?? ""),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: post["user_vote"] == 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () => toggleVote(this, postId, 1),
                      ),
                      Text("${post["votes_count"] ?? 0}"),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: post["user_vote"] == -1
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () => toggleVote(this, postId, -1),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommentPage(postId: postId),
                            ),
                          );
                        },
                      ),
                      Text("${post["comment_count"] ?? 0}"),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () => toggleSave(this, postId, isSaved),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => onItemTapped(this, index),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_3_outlined),
            label: AppLocalizations.of(context)!.communities,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_box_outlined),
            label: AppLocalizations.of(context)!.create,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: AppLocalizations.of(context)!.chat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none),
            label: AppLocalizations.of(context)!.inbox,
          ),
        ],
      ),
    );
  }
}

