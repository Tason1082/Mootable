import 'package:flutter/material.dart';

class CommunityDetailPage extends StatelessWidget {
  final Map<String, dynamic> community;

  const CommunityDetailPage({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context) {
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
              backgroundImage: community['image'] != null
                  ? NetworkImage(community['image'])
                  : null,
              child: community['image'] == null
                  ? const Icon(Icons.groups, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              "r/${community['name']}",
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
                  "r/${community['name']}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  community['description'] ?? '',
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
              itemCount: 1,
              itemBuilder: (context, index) {
                return _postCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    community['name'][0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "tason12345 • 1 ay",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Sa",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.arrow_upward, size: 20),
                SizedBox(width: 4),
                Text("1"),
                SizedBox(width: 16),
                Icon(Icons.comment_outlined, size: 20),
                SizedBox(width: 4),
                Text("0"),
                Spacer(),
                Icon(Icons.bookmark_border),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
