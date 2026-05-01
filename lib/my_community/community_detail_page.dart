import 'dart:typed_data';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../TimeAgo.dart';
import '../comment/comment_page.dart';
import '../core/api_service.dart';
import '../post/post_card.dart';
import '../quote_post_page.dart';
import '../video_player_widget.dart';
import '../core/api_client.dart';

// 🔥 EKLENDİ
import '../home/home_page_functions.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityName;

  const CommunityDetailPage({super.key, required this.communityName});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Map<String, dynamic>? community;
  bool isLoading = true;
  String? error;
  bool _isJoined = false;
  bool _loadingJoin = true;
  List<Map<String, dynamic>> filteredPosts = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  // 🔥 EKLENDİ (joinCommunity için gerekli)
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
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
    final url = "https://mootable.com/r/${widget.communityName}";

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
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final communityId = posts.isNotEmpty
          ? posts[0]["communityId"].toString()
          : null;

      if (communityId == null) return;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(picked.path),
        "type": "icon", // 🔥 önemli
      });

      await ApiClient.dio.post(
        "/api/communities/$communityId/upload-image",
        data: formData,
      );

      // 🔥 tekrar çek (signed url yenilensin)
      await fetchCommunity();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload başarısız: $e")),
      );
    }
  }
  Future<void> _toggleJoin() async {
    final communityId = posts.isNotEmpty
        ? posts[0]["communityId"].toString()
        : null;

    if (communityId == null) return;

    setState(() => _loadingJoin = true);

    try {
      if (_isJoined) {
        await ApiService.leaveCommunity(communityId);
        _isJoined = false;
      } else {
        await ApiService.joinCommunity(communityId);
        _isJoined = true;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("İşlem başarısız: $e")));
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }
  Future<void> fetchCommunity() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiClient.dio.get(
        '/api/communities/${widget.communityName}',
      );

      final data = Map<String, dynamic>.from(response.data);

      setState(() {
        community = {
          'id': data['id'],
          'name': data['name'],
          'description': data['description'] ?? '',
          'image': data['iconUrl'],
          'banner': data['bannerUrl'],
          'memberCount': data['memberCount'],
          'isMember': data['isMember'],
        };

        isLoading = false;
      });

      // 🔥 POSTS FETCH (SAFE)
      final response2 = await ApiClient.dio.get(
        '/api/posts/community/byname/${widget.communityName}',
      );

// 🔥 OUTER MAP
      final Map<String, dynamic> body =
      Map<String, dynamic>.from(response2.data);

// 🔥 INNER LIST
      final List rawList = body["data"] as List;

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

      setState(() {
        error = e.toString();
        isLoading = false;
      });

      debugPrint("COMMUNITY LOAD ERROR: $e");
    }

    _checkIfJoined();
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
          const Icon(Icons.more_vert),
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
                    _loadingJoin
                        ? const SizedBox(
                      width: 80,
                      child: Center(
                          child:
                          CircularProgressIndicator(strokeWidth: 2)),
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