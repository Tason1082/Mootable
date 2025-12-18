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

  int limit = 5;
  int offset = 0;
  bool isLoadingMore = false;
  bool hasMore = true;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    fetchPosts(this);
    _fetchUserProfile();

    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          fetchPosts(this, loadMore: true);
        }
      });
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
    if (user == null) return;

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

      setState(() {
        profileImageUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil fotoğrafı güncellendi"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil fotoğrafı yüklenemedi"),
          ),
        );
      }
    }
  }

  Widget _buildMediaWidget(String url) {
    final lower = url.toLowerCase();

    if (lower.endsWith(".mp4") ||
        lower.endsWith(".mov") ||
        lower.endsWith(".avi") ||
        lower.endsWith(".webm")) {
      return AspectRatio(
        aspectRatio: 1,
        child: VideoPlayerWidget(videoUrl: url),
      );
    }

    if (lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".png") ||
        lower.endsWith(".gif")) {
      return Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(child: Text("Desteklenmeyen medya türü")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => scaffoldKey.currentState?.openEndDrawer(),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colors.surfaceVariant,
                backgroundImage:
                profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person)
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
              return isLoadingMore
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
                  : const SizedBox.shrink();
            }

            final post = posts[index];
            final postId = post["id"];
            final isSaved = post["is_saved"] == true;

            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.surfaceVariant,
                      child: Icon(Icons.groups,
                          color: colors.onSurfaceVariant),
                    ),
                    title: Text(
                      post["community_name"] ?? "",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      TimeAgo.format(
                        context,
                        DateTime.parse(post["created_at"]),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: post["is_member"] != true
                        ? TextButton(
                      onPressed: () => joinCommunity(
                        this,
                        post["community"],
                        index,
                      ),
                      child: const Text("Katıl"),
                    )
                        : null,
                  ),

                  if (post["image_url"] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMediaWidget(post["image_url"]),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      post["content"] ?? "",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            color: post["user_vote"] == 1
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              toggleVote(this, postId, 1),
                        ),
                        Text("${post["votes_count"] ?? 0}"),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward,
                            color: post["user_vote"] == -1
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              toggleVote(this, postId, -1),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommentPage(postId: postId),
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
                            color: isSaved
                                ? colors.secondary
                                : colors.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              toggleSave(this, postId, isSaved),
                        ),
                      ],
                    ),
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
