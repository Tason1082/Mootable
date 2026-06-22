import 'package:flutter/material.dart';

import '../chat/conversation_service.dart';
import '../chat/message_model.dart';

class CommunityMailPage extends StatefulWidget {
  final String communityId;

  const CommunityMailPage({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityMailPage> createState() => _ModMailPageState();
}

class _ModMailPageState extends State<CommunityMailPage> {
  List<MessageModel> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await ConversationService.getCommunityMessages(
        widget.communityId,
      );

      if (!mounted) return;

      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Henüz topluluğa gelen mail yok",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluğa Gelen Mailler"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        constraints: const BoxConstraints(
                          maxHeight: 500,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                  item.senderProfileImage != null &&
                                      item.senderProfileImage!.isNotEmpty
                                      ? NetworkImage(
                                    item.senderProfileImage!,
                                  )
                                      : null,
                                  child: item.senderProfileImage == null ||
                                      item.senderProfileImage!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.senderUsername ?? item.senderId,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const Divider(height: 30),

                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  item.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Kapat"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                      item.senderProfileImage != null &&
                          item.senderProfileImage!.isNotEmpty
                          ? NetworkImage(item.senderProfileImage!)
                          : null,
                      child: item.senderProfileImage == null ||
                          item.senderProfileImage!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.senderUsername ?? item.senderId,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 18,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Mesajı Aç",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}