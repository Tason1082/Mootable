import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../TimeAgo.dart';
import '../comment/comment_page.dart';
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

  // 🔥 EKLENDİ (joinCommunity için gerekli)
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    fetchCommunity();
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
        posts = mappedPosts; // 🔥 önemli
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
        title: Row(
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
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 12),
          Icon(Icons.share),
          SizedBox(width: 12),
          Icon(Icons.more_vert),
          SizedBox(width: 8),
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
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Katıldın"),
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
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

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