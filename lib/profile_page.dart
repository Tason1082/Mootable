import 'package:flutter/material.dart';
import 'package:mootable/post/post_card.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import 'edit_profile_page.dart';
import 'home/home_page_functions.dart';

class ProfilePage extends StatefulWidget {

  final String username;

  const ProfilePage({super.key, required this.username});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? user;
  List posts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userRes = await ApiClient.dio.get(
        '/api/users/username/${widget.username}',
      );

      final postRes = await ApiClient.dio.get(
        '/api/posts/user/${widget.username}',
      );

      // 🔥 OUTER RESPONSE MAP
      final Map<String, dynamic> body =
      Map<String, dynamic>.from(postRes.data);

      // 🔥 INNER LIST
      final List rawList = body["data"] as List;

      final mappedPosts = rawList.map((p) {
        final map = Map<String, dynamic>.from(p);

        return {
          ...map,
          "votes_count": map["netScore"] ?? 0,
          "user_vote": map["userVote"] ?? 0,
          "created_at": map["createdAt"],
          "community": map["community"],
          "communityId": map["communityId"],
          "comment_count": map["commentCount"] ?? 0,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        user = Map<String, dynamic>.from(userRes.data);
        posts = mappedPosts;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint("PROFILE LOAD ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            /// 🔥 HEADER
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              actions: const [
                Icon(Icons.search, color: Colors.black),
                SizedBox(width: 12),
                Icon(Icons.settings, color: Colors.black),
                SizedBox(width: 12),
                Icon(Icons.more_vert, color: Colors.black),
                SizedBox(width: 8),
              ],
            ),

            /// 🔥 STICKY TABBAR
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(text: "Paylaşımlar"),
                    Tab(text: "Yorumlar"),
                    Tab(text: "Hakkımda"),
                  ],
                ),
              ),
            ),
          ];
        },

        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPosts(),
            _buildComments(),
            _buildAbout(),
          ],
        ),
      ),
    );
  }

  /// 🔹 HEADER
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profil resmi
              CircleAvatar(
                radius: 36,
                backgroundImage: user?['profileImageUrl'] != null
                    ? NetworkImage(user!['profileImageUrl'])
                    : null,
                child: user?['profileImageUrl'] == null
                    ? const Icon(Icons.person, size: 36)
                    : null,
              ),
              const SizedBox(width: 16),

              // Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "u/${widget.username}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Düzenle butonu

            ],
          ),

          const SizedBox(height: 12),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat("Karma", "${user?['karma'] ?? 0}"),
              _stat("Katkılar", "${posts.length}"),
              _stat("Hesap yaşı", "5 ay"),
              _stat("Aktif", "0"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPosts() {
    if (posts.isEmpty) {
      return const Center(child: Text("Hiç post yok"));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return PostCard(
          post: post,
          parentContext: context,

          /// 🔥 HomePage'deki fonksiyonu kullanıyoruz
          onVote: (postId, vote) {
            toggleVote(this, postId, vote);
          },

          /// opsiyonel
          onJoinCommunity: (communityName, postId) {
            print("Joined: $communityName");
          },
        );
      },
    );
  }

  Widget _buildComments() => const Center(child: Text("Yorumlar yakında"));

  Widget _buildAbout() => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(user?['bio'] ?? 'Bio yok'),
  );
}

/// 🔥 STICKY TAB FIX
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}