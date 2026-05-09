import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_navigation.dart';
import '../core/api_service.dart';
import '../error/error_handler.dart';



import '../post/post_card.dart';


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
  final Map<int, GlobalKey> postKeys = {};
  final user = Supabase.instance.client.auth.currentUser;
  String? username;
  String? bio;
  String? profileImageUrl;
  final Set<int> highlightedPosts = {};
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  static HomePageState? instance;
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

    instance = this;

    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          fetchPosts(this, loadMore: true);
        }
      });


  }

  Future<void> openPost(int postId) async {
    // önce post listede var mı kontrol et
    final exists = posts.any((p) => p["id"] == postId);

    // yoksa fetch et
    if (!exists) {
      final post = await ApiService.getPostById(postId);

      if (post != null) {
        setState(() {
          posts.insert(0, post);
        });

        await Future.delayed(
          const Duration(milliseconds: 300),
        );
      }
    }

    final key = postKeys[postId];

    if (key?.currentContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _highlightPost(postId);
  }
  void _highlightPost(int postId) {
    setState(() {
      highlightedPosts.add(postId);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        highlightedPosts.remove(postId);
      });
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
        refreshProfile: _fetchUserProfile, // artık sadece refreshProfile var
      ),
      body: loading && posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => fetchPosts(this),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Eğer index posts.length'den büyükse, yükleme göstergesi
            if (index >= posts.length) {
              return isLoadingMore
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
                  : const SizedBox.shrink();
            }
            final post = posts[index];

            return Container(
              key: postKeys[post["id"]] ??= GlobalKey(),

              child: PostCard(
                post: post,
                parentContext: context,

                onVote: (postId, vote) =>
                    toggleVote(this, postId, vote),

                onJoinCommunity: (communityName, index) =>
                    joinCommunity(this, communityName, index),

                highlight:
                highlightedPosts.contains(post["id"]),
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
