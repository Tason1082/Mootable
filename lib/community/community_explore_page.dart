import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';

class CommunityExplorePage extends StatefulWidget {
  const CommunityExplorePage({super.key});

  @override
  State<CommunityExplorePage> createState() =>
      _CommunityExplorePageState();
}

class _CommunityExplorePageState
    extends State<CommunityExplorePage> {
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

  Future<void> _joinCommunity(String id) async {
    try {
      await ApiClient.dio.post(
        "/api/communities/$id/join",
      );

      final joined = allCommunities.firstWhere(
            (c) => c["id"] == id,
      );

      setState(() {
        userJoinedCommunities.add(joined);
      });
    } catch (e) {
      debugPrint("Join error: $e");
    }
  }

  Future<void> _leaveCommunity(String id) async {
    try {
      await ApiClient.dio.delete(
        "/api/communities/$id/leave",
      );

      setState(() {
        userJoinedCommunities.removeWhere(
              (c) => c["id"] == id,
        );
      });
    } catch (e) {
      debugPrint("Leave error: $e");
    }
  }

  Future<void> _loadAllCommunities() async {
    try {
      final response = await ApiClient.dio.get(
        "/api/communities",
      );

      allCommunities =
      List<Map<String, dynamic>>.from(
        response.data["data"],
      );
    } catch (_) {
      allCommunities = [];
    }
  }

  Future<void> _loadCategoriesFromApi() async {
    try {
      final locale =
          Localizations.localeOf(context)
              .languageCode;

      final response = await ApiClient.dio.get(
        "/api/categories",
        queryParameters: {
          "locale": locale,
        },
      );

      final List data = response.data;

      categories =
      List<Map<String, dynamic>>.from(data);

      categoryTopics.clear();

      for (var cat in categories) {
        categoryTopics[cat["key"]] =
        List<Map<String, dynamic>>.from(
          cat["topics"] ?? [],
        );
      }

      if (categories.isNotEmpty) {
        selectedCategoryKey =
        categories.first["key"];
      }
    } catch (e) {
      categories = [];
      categoryTopics = {};
    }
  }

  Future<void> _loadRecommended() async {
    try {
      final response =
      await ApiClient.dio.get(
        "/api/communities/recommended",
      );

      recommended =
      List<Map<String, dynamic>>.from(
        response.data["data"],
      );
    } catch (_) {
      recommended = [];
    }
  }

  Future<void> _loadUserJoinedCommunities() async {
    try {
      final response =
      await ApiClient.dio.get(
        "/api/communities/my",
      );

      userJoinedCommunities =
      List<Map<String, dynamic>>.from(
        response.data["data"],
      );
    } catch (_) {
      userJoinedCommunities = [];
    }
  }

  bool _isJoined(
      Map<String, dynamic> community) {
    final id = community["id"]?.toString();

    return userJoinedCommunities.any(
          (c) => c["id"]?.toString() == id,
    );
  }

  List<Map<String, dynamic>>
  _filteredCommunities() {
    final q = searchQuery.toLowerCase();

    return allCommunities.where((c) {
      final name =
      (c["name"] ?? "").toLowerCase();

      if (q.isNotEmpty &&
          !name.contains(q)) {
        return false;
      }

      if (selectedTopicKey != null) {
        final topics =
            (c["topics"] as List?) ?? [];

        final hasTopic = topics.any(
              (t) =>
          t.toString() ==
              selectedTopicKey,
        );

        if (!hasTopic) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Text(
                  "Communities",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Discover people with the same interests.",
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(.9),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final selected =
              selectedCategoryKey ==
                  cat["key"];

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 10,
            ),
            child: ChoiceChip(
              label: Text(cat["name"]),
              selected: selected,
              showCheckmark: false,
              backgroundColor:
              Colors.white.withOpacity(.05),
              selectedColor:
              AppTheme.primary,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.grey.shade300,
                fontWeight:
                FontWeight.w600,
              ),
              side: BorderSide.none,
              onSelected: (_) {
                setState(() {
                  selectedCategoryKey =
                  cat["key"];
                  selectedTopicKey =
                  null;
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
        categoryTopics[selectedCategoryKey] ??
            [];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: topics.map((topic) {
          final selected =
              selectedTopicKey ==
                  topic["key"];

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 10,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTopicKey =
                  selected
                      ? null
                      : topic["key"];
                });
              },
              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 220,
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary
                      : Colors.white
                      .withOpacity(
                    .04,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    50,
                  ),
                ),
                child: Text(
                  topic["name"],
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.grey
                        .shade300,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _communityCard(
      Map<String, dynamic> c) {
    final isJoined = _isJoined(c);

    final imageUrl =
    c["iconUrl"]?.toString();
    final bannerUrl = c["bannerUrl"];
    final memberCount =
        c["memberCount"] ?? 0;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xff1B1C1F),
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color:
          Colors.white.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // BANNER
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: bannerUrl != null
                      ? Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    decoration:
                    BoxDecoration(
                      gradient:
                      LinearGradient(
                        colors: [
                          AppTheme.primary,
                          Colors.deepPurple,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.black
                        .withOpacity(.4),
                    borderRadius:
                    BorderRadius.circular(
                      40,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 15,
                        color:
                        Colors.orange,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        "Trending",
                        style: TextStyle(
                          color:
                          Colors.grey
                              .shade200,
                          fontSize: 12,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding:
            const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // AVATAR
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade800,

                    backgroundImage:
                    imageUrl != null &&
                        imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,

                    onBackgroundImageError:
                        (_, __) {},

                    child:
                    imageUrl == null ||
                        imageUrl.isEmpty
                        ? const Icon(
                      Icons.groups,
                      color: Colors.white,
                    )
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c["name"] ??
                                  "",
                              style:
                              const TextStyle(
                                fontSize:
                                18,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.verified,
                            color:
                            Colors.blue,
                            size: 18,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Row(
                        children: [
                          Icon(
                            Icons
                                .people_alt_outlined,
                            size: 16,
                            color: Colors
                                .grey
                                .shade400,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            "$memberCount members",
                            style:
                            TextStyle(
                              color: Colors
                                  .grey
                                  .shade400,
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                            const BoxDecoration(
                              color:
                              Colors.green,
                              shape:
                              BoxShape
                                  .circle,
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            "Active",
                            style:
                            TextStyle(
                              color: Colors
                                  .grey
                                  .shade400,
                              fontSize:
                              13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        c["description"] ??
                            "",
                        maxLines: 3,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade300,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                            ElevatedButton(
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                isJoined
                                    ? Colors
                                    .white
                                    .withOpacity(
                                  .08,
                                )
                                    : AppTheme
                                    .primary,
                                foregroundColor:
                                Colors
                                    .white,
                                elevation: 0,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    16,
                                  ),
                                ),
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical:
                                  14,
                                ),
                              ),
                              onPressed: () {
                                if (isJoined) {
                                  _leaveCommunity(
                                    c["id"],
                                  );
                                } else {
                                  _joinCommunity(
                                    c["id"],
                                  );
                                }
                              },
                              child: Text(
                                isJoined
                                    ? "Joined"
                                    : "Join Community",
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
    AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
      const Color(0xff111214),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding:
          const EdgeInsets.only(
            right: 12,
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(
                .05,
              ),
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),
            child: TextField(
              onChanged: (v) =>
                  setState(
                        () => searchQuery = v,
                  ),
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: l10n.search,
                hintStyle: TextStyle(
                  color:
                  Colors.grey.shade500,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color:
                  Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding:
          const EdgeInsets.all(16),
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            _categoryBar(),

            const SizedBox(height: 14),

            _topicsBar(),

            const SizedBox(height: 24),

            ..._filteredCommunities()
                .map(_communityCard)
                .toList(),
          ],
        ),
      ),
    );
  }
}




