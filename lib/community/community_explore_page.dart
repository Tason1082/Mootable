import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';

class CommunityExplorePage extends StatefulWidget {
  const CommunityExplorePage({super.key});

  @override
  State<CommunityExplorePage> createState() => _CommunityExplorePageState();
}

class _CommunityExplorePageState extends State<CommunityExplorePage> {
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
      _loadRecommended(),
      _loadUserJoinedCommunities(),
    ]);

    setState(() => loading = false);
  }

  // ================= JOIN =================

  Future<void> _joinCommunity(String id) async {
    try {
      await ApiClient.dio.post("/api/communities/$id/join");

      final joined = allCommunities.firstWhere((c) => c["id"] == id);

      setState(() {
        userJoinedCommunities.add(joined);
      });
    } catch (e) {
      print("Join error: $e");
    }
  }

  // ================= CATEGORY API =================

  Future<void> _loadCategoriesFromApi() async {
    try {
      final locale = Localizations.localeOf(context).languageCode;

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
      final response = await ApiClient.dio.get("/api/communities");

      allCommunities = List<Map<String, dynamic>>.from(response.data);
    } catch (_) {
      allCommunities = [];
    }
  }

  Future<void> _loadRecommended() async {
    try {
      final response =
      await ApiClient.dio.get("/api/communities/recommended");

      recommended = List<Map<String, dynamic>>.from(response.data);
    } catch (_) {
      recommended = [];
    }
  }

  Future<void> _loadUserJoinedCommunities() async {
    try {
      final response =
      await ApiClient.dio.get("/api/communities/my"); // ✅ düzeltildi

      userJoinedCommunities =
      List<Map<String, dynamic>>.from(response.data);
    } catch (_) {
      userJoinedCommunities = [];
    }
  }

  bool _isJoined(Map<String, dynamic> community) {
    return userJoinedCommunities.any((c) => c["id"] == community["id"]);
  }
  Future<void> _leaveCommunity(String id) async {
    try {
      await ApiClient.dio.delete("/api/communities/$id/leave");

      setState(() {
        userJoinedCommunities.removeWhere((c) => c["id"] == id);
      });

    } catch (e) {
      print("Leave error: $e");
    }
  }
  List<Map<String, dynamic>> _filteredCommunities() {
    final q = searchQuery.toLowerCase();

    return allCommunities.where((c) {
      final name = (c["name"] ?? "").toLowerCase();

      if (q.isEmpty) return true;
      return name.contains(q);
    }).toList();
  }

  // ================= UI =================

  Widget _categoryBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final selected = selectedCategoryKey == cat["key"];

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
    final topics = categoryTopics[selectedCategoryKey] ?? [];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: topics.map((topic) {
          final selected = selectedTopicKey == topic["key"];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(topic["name"]),
              selected: selected,
              selectedColor: AppTheme.primary,
              onSelected: (_) {
                setState(() {
                  selectedTopicKey = selected ? null : topic["key"];
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _communityTile(Map<String, dynamic> c) {
    final isJoined = _isJoined(c);

    return Card(
      child: ListTile(
        title: Text(c["name"] ?? ""),
        subtitle: Text(c["description"] ?? ""),
        trailing: ElevatedButton(
          onPressed: () {
            if (isJoined) {
              _leaveCommunity(c["id"]);
            } else {
              _joinCommunity(c["id"]);
            }
          },
          child: Text(isJoined ? "Ayrıl" : "Katıl"),
        ),
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
          onChanged: (v) => setState(() => searchQuery = v),
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
            ..._filteredCommunities().map(_communityTile).toList(),
          ],
        ),
      ),
    );
  }
}





