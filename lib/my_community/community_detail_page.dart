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

  @override
  void initState() {
    super.initState();
    fetchCommunity();
  }

  Future<void> fetchCommunity() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiClient.dio.get(
        '/api/posts/community/byname/${widget.communityName}', // communityName gönder
      );

      setState(() {
        community = {
          'name': widget.communityName,
          'description': 'Community description', // opsiyonel, backend’den alabilirsiniz
          'posts': response.data, // API’den gelen postlar
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
              itemCount: community?['posts']?.length ?? 0,
              itemBuilder: (context, index) {
                final post = community!['posts'][index];
                return PostCard(
                  post: post,
                  parentContext: context,
                  onVote: (postId, vote) async {
                    // Oy verme API'si
                    try {
                      await ApiClient.dio.post('/api/posts/vote',
                          data: {"postId": postId, "vote": vote});
                      // Lokal state güncelle
                      setState(() {
                        final oldVote = post['user_vote'] ?? 0;
                        post['votes_count'] = (post['votes_count'] ?? 0) - oldVote + vote;
                        post['user_vote'] = vote;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Vote hatası: $e')));
                    }
                  },
                  onJoinCommunity: (communityName, _) async {
                    try {
                      await ApiClient.dio.post('/api/communities/join',
                          data: {"communityName": communityName});
                      setState(() {
                        post['is_member'] = true;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Join hatası: $e')));
                    }
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