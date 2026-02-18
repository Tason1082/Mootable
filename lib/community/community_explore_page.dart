import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/api_client.dart';
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
  bool _categoriesLoaded = false;

  List<Map<String, dynamic>> recommended = [];
  List<Map<String, dynamic>> allCommunities = [];
  List<Map<String, dynamic>> userJoinedCommunities = [];

  List<Map<String, dynamic>> categories = [];
  Map<String, List<Map<String, dynamic>>> categoryTopics = {};

  String selectedCategoryKey = "";
  String? selectedTopicKey;
  String searchQuery = "";

  // ================= INIT =================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_categoriesLoaded) {
      _loadInitialData();
      _categoriesLoaded = true;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => loading = true);

    await Future.wait([
      _loadCategoriesFromApi(),
      _loadAllCommunities(),
      _loadUserInterestsAndRecommended(),
      _loadUserJoinedCommunities(),
    ]);

    setState(() => loading = false);
  }

  // ================= CATEGORY API =================

  Future<void> _loadCategoriesFromApi() async {
    try {
      final locale =
          Localizations.localeOf(context).languageCode;

      final response = await ApiClient.dio.get(
        "/api/categories",
        queryParameters: {"locale": locale},
      );

      final List data = response.data;

      categories = List<Map<String, dynamic>>.from(data);

      categoryTopics.clear();

      for (var cat in categories) {
        categoryTopics[cat["key"]] =
        List<Map<String, dynamic>>.from(cat["topics"] ?? []);
      }

      if (categories.isNotEmpty) {
        selectedCategoryKey = categories.first["key"];
      }
    } catch (e) {
      categories = [];
      categoryTopics = {};
    }
  }

  // ================= COMMUNITIES =================

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

      final comms = await supabase
          .from("communities")
          .select("*")
          .inFilter("id", ids);

      userJoinedCommunities =
      List<Map<String, dynamic>>.from(comms);
    } catch (_) {
      userJoinedCommunities = [];
    }
  }

  bool _isJoined(Map<String, dynamic> community) {
    return userJoinedCommunities
        .any((c) => c["id"] == community["id"]);
  }

  List<Map<String, dynamic>> _filteredCommunities() {
    final q = searchQuery.toLowerCase();

    final currentTopics =
        categoryTopics[selectedCategoryKey]
            ?.map((t) => t["key"].toString().toLowerCase())
            .toList() ??
            [];

    return allCommunities.where((c) {
      if (_isJoined(c)) return false;

      final topics = List<String>.from(c["topics"] ?? [])
          .map((t) => t.toLowerCase())
          .toList();

      if (selectedTopicKey != null &&
          !topics.contains(selectedTopicKey!.toLowerCase()))
        return false;

      if (selectedTopicKey == null &&
          !topics.any((t) => currentTopics.contains(t)))
        return false;

      final name = (c["name"] ?? "").toLowerCase();
      final desc = (c["description"] ?? "").toLowerCase();

      return name.contains(q) ||
          desc.contains(q) ||
          q.isEmpty;
    }).toList();
  }

  // ================= UI =================

  Widget _categoryBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final selected =
              selectedCategoryKey == cat["key"];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat["name"]),
              selected: selected,
              selectedColor: AppTheme.primary,
              onSelected: (_) {
                setState(() {
                  selectedCategoryKey = cat["key"];
                  selectedTopicKey = null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _topicsBar() {
    final topics =
        categoryTopics[selectedCategoryKey] ?? [];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: topics.map((topic) {
          final selected =
              selectedTopicKey == topic["key"];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(topic["name"]),
              selected: selected,
              selectedColor: AppTheme.primary,
              onSelected: (_) {
                setState(() {
                  selectedTopicKey =
                  selected ? null : topic["key"];
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (v) =>
              setState(() => searchQuery = v),
          decoration: InputDecoration(
            hintText: l10n.search,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            _categoryBar(),
            const SizedBox(height: 10),
            _topicsBar(),
            const SizedBox(height: 20),
            ..._filteredCommunities()
                .map((c) => ListTile(
              title:
              Text(c["name"] ?? ""),
              subtitle: Text(
                  c["description"] ?? ""),
            ))
                .toList(),
          ],
        ),
      ),
    );
  }
}





