import 'package:flutter/material.dart';
import '../post/post_card.dart';
import '../core/api_client.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailPage> createState() =>
      _PostDetailPageState();
}

class _PostDetailPageState
    extends State<PostDetailPage> {
  Map<String, dynamic>? post;
  bool loading = true;

  @override
  @override
  void initState() {
    super.initState();

    debugPrint("🔥 POST DETAIL OPENED - ID: ${widget.postId}");

    _loadPost();
  }
  Future<void> _loadPost() async {
    try {
      final res = await ApiClient.dio.get(
        "/api/posts/${widget.postId}",
      );
      debugPrint("📦 POST RESPONSE: ${res.data}");
      setState(() {
        post = res.data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (post == null) {
      return const Scaffold(
        body: Center(child: Text("Post bulunamadı")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gönderi")),

      // 🔥 BURASI KRİTİK
      body: PostCard(
        post: post!,
        parentContext: context,
        isMyPost: false,
      ),
    );
  }
}