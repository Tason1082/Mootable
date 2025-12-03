import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'community/topic_data.dart'; // getTopicsData fonksiyonunu import et

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
  List<Map<String, dynamic>> userJoinedCommunities = [];

  String searchQuery = "";

  late AppLocalizations l10n;

  List<String> redditCategories = [];
  String selectedCategory = "";
  String? selectedTopic; // 🔹 Seçilen alt konu

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
      final result = await supabase
          .from("communities")
          .select("*")
          .order("created_at", ascending: false);

      allCommunities = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      allCommunities = [];
    }
  }

  Future<void> _loadUserInterestsAndRecommended() async {
    if (user == null) {
      recommended = [];
      return;
    }

    try {
      final interests = await supabase
          .from("user_interests")
          .select("interest_name")
          .eq("user_id", user!.id);

      final interestNames = interests
          .map((i) => i["interest_name"].toString().toLowerCase())
          .toList();

      if (interestNames.isEmpty) {
        recommended = [];
        return;
      }

      final recs = await supabase
          .from("communities")
          .select("*")
          .overlaps("topics", interestNames)
          .order("created_at", ascending: false);

      recommended = List<Map<String, dynamic>>.from(recs);
    } catch (e) {
      recommended = [];
    }
  }

  Future<void> _loadUserJoinedCommunities() async {
    if (user == null) {
      userJoinedCommunities = [];
      return;
    }

    try {
      final joins = await supabase
          .from("user_communities")
          .select("community_id")
          .eq("user_id", user!.id);

      final ids = joins.map((j) => j["community_id"]).toList();

      if (ids.isEmpty) {
        userJoinedCommunities = [];
        return;
      }

      final comms =
      await supabase.from("communities").select("*").inFilter("id", ids);

      userJoinedCommunities = List<Map<String, dynamic>>.from(comms);
    } catch (e) {
      userJoinedCommunities = [];
    }
  }

  // 🔹 Filtreleme: selectedCategory ve selectedTopic küçük harfe göre
  List<Map<String, dynamic>> _filteredCommunities() {
    final q = searchQuery.toLowerCase();
    final topicsData = getTopicsData(l10n);
    final currentTopics =
        topicsData[selectedCategory]?.map((t) => t.toLowerCase()).toList() ?? [];

    return allCommunities.where((c) {
      final communityTopics =
      List<String>.from(c["topics"] ?? []).map((t) => t.toLowerCase()).toList();

      // 🔹 selectedTopic varsa ona göre filtrele
      if (selectedTopic != null &&
          !communityTopics.contains(selectedTopic!.toLowerCase())) return false;

      // 🔹 selectedTopic yoksa kategori alt konularına göre filtrele
      if (selectedTopic == null &&
          !communityTopics.any((t) => currentTopics.contains(t))) return false;

      if (q.isEmpty) return true;

      final name = (c["name"] ?? "").toString().toLowerCase();
      final desc = (c["description"] ?? "").toString().toLowerCase();

      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  bool _isJoined(Map<String, dynamic> community) {
    return userJoinedCommunities.any((c) => c["id"] == community["id"]);
  }

  Future<void> _joinCommunity(Map<String, dynamic> community) async {
    if (user == null) return;

    final id = community["id"];

    try {
      await supabase.from("user_communities").insert({
        "user_id": user!.id,
        "community_id": id,
        "joined_at": DateTime.now().toIso8601String(),
      });

      await _loadUserJoinedCommunities();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Topluluğa katıldın ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu")),
      );
    }
  }

  // 🔹 Scrollable kategori barı
  Widget _redditStyleCategoryBar() {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: redditCategories.map((cat) {
            final selected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedCategory = cat;
                  selectedTopic = null; // kategori değişince alt konuyu resetle
                }),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 🔹 Alt konular yatay scroll, tıklanabilir ve seçiliyi işaretli
  Widget _buildTopicsBar() {
    final currentTopics = getTopicsData(l10n)[selectedCategory] ?? [];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: currentTopics.length,
        itemBuilder: (context, index) {
          final topic = currentTopics[index];
          final isSelected = selectedTopic?.toLowerCase() == topic.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() {
                selectedTopic = isSelected ? null : topic; // seçiliyi toggle et
              }),
              child: Chip(
                label: Text(topic),
                backgroundColor: isSelected ? Colors.black : Colors.grey.shade200,
                labelStyle:
                TextStyle(color: isSelected ? Colors.white : Colors.black),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _recommendedCard(Map<String, dynamic> community) {
    final joined = _isJoined(community);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: community["avatar_url"] != null
                    ? NetworkImage(community["avatar_url"])
                    : null,
                child: community["avatar_url"] == null
                    ? const Icon(Icons.group)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  community["name"] ?? "",
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            community["description"] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: joined ? null : () => _joinCommunity(community),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(joined ? "Katıldın" : "Katıl"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityCard(Map<String, dynamic> community) {
    final joined = _isJoined(community);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: community["avatar_url"] != null
                ? NetworkImage(community["avatar_url"])
                : null,
            child:
            community["avatar_url"] == null ? const Icon(Icons.group) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  community["description"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: joined ? null : () => _joinCommunity(community),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              joined ? Colors.grey.shade300 : Colors.grey.shade200,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(joined ? "Katıldın" : "Katıl"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;
    redditCategories = getTopicsData(l10n).keys.toList();
    if (selectedCategory.isEmpty && redditCategories.isNotEmpty) {
      selectedCategory = redditCategories.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: const Icon(Icons.menu),
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            onChanged: (v) => setState(() {
              searchQuery = v;
            }),
            decoration: const InputDecoration(
              hintText: "Topluluk ara",
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
          ),
        ),
        actions: const [
          SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          SizedBox(width: 14),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            const Text(
              "Konuya göre toplulukları keşfet",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _redditStyleCategoryBar(),
                const SizedBox(height: 10),
                _buildTopicsBar(), // 🔹 tıklanabilir alt konular
              ],
            ),

            const SizedBox(height: 24),
            const Text("Senin için önerilen",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: recommended.map(_recommendedCard).toList(),
              ),
            ),

            const SizedBox(height: 25),
            const Text("Tüm topluluklar",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),
            ..._filteredCommunities().map(_communityCard).toList(),
          ],
        ),
      ),
    );
  }
}

