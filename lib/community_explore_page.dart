import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityExplorePage extends StatefulWidget {
  const CommunityExplorePage({super.key});

  @override
  State<CommunityExplorePage> createState() => _CommunityExplorePageState();
}

class _CommunityExplorePageState extends State<CommunityExplorePage> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  bool loading = true;
  List<Map<String, dynamic>> recommended = [];
  List<Map<String, dynamic>> allCommunities = [];
  List<String> categoryList = [];
  List<Map<String, dynamic>> userJoinedCommunities = [];

  String selectedCategory = "All";
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => loading = true);
    await Future.wait([
      _loadAllCommunities(),
      _loadUserInterestsAndRecommended(),
      _loadUserJoinedCommunities(),
    ]);
    setState(() => loading = false);
  }

  Future<void> _loadAllCommunities() async {
    try {
      final communities = List<Map<String, dynamic>>.from(
        await supabase.from("communities").select("*").order("created_at", ascending: false),
      );
      allCommunities = communities;
      final types = communities.map((c) => (c["type"] ?? "Other").toString()).toSet().toList();
      categoryList = ["All", ...types];
    } catch (e) {
      debugPrint("Load communities error: $e");
      allCommunities = [];
      categoryList = ["All"];
    }
  }

  Future<void> _loadUserInterestsAndRecommended() async {
    if (user == null) {
      recommended = [];
      return;
    }
    try {
      final interests = List<Map<String, dynamic>>.from(
        await supabase.from("user_interests").select("interest_name").eq("user_id", user!.id),
      );

      final interestNames = interests.map((i) => i["interest_name"].toString()).toList();

      if (interestNames.isEmpty) {
        recommended = [];
        return;
      }

      final recs = List<Map<String, dynamic>>.from(
        await supabase
            .from("communities")
            .select("*")
            .inFilter("type", interestNames)
            .order("created_at", ascending: false),
      );

      recommended = recs;
    } catch (e) {
      debugPrint("Load user interests error: $e");
      recommended = [];
    }
  }

  Future<void> _loadUserJoinedCommunities() async {
    if (user == null) {
      userJoinedCommunities = [];
      return;
    }
    try {
      final joins = List<Map<String, dynamic>>.from(
        await supabase.from("user_communities").select("community_id").eq("user_id", user!.id),
      );
      final communityIds = joins.map((j) => j["community_id"]).toList();

      if (communityIds.isEmpty) {
        userJoinedCommunities = [];
        return;
      }

      final comms = List<Map<String, dynamic>>.from(
        await supabase.from("communities").select("*").inFilter("id", communityIds),
      );

      userJoinedCommunities = comms;
    } catch (e) {
      debugPrint("Load user joined communities error: $e");
      userJoinedCommunities = [];
    }
  }

  List<Map<String, dynamic>> _filteredCommunities() {
    final q = searchQuery.trim().toLowerCase();
    return allCommunities.where((c) {
      if (selectedCategory != "All" && (c["type"] ?? "") != selectedCategory) return false;
      if (q.isEmpty) return true;
      final name = (c["name"] ?? "").toString().toLowerCase();
      final desc = (c["description"] ?? "").toString().toLowerCase();
      final type = (c["type"] ?? "").toString().toLowerCase();
      return name.contains(q) || desc.contains(q) || type.contains(q);
    }).toList();
  }

  Future<void> _joinCommunity(Map<String, dynamic> community) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giriş yapmalısınız.")));
      return;
    }

    final communityId = community["id"];

    try {
      final existing = await supabase
          .from("user_communities")
          .select("id")
          .eq("user_id", user!.id)
          .eq("community_id", communityId)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaten katılıyorsun.")));
        return;
      }

      await supabase.from("user_communities").insert({
        "user_id": user!.id,
        "community_id": communityId,
        "joined_at": DateTime.now().toIso8601String(),
      });

      await _loadUserJoinedCommunities();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Topluluğa katıldın ✅")));
    } catch (e) {
      debugPrint("Join community error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Katılma başarısız.")));
    }
  }

  bool _isJoined(Map<String, dynamic> community) {
    return userJoinedCommunities.any((c) => c["id"] == community["id"]);
  }

  Widget _communityCard(Map<String, dynamic> community) {
    final joined = _isJoined(community);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: community["avatar_url"] != null ? NetworkImage(community["avatar_url"]) : null,
          child: community["avatar_url"] == null ? const Icon(Icons.group) : null,
        ),
        title: Text(community["name"] ?? "Topluluk"),
        subtitle: Text(community["description"] ?? (community["type"] ?? "")),
        trailing: ElevatedButton(
          onPressed: joined ? null : () => _joinCommunity(community),
          child: Text(joined ? "Katıldın" : "Katıl"),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Topluluk: ${community["name"]}")),
          );
        },
      ),
    );
  }

  Widget _communityTileCompact(Map<String, dynamic> community) {
    final joined = _isJoined(community);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: CircleAvatar(
        backgroundImage: community["avatar_url"] != null ? NetworkImage(community["avatar_url"]) : null,
        child: community["avatar_url"] == null ? const Icon(Icons.group) : null,
      ),
      title: Text(community["name"] ?? "Topluluk"),
      subtitle: Text(community["description"] ?? (community["type"] ?? "")),
      trailing: ElevatedButton(
        onPressed: joined ? null : () => _joinCommunity(community),
        child: Text(joined ? "Katıldın" : "Katıl"),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Topluluk: ${community["name"]}")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Toplulukları Keşfet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Topluluk oluşturma")),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "Topluluk ara",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (v) {
                setState(() => searchQuery = v);
              },
            ),
            const SizedBox(height: 12),

            // Categories
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = categoryList[idx];
                  final selected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            const Text("Senin için önerilen",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (recommended.isEmpty)
              const Text("Kişisel öneri bulunamadı. İlgi alanlarını ekleyin veya farklı kategorileri keşfedin.")
            else
              Column(
                children: recommended.map((c) => _communityTileCompact(c)).toList(),
              ),

            const SizedBox(height: 20),

            const Text("Katıldığın topluluklar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (userJoinedCommunities.isEmpty)
              const Text("Henüz hiçbir topluluğa katılmadın.")
            else
              Column(
                children: userJoinedCommunities.map((c) => _communityCard(c)).toList(),
              ),

            const SizedBox(height: 20),

            const Text("Tüm topluluklar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ..._filteredCommunities().map((c) => _communityCard(c)).toList(),
          ],
        ),
      ),
    );
  }
}
