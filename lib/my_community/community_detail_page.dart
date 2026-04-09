import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
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
    setState(() => isLoading = true);
    try {
      final response = await ApiClient.dio.get(
        '/api/posts/community/byname/${widget.communityName}',
      );

      // 🔥 MAPPING EKLENDİ
      final raw = List<Map<String, dynamic>>.from(response.data);

      final mappedPosts = raw.map((p) {
        return {
          ...p,
          "votes_count": p["netScore"] ?? 0,
          "user_vote": p["userVote"] ?? 0,
          "created_at": p["createdAt"],
          "community": p["community"],
          "communityId": p["communityId"],
          "comment_count": p["commentCount"] ?? 0,
        };
      }).toList();

      setState(() {
        posts = mappedPosts;
        filteredPosts = mappedPosts; // 🔥 BURAYA EKLİYORSUN

        community = {
          'name': widget.communityName,
          'description': 'Community description',
          'posts': mappedPosts,
        };

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }_checkIfJoined();
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
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              backgroundImage: community?['image'] != null
                  ? NetworkImage(community!['image'])
                  : null,
              child: community?['image'] == null
                  ? const Icon(Icons.groups, color: Colors.white, size: 18)
                  : null,
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
          const Icon(Icons.share),
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
                  "r/${community?['name'] ?? ''}",
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
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                        : ElevatedButton(
                      onPressed: _toggleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined ? Colors.grey[300] : null,
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
              itemCount: filteredPosts.length, // 🔥 BURASI
              itemBuilder: (context, index) {
                final post = filteredPosts[index]; // 🔥 BURASI

                return PostCard(
                  post: post,
                  parentContext: context,

                  // 🔥 ARTIK GLOBAL FONKSİYON
                  onVote: (postId, vote) {
                    toggleVote(this, postId, vote);
                  },

                  // 🔥 INDEX FIX + GLOBAL JOIN
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
  }
}