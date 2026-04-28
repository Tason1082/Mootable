import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'conversation_service.dart';
import 'message_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signalr_service.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final String? receiverId;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    this.receiverId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<MessageModel> messages = [];

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  String? myUserId;
  String? token;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    myUserId = await storage.read(key: "userId");
    token = await storage.read(key: "token");

    if (!mounted) return;
    if (myUserId == null || token == null) return;

    await _loadInitialMessages();

    await SignalRService.connect(token!);
    await SignalRService.joinConversation(widget.conversationId);

    SignalRService.onMessage((data) {
      if (!mounted) return;
      if (data == null || data.isEmpty) return;

      final map = Map<String, dynamic>.from(data.first as Map);

      final incoming = MessageModel.fromJson(map);

      if (incoming.conversationId != widget.conversationId) return;

      final exists = messages.any((m) => m.id == incoming.id);
      if (exists) return;

      setState(() {
        messages.add(incoming);
      });

      _scrollToBottom();
    });

    setState(() {});
  }

  Future<void> _loadInitialMessages() async {
    final convo = await ConversationService.get(widget.conversationId);

    final msgs = convo.messages;

    await Future.wait(
      msgs.map((msg) async {
        final user = await ApiService.getUserById(msg.senderId);

        msg.senderUsername = user?["username"] ?? "Unknown";
        msg.senderProfileImage = user?["profileImageUrl"];
      }),
    );

    if (!mounted) return;

    setState(() {
      messages = msgs;
    });

    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    await SignalRService.sendMessage(
      widget.conversationId,
      text,
    );

    controller.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (!scrollController.hasClients) return;

      scrollController.jumpTo(
        scrollController.position.maxScrollExtent,
      );
    });
  }

  String formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    SignalRService.disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (myUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sohbet")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isMe = msg.senderId == myUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: msg.senderProfileImage != null
                              ? NetworkImage(msg.senderProfileImage!)
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          child: msg.senderProfileImage == null
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ],

                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.senderUsername ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                            const SizedBox(height: 2),

                            Text(
                              msg.content,
                              style: const TextStyle(fontSize: 15),
                            ),

                            const SizedBox(height: 4),

                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                formatTime(msg.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Mesaj yaz...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



