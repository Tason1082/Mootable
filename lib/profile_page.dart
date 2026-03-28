import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import 'edit_profile_page.dart';

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
      final userId = await AuthService.getUserId();
      print("PROFILE PAGE USER ID -> $userId");

      if (userId == null) {
        print("USER ID NULL");
        setState(() => loading = false);
        return;
      }

      final userRes = await ApiClient.dio.get('/api/users/$userId');
      print("USER RESPONSE -> ${userRes.data}");

final postRes = await ApiClient.dio.get('/api/posts/me');print("POST RESPONSE -> ${postRes.data}");

      setState(() {
        // 🔹 Map olarak cast ediyoruz ki user?['username'] çalışsın
        user = Map<String, dynamic>.from(userRes.data);
        posts = postRes.data is List ? List.from(postRes.data) : [];
        loading = false;
      });
    } catch (e, st) {
      print("PROFILE ERROR -> $e");
      print(st);
      setState(() => loading = false);
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
              OutlinedButton(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        initialUsername: user?['username'],
                        initialBio: user?['bio'],
                      ),
                    ),
                  );

                  // 🔥 geri dönünce refresh
                  if (updated == true) {
                    _loadProfile();
                  }
                },
                child: const Text("Düzenle"),
              ),
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
    if (posts.isEmpty) return const Center(child: Text("Hiç post yok"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(post['content'] ?? ''),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 18),
                  Text("${post['upvotes'] ?? 0}"),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment, size: 18),
                  Text("${post['commentsCount'] ?? 0}"),
                ],
              ),
            ],
          ),
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