import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chat/chat_detail_page.dart';
import '../chat/conversation_list_model.dart';
import '../chat/conversation_service.dart';

class ModMailPage extends StatefulWidget {
  const ModMailPage({super.key});

  @override
  State<ModMailPage> createState() => _ModMailPageState();
}

class _ModMailPageState extends State<ModMailPage> {
  List<ConversationListModel> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await ConversationService.getAll();

    final filtered = data
        .where((c) => c.name.startsWith("community:"))
        .toList();

    setState(() {
      items = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(
        child: Text("Henüz mod mail yok"),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];

        return ListTile(
          leading: const Icon(Icons.mail_outline),
          title: Text(item.lastMessage.isEmpty
              ? "Yeni mesaj"
              : item.lastMessage),
          subtitle: Text(item.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  conversationId: item.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}