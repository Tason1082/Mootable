import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../TimeAgo.dart';
import '../error_handler.dart';
import '../comment/comment_page.dart';
import '../post/post_card.dart';
import '../quote_post_page.dart';
import '../video_player_widget.dart';
import '../community/community_explore_page.dart';
import '../community/CreateCommunityPage.dart';
import '../edit_profile_page.dart';
import '../settings_page.dart';
import '../post/post_page.dart';
import '../user_posts_page.dart';
import '../saved_posts_page.dart';
import 'home_page_functions.dart';
import 'left_menu.dart';
import 'right_profile_drawer.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    try {
      final profile = await Supabase.instance.client
          .from("profiles")
          .select("username, bio, avatar_url")
          .eq("id", user!.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        username = profile?["username"] ?? "Anonim";
        bio = profile?["bio"];
        profileImageUrl = profile?["avatar_url"];
      });
    } catch (e, st) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, stackTrace: st);
    }
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

      await Supabase.instance.client.storage.from('avatars').upload(fileName, file);

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
          const SnackBar(content: Text("Profil fotoğrafı güncellendi")),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, stackTrace: st);
    }
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
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null ? const Icon(Icons.person) : null,
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

            return PostCard(
              post: post,
              parentContext: context,
              onVote: (postId, vote) => toggleVote(this, postId, vote),
              onJoinCommunity: (communityName, index) =>
                  joinCommunity(this, communityName, index),
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
