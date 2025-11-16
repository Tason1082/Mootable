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
import 'dart:typed_data' as typed_data;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'video_player_widget.dart';
import 'CreateCommunityPage.dart';
// ✅ Yeni doğru import
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
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

  // ✅ Sayfalama için eklenen değişkenler
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
        // Liste sonuna yaklaşıldı
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
  Widget _buildLeftMenu() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.add), // + işareti
            title: Text(
              AppLocalizations.of(context)!.createCommunity, // "Topluluk Oluştur"
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              // Topluluk oluşturma sayfasına yönlendirme
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCommunityPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  void openLeftSideSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5, // 👉 YARIM EKRAN
              child: Drawer( // kendi drawer içeriğini buraya koy
                child: _buildLeftMenu(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return Transform.translate(
          offset: Offset(-300 * (1 - anim.value), 0),
          child: child,
        );
      },
    );
  }

  Future<void> _fetchUserProfile() async {
    if (user == null) return;
    final profile =
    await Supabase.instance.client
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
          "${user!.id}_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg";
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil yüklenemedi!")));
    }
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;
    if (!loadMore) setState(() => _loading = true);
    setState(() => _isLoadingMore = true);
    final from = _offset;
    final to = _offset + _limit - 1;
    final List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from("posts")
          .select("id, content, image_url, created_at, user_id")
          .order("created_at", ascending: false)
          .range(from, to),
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
      final profileMap =
      await Supabase.instance.client
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
      final savedMap =
      await Supabase.instance.client
          .from("saves")
          .select("id")
          .eq("post_id", post["id"])
          .eq("user_id", user!.id)
          .maybeSingle();
      final upvotes = votesList
          .where((v) => v["vote"] == 1)
          .length;
      final downvotes = votesList
          .where((v) => v["vote"] == -1)
          .length;
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

    // UI'da hemen tepki
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
      final existingVote =
      await Supabase.instance.client
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
      // Hata durumunda UI rollback
      setState(() {
        post["user_vote"] = previousVote;
        post["votes_count"] = previousCount;
      });
      print("Vote error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Oylama başarısız oldu!")));
    }
  }

  Future<void> _toggleSave(int postId, bool currentlySaved) async {
    final userId = user?.id;
    if (userId == null) return;

    final index = _posts.indexWhere((p) => p["id"] == postId);
    if (index == -1) return;

    // UI anında güncelle
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
      // Hata durumunda rollback
      setState(() {
        _posts[index]["is_saved"] = currentlySaved;
      });
      print("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kaydetme işlemi başarısız oldu!")),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAddPage()),
      ).then((_) => _fetchPosts());
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
        errorBuilder:
            (context, error, stackTrace) =>
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
          onPressed: openLeftSideSheet,

        ),

        // 🔹 BURADA "Mootable" yerine LOGO EKLENDİ:
        title: Image.asset(
          'assets/logo.jpeg',   // Logonun yolu (pubspec.yaml’da tanımlı olmalı)
          height: 40,           // AppBar’a sığması için ideal yükseklik
        ),

        centerTitle: true, // Logoyu ortalar

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
                      profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child:
                      profileImageUrl == null
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
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
                          builder:
                              (_) =>
                              EditProfilePage(
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
                          builder:
                              (_) =>
                              UserPostsPage(
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
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.settings),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
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
      body:
      _loading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchPosts,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          // Eğer daha fazla varsa loading göstergesi ekle
          itemBuilder: (context, index) {
            if (index >= _posts.length) {
              // Liste sonuna gelindi -> yükleniyor göstergesi
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const SizedBox.shrink(); // Daha fazla yoksa boş
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
                      backgroundImage:
                      profile?["avatar_url"] != null
                          ? NetworkImage(profile["avatar_url"])
                          : null,
                      child:
                      profile?["avatar_url"] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profile?["username"] ?? "Anonim"),
                    subtitle: Text(
                      TimeAgo.format(
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
                          color:
                          post["user_vote"] == 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () => _toggleVote(postId, 1),
                      ),
                      Text("${post["votes_count"] ?? 0}"),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color:
                          post["user_vote"] == -1
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
                              builder:
                                  (_) => CommentPage(postId: postId),
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








