import 'package:flutter/material.dart';
import 'conversation_service.dart';
import 'message_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final String? receiverId; // DM alıcısı

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
  final controller = TextEditingController();
  final scrollController = ScrollController();

  String? myUserId;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // 🔹 Login sonrası saklanan userId'yi al
  Future<void> _loadUserId() async {
    final id = await storage.read(key: "userId");
    setState(() {
      myUserId = id;
    });
    _load(); // kullanıcı ID alındıktan sonra mesajları yükle
  }

  Future<void> _load() async {
    if (myUserId == null) return; // ID yoksa yükleme yapma

    final convo = await ConversationService.get(widget.conversationId);

    setState(() {
      messages = convo.messages;
    });

    _scrollToBottom();
  }

  Future<void> _send() async {
    if (myUserId == null) return;

    final text = controller.text.trim();
    if (text.isEmpty) return;

    await ConversationService.sendMessage(
      widget.conversationId,
      text,
      receiverId: widget.receiverId,
    );

    controller.clear();
    _load();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  String formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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

                print("MY ID: $myUserId (${myUserId.runtimeType})");
                print("SENDER: ${msg.senderId} (${msg.senderId.runtimeType})");
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFDCF8C6) : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg.content, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(formatTime(msg.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Mesaj yaz...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
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



