
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';


import '../error/error_handler.dart';



import '../post/post_card.dart';


import 'home_page_functions.dart';
import 'left_menu.dart';
import 'right_profile_drawer.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  static final GlobalKey<HomePageState> globalKey =
  GlobalKey<HomePageState>();

  final int? postId;

  const HomePage({
    super.key,
    this.postId,
  });

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
  static HomePageState? instance;
  String? profileImageUrl;
  final Set<int> highlightedPosts = {};
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;

  int limit = 20;
  int offset = 0;
  bool isLoadingMore = false;
  bool hasMore = true;


  late final ScrollController _scrollController;

  @override


  @override
  void initState() {
    super.initState();



    instance = this;

    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          fetchPosts(this, loadMore: true);
        }
      });

    _fetchUserProfile();

    fetchPosts(this).then((_) async {

      for (final post in posts) {
        final postId = post["id"];

        final key = postKeys[postId] ??= GlobalKey();

        debugPrint("Post $postId key => $key");
      }



      final key = postKeys[16];
      debugPrint("161616POST 16 KEY => $key");
      if (key != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = key.currentContext;
          if (context == null) return;

          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        });
      }
    });

  }

  void scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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

              key: postKeys[post["id"]],
              child: PostCard(
                post: post,
                parentContext: context,

                onVote: (postId, vote) =>
                    toggleVote(this, postId, vote),

                onJoinCommunity: (communityName, index) =>
                    joinCommunity(this, communityName, index),


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
