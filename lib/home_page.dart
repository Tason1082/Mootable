import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'community_explore_page.dart';
import 'login_page.dart';
import 'comment_page.dart';
import 'post_page.dart';
import 'user_posts_page.dart';
import 'saved_posts_page.dart';
import 'TimeAgo.dart';
import 'dart:typed_data' as typed_data;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'video_player_widget.dart';
import 'community/CreateCommunityPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

// YENİ MENÜ DOSYALARI
import 'left_menu.dart';
import 'right_profile_drawer.dart';

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

  // Sayfalama
  int _limit = 5;
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchPosts(loadMore: true);
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

  Future<void> _fetchPosts({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;

    if (!loadMore) setState(() => _loading = true);
    setState(() => _isLoadingMore = true);

    final List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from("posts")
          .select("id, content, image_url, created_at, user_id")
          .order("created_at", ascending: false)
          .range(_offset, _offset + _limit - 1),
    );

    if (posts.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
        _loading = false;
      });
      return;
    }

    List<Map<String, dynamic>> postsWithExtras = [];
    for (var post in posts) {
      final profileMap = await Supabase.instance.client
          .from("profiles")
          .select("username, avatar_url")
          .eq("id", post["user_id"])
          .maybeSingle();

      final votesList = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from("votes")
            .select("user_id, vote")
            .eq("post_id", post["id"]),
      );

      final commentsList = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from("comments")
            .select("id")
            .eq("post_id", post["id"]),
      );

      final savedMap = await Supabase.instance.client
          .from("saves")
          .select("id")
          .eq("post_id", post["id"])
          .eq("user_id", user!.id)
          .maybeSingle();

      final upvotes = votesList.where((v) => v["vote"] == 1).length;
      final downvotes = votesList.where((v) => v["vote"] == -1).length;
      final userVote =
          votesList.firstWhere(
                (v) => v["user_id"] == user?.id,
            orElse: () => {"vote": 0},
          )["vote"] ??
              0;

      postsWithExtras.add({
        ...post,
        "profiles": profileMap,
        "votes_count": upvotes - downvotes,
        "user_vote": userVote,
        "comment_count": commentsList.length,
        "is_saved": savedMap != null,
      });
    }

    setState(() {
      if (loadMore) {
        _posts.addAll(postsWithExtras);
      } else {
        _posts = postsWithExtras;
      }

      _offset += _limit;
      _isLoadingMore = false;
      _loading = false;
      _hasMore = posts.length == _limit;
    });
  }

  Future<void> _toggleVote(int postId, int vote) async {
    final userId = user?.id;
    if (userId == null) return;

    final index = _posts.indexWhere((p) => p["id"] == postId);
    if (index == -1) return;

    final post = _posts[index];
    final int previousVote = post["user_vote"] ?? 0;
    final int previousCount = post["votes_count"] ?? 0;

    setState(() {
      if (previousVote == vote) {
        post["user_vote"] = 0;
        post["votes_count"] = previousCount - vote;
      } else {
        post["user_vote"] = vote;
        post["votes_count"] = previousCount - previousVote + vote;
      }
    });

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
        await Supabase.instance.client.from("votes").insert({
          "post_id": postId,
          "user_id": userId,
          "vote": vote,
        });
      }
    } catch (e) {
      setState(() {
        post["user_vote"] = previousVote;
        post["votes_count"] = previousCount;
      });
      print("Vote error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oylama başarısız oldu!")),
      );
    }
  }

  Future<void> _toggleSave(int postId, bool currentlySaved) async {
    final userId = user?.id;
    if (userId == null) return;

    final index = _posts.indexWhere((p) => p["id"] == postId);
    if (index == -1) return;

    setState(() {
      _posts[index]["is_saved"] = !currentlySaved;
    });

    try {
      if (currentlySaved) {
        await Supabase.instance.client
            .from("saves")
            .delete()
            .eq("post_id", postId)
            .eq("user_id", userId);
      } else {
        await Supabase.instance.client.from("saves").insert({
          "post_id": postId,
          "user_id": userId,
        });
      }
    } catch (e) {
      setState(() {
        _posts[index]["is_saved"] = currentlySaved;
      });
      print("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kaydetme işlemi başarısız oldu!")),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Topluluk sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityExplorePage()),
      );
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAddPage()),
      ).then((value) {
        if (value == true) {
          _offset = 0;
          _posts.clear();
          _hasMore = true;
          _fetchPosts();
        }
      });
    } else {
      setState(() => _selectedIndex = index);
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
      key: _scaffoldKey,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => openLeftSideSheet(context), // YENİ
        ),

        title: Image.asset(
          'assets/logo.jpeg',
          height: 40,
        ),
        centerTitle: true,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
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

      // 👉 Sağdaki Profil Menüsü Artık Ayrı Dosyada
      endDrawer: RightProfileDrawer(
        profileImageUrl: profileImageUrl,
        username: username,
        bio: bio,
        onUploadProfileImage: _uploadProfileImage,
        refreshProfile: _fetchUserProfile,
      ),

      body: _loading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchPosts,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _posts.length) {
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            final post = _posts[index];
            final profile = post["profiles"];
            final postId = post["id"];
            final isSaved = post["is_saved"] == true;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
                        onPressed: () => _toggleVote(postId, 1),
                      ),
                      Text("${post["votes_count"] ?? 0}"),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: post["user_vote"] == -1
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () => _toggleVote(postId, -1),
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
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isSaved ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () => _toggleSave(postId, isSaved),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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



