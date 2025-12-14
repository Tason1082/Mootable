import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'community_detail_page.dart';

class MyCommunityPage extends StatefulWidget {
  const MyCommunityPage({super.key});

  @override
  State<MyCommunityPage> createState() => _MyCommunityPageState();
}

class _MyCommunityPageState extends State<MyCommunityPage> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadMyCommunities();
  }

  Future<List<Map<String, dynamic>>> _loadMyCommunities() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // 1️⃣ Kullanıcının community_id'lerini al
    final userCommunities = await supabase
        .from('user_communities')
        .select('community_id')
        .eq('user_id', user.id);

    if (userCommunities.isEmpty) return [];

    final communityIds =
    userCommunities.map((e) => e['community_id']).toList();

    // 2️⃣ community_id'lere göre communities tablosunu çek
    final communities = await supabase
        .from('communities')
        .select()
        .inFilter('id', communityIds);

    return List<Map<String, dynamic>>.from(communities);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluklarım"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Henüz katıldığın bir topluluk yok",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final communities = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: community['image'] != null
                        ? NetworkImage(community['image'])
                        : null,
                    child: community['image'] == null
                        ? const Icon(Icons.groups)
                        : null,
                  ),
                  title: Text(
                    community['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    community['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityDetailPage(
                          community: community,
                        ),
                      ),
                    );
                  },

                ),
              );
            },
          );
        },
      ),
    );
  }
}
