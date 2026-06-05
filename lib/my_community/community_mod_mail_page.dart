import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chat/conversation_service.dart';

class CommunityModMailPage extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityModMailPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityModMailPage> createState() =>
      _CommunityModMailPageState();
}

class _CommunityModMailPageState
    extends State<CommunityModMailPage> {

  final TextEditingController subjectController =
  TextEditingController();

  final TextEditingController messageController =
  TextEditingController();

  bool sending = false;

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    setState(() => sending = true);

    try {
      final conversationId =
      await ConversationService.create(
        title: subjectController.text.trim(),
        userIds: [
          "community:${widget.communityId}",
        ],
      );

      await ConversationService.sendMessage(
        conversationId: conversationId,
        receiverId: "community:${widget.communityId}",
        content: messageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mesaj gönderildi"),
        ),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => sending = false);
      };
  }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ship/${widget.communityName}",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: "Konu",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TextField(
                controller: messageController,
                maxLines: null,
                expands: true,
                textAlignVertical:
                TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "Mesajınızı yazın...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                sending ? null : sendMessage,
                child: sending
                    ? const CircularProgressIndicator()
                    : const Text("Gönder"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}