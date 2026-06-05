
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'community_mod_mail_page.dart';
import '../core/api_service.dart';
import '../post/post_card.dart';

import '../core/api_client.dart';

// 🔥 EKLENDİ
import '../home/home_page_functions.dart';
import 'community_settings_page.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityName;

  const CommunityDetailPage({super.key, required this.communityName});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Map<String, dynamic>? community;
  bool isLoading = true;
  bool _isAdult = false;
  String? error;
  bool _isJoined = false;
  bool _loadingJoin = true;
  late String communityName;
  List<Map<String, dynamic>> filteredPosts = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  // 🔥 EKLENDİ (joinCommunity için gerekli)
  List<Map<String, dynamic>> posts = [];
  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final TextEditingController _topicsController =
  TextEditingController();

  String _selectedType = "public";



  bool _updatingCommunity = false;
  @override
  void initState() {
    super.initState();
    communityName = widget.communityName;
    fetchCommunity();
  }
  void _filterPosts(String query) {
    final lowerQuery = query.toLowerCase();

    final results = posts.where((post) {
      final content = (post["content"] ?? "").toString().toLowerCase();
      return content.contains(lowerQuery);
    }).toList();

    setState(() {
      filteredPosts = results;
    });
  }
  void _openCommunityImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                // 🔥 TOP BAR (geri + boşluk)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // 🔥 IMAGE
                Expanded(
                  child: Center(
                    child: community?['image'] != null
                        ? Image.network(
                      community!['image'],
                      fit: BoxFit.contain,
                    )
                        : const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),

                // 🔥 ALT BUTON (artık yukarıda ve safe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _pickAndUploadImage();
                        Navigator.pop(context);
                      },
                      child: const Text("Topluluk resmini değiştir"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _shareCommunity() {
    final url = "https://mootable.com/r/${communityName}";

    Share.share(
      "Bu community'ye bak 👇\n$url",
    );
  }

  Future<void> _checkIfJoined() async {
    try {
      final communityId = posts.isNotEmpty
          ? posts[0]["communityId"].toString()
          : null;

      if (communityId == null) return;

      final joined = await ApiService.isJoined(communityId);

      if (mounted) {
        setState(() {
          _isJoined = joined;
          _loadingJoin = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      final communityId = posts.isNotEmpty
          ? posts[0]["communityId"].toString()
          : null;

      if (communityId == null) return;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          picked.path,
        ),
        "type": "icon",
      });

      final response = await ApiClient.dio.post(
        "/api/communities/$communityId/upload-image",
        data: formData,
      );

      final data = response.data;

      debugPrint("UPLOAD IMAGE RESPONSE: ${response.data.runtimeType}");
      debugPrint("UPLOAD IMAGE BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      await fetchCommunity();
    } catch (e) {
      debugPrint("UPLOAD IMAGE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload başarısız: $e"),
        ),
      );
    }
  }
  bool get canManageCommunity {
    final role = community?['myRole'];

    // Leader = 0
    // CoLeader = 1

    return role == 0 || role == 1;
  }
  Future<void> _toggleJoin() async {
    final communityId = posts.isNotEmpty
        ? posts[0]["communityId"].toString()
        : null;

    if (communityId == null) return;

    setState(() {
      _loadingJoin = true;
    });

    try {
      Response response;

      if (_isJoined) {
        response = await ApiClient.dio.delete(
          "/api/communities/$communityId/leave",
        );
      } else {
        response = await ApiClient.dio.post(
          "/api/communities/$communityId/join",
        );
      }

      final data = response.data;

      debugPrint("JOIN RESPONSE: ${response.data.runtimeType}");
      debugPrint("JOIN BODY: ${response.data}");

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      _isJoined = !_isJoined;

      setState(() {});
    } catch (e) {
      debugPrint("JOIN ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İşlem başarısız: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingJoin = false;
        });
      }
    }
  }
  void _showCommunityMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text("Özel akışa ekle"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: const Text("Rozeti düzenle"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(
                  "Bu topluluk hakkında daha fazla bilgi edin",
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text("Moderatörlere mesaj at"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityModMailPage(
                        communityId: community?['id']?.toString() ?? '',
                        communityName: community?['name'] ?? '',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_off_outlined),
                title: Text(
                  "ship/${community?['name']} adlı subtable'i sessize al",
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Ana ekrana ekle"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> fetchCommunity() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiClient.dio.get(
          '/api/communities/${communityName}'
      );

      final body = response.data;

      debugPrint("COMMUNITY RESPONSE: ${response.data.runtimeType}");
      debugPrint("COMMUNITY BODY: ${response.data}");

      if (body["success"] != true) {
        throw Exception(body["message"]);
      }

      final data = Map<String, dynamic>.from(
        body["data"],
      );

      setState(() {
        community = {
          'id': data['id'],
          'name': data['name'],
          'description': data['description'] ?? '',
          'image': data['iconUrl'],
          'banner': data['bannerUrl'],
          'memberCount': data['memberCount'],
          'isMember': data['isMember'],
          'myRole': data['myRole'],

          // EKLE
          'type': data['type'] ?? 'public',
          'topics': data['topics'] ?? [],
          'isAdult': data['isAdult'] ?? false,
        };

// CONTROLLERLARI DOLDUR
        _nameController.text = data['name'] ?? '';

        _descriptionController.text =
            data['description'] ?? '';

        _topicsController.text =
            (data['topics'] as List?)
                ?.join(", ") ??
                '';

        _selectedType =
            data['type'] ?? 'public';

        _isAdult =
            data['isAdult'] ?? false;

        isLoading = false;
      });

      // POSTS
      final response2 = await ApiClient.dio.get(
        '/api/posts/community/byname/${communityName}',
      );

      final postsBody = response2.data;

      debugPrint("COMMUNITY POSTS RESPONSE: ${response2.data.runtimeType}");
      debugPrint("COMMUNITY POSTS BODY: ${response2.data}");

      if (postsBody["success"] != true) {
        throw Exception(postsBody["message"]);
      }

      final List rawList = postsBody["data"] ?? [];

      final mappedPosts = rawList.map((p) {
        final map = Map<String, dynamic>.from(p);

        return {
          ...map,

          "votes_count": map["netScore"] ?? 0,
          "user_vote": map["userVote"] ?? 0,

          "created_at": map["createdAt"],

          "comment_count": map["commentCount"] ?? 0,
        };
      }).toList();

      setState(() {
        posts = mappedPosts;
        filteredPosts = mappedPosts;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint("COMMUNITY LOAD ERROR: $e");

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }

    _checkIfJoined();
  }
  Future<void> _updateCommunity() async {
    try {
      setState(() {
        _updatingCommunity = true;
      });

      final communityId = community?['id'];

      final topics = _topicsController.text
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final body = {
        "name": _nameController.text.trim(),
        "description":
        _descriptionController.text.trim(),
        "topics": topics,
        "type": _selectedType,
        "isAdult": _isAdult,
      };

      final response = await ApiClient.dio.put(
        "/api/communities/$communityId",
        data: body,
      );

      final data = response.data;

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      Navigator.pop(context);

      await fetchCommunity();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Topluluk güncellendi"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Güncelleme başarısız: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCommunity = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text("Hata: $error")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Post ara...",
            border: InputBorder.none,
          ),
          onChanged: _filterPosts,
        )
            : Row(
          children: [
            /// 🔥 TIKLANABİLİR AVATAR
            GestureDetector(
              onTap: () => _openCommunityImage(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                backgroundImage: community?['image'] != null
                    ? NetworkImage(community!['image'])
                    : null,
                child: community?['image'] == null
                    ? const Icon(Icons.groups, color: Colors.white, size: 18)
                    : null,
              ),
            ),

            const SizedBox(width: 8),

            Text(
              "r/${community?['name'] ?? ''}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  filteredPosts = posts;
                }
                isSearching = !isSearching;
              });
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCommunity,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showCommunityMenu,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ship/${community?['name'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  community?['description'] ?? '',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.bar_chart, size: 16),
                    const SizedBox(width: 4),
                    const Text("Haftalık 1 ziyaretçi"),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (canManageCommunity)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child:OutlinedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunitySettingsPage(
                                      community: community!,
                                      onUpdated: fetchCommunity,
                                      onNameChanged: (newName) {
                                        setState(() {
                                          communityName = newName;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Topluluk Ayarları"),
                            ),
                          ),

                        _loadingJoin
                            ? const SizedBox(
                          width: 80,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : ElevatedButton(
                          onPressed: _toggleJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            _isJoined ? Colors.grey[300] : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(_isJoined ? "Ayrıl" : "Katıl"),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // POSTS
          Expanded(
            child: ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];

                return PostCard(
                  post: post,
                  parentContext: context,
                  onVote: (postId, vote) {
                    toggleVote(this, postId, vote);
                  },
                  onJoinCommunity: (communityName, _) {
                    joinCommunity(this, communityName, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }}