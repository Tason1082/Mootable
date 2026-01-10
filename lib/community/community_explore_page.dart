import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'topic_data.dart';
import '../theme/app_theme.dart';

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
  String? selectedTopic;

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
    } catch (_) {
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
      final interestNames =
      interests.map((i) => i["interest_name"].toString().toLowerCase()).toList();

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
    } catch (_) {
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
    } catch (_) {
      userJoinedCommunities = [];
    }
  }

  bool _isJoined(Map<String, dynamic> community) {
    return userJoinedCommunities.any((c) => c["id"] == community["id"]);
  }

  List<Map<String, dynamic>> get filteredRecommended {
    final joinedIds = userJoinedCommunities.map((c) => c["id"]).toList();
    return recommended.where((c) => !joinedIds.contains(c["id"])).toList();
  }

  List<Map<String, dynamic>> _filteredCommunities() {
    final q = searchQuery.toLowerCase();
    final currentTopics =
        getTopicsData(l10n)[selectedCategory]?.map((t) => t.toLowerCase()).toList() ?? [];

    return allCommunities.where((c) {
      if (_isJoined(c)) return false;

      final topics = List<String>.from(c["topics"] ?? []).map((t) => t.toLowerCase()).toList();

      if (selectedTopic != null && !topics.contains(selectedTopic!.toLowerCase())) return false;

      if (selectedTopic == null && !topics.any((t) => currentTopics.contains(t))) return false;

      final name = (c["name"] ?? "").toLowerCase();
      final desc = (c["description"] ?? "").toLowerCase();

      return name.contains(q) || desc.contains(q) || q.isEmpty;
    }).toList();
  }

  Future<void> _joinCommunity(Map<String, dynamic> community) async {
    if (user == null) return;

    await supabase.from("user_communities").insert({
      "user_id": user!.id,
      "community_id": community["id"],
      "joined_at": DateTime.now().toIso8601String(),
    });

    await _loadUserJoinedCommunities();
    setState(() {});
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: redditCategories.map((cat) {
          final selected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
              selected: selected,
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.grey.shade200,
              onSelected: (_) {
                setState(() {
                  selectedCategory = cat;
                  selectedTopic = null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _topicsBar() {
    final topics = getTopicsData(l10n)[selectedCategory] ?? [];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: topics.map((topic) {
          final selected = selectedTopic?.toLowerCase() == topic.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                topic,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
              selected: selected,
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.grey.shade200,
              onSelected: (_) {
                setState(() {
                  selectedTopic = selected ? null : topic;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }




  Widget _recommendedCard(BuildContext context, Map<String, dynamic> community) {
    final joined = _isJoined(community);
    return SizedBox(
      width: 300,
      child: Card(
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: community["avatar_url"] != null
                      ? NetworkImage(community["avatar_url"])
                      : null,
                  child: community["avatar_url"] == null
                      ? Icon(Icons.groups, color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : null,
                ),
                title: Text(community["name"] ?? "", style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                community["description"] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: joined
                    ? FilledButton.tonal(
                  onPressed: null,
                  child: const Text("Katıldın"),
                )
                    : FilledButton(
                  onPressed: () => _joinCommunity(community),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(AppTheme.primary),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text("Katıl"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _communityCard(BuildContext context, Map<String, dynamic> community) {
    final joined = _isJoined(community);
    return Card(
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          backgroundImage: community["avatar_url"] != null
              ? NetworkImage(community["avatar_url"])
              : null,
          child: community["avatar_url"] == null
              ? Icon(Icons.groups, color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
        title: Text(community["name"] ?? ""),
        subtitle: Text(
          community["description"] ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: joined
            ? FilledButton.tonal(
          onPressed: null,
          child: const Text("Katıldın"),
        )
            : FilledButton(
          onPressed: () => _joinCommunity(community),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(AppTheme.primary),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          child: const Text("Katıl"),
        ),
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
      appBar: AppBar(
        title: TextField(
          onChanged: (v) => setState(() => searchQuery = v),
          decoration: const InputDecoration(
            hintText: "Topluluk ara",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text("Konuya göre toplulukları keşfet", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _categoryBar(),
            const SizedBox(height: 10),
            _topicsBar(),
            const SizedBox(height: 24),
            Text("Senin için önerilen", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: filteredRecommended.map((c) => _recommendedCard(context, c)).toList(),
              ),
            ),
            const SizedBox(height: 25),
            Text("Tüm topluluklar", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ..._filteredCommunities().map((c) => _communityCard(context, c)).toList(),
          ],
        ),
      ),
    );
  }
}
