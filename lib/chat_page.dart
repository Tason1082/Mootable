import 'package:flutter/material.dart';

import 'chat/chat_detail_page.dart';
import 'chat/conversation_list_model.dart';
import 'chat/conversation_service.dart';
import 'newchatpage.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ConversationListModel> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ConversationService.getAll();

      setState(() {
        conversations = list;
        isLoading = false;
      });
    } catch (e) {
      print("LOAD ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildConversationList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversations.isEmpty) {
      return const SizedBox();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final convo = conversations[index];

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(Icons.chat_bubble_outline, color: Colors.black),
            ),
            title: Text(
              convo.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              convo.lastMessage.isNotEmpty
                  ? convo.lastMessage
                  : "Henüz mesaj yok",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: convo.lastMessageAt != null
                ? Text(
              _formatDate(convo.lastMessageAt!),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
                : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatDetailPage(conversationId: convo.id),
                ),
              );

              _load(); // geri dönünce liste refresh olsun
            },

          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return "Dün";
    } else {
      return "${date.day}.${date.month}.${date.year}";
    }
  }

  void _showMarkAllReadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mesajları okundu olarak işaretle"),
        content: const Text(
          "Okunmamış tüm mesajları okundu olarak işaretlemek istiyor musun?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tüm mesajlar okundu olarak işaretlendi"),
                ),
              );
            },
            child: const Text(
              "Evet",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatFilterDialog() {
    bool groupChats = true;
    bool directChats = true;
    bool modMail = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Sohbetleri filtrele",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SmallFilterOption(
                    label: "Grup sohbetleri",
                    value: groupChats,
                    onChanged: (v) => setStateDialog(() => groupChats = v),
                  ),
                  _SmallFilterOption(
                    label: "Doğrudan sohbetler",
                    value: directChats,
                    onChanged: (v) => setStateDialog(() => directChats = v),
                  ),
                  _SmallFilterOption(
                    label: "Mod mail",
                    value: modMail,
                    onChanged: (v) => setStateDialog(() => modMail = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sohbet filtreleri uygulandı"),
                      ),
                    );
                  },
                  child: const Text(
                    "Uygula",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text(
            "Sohbetler",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Mesajlar"),
              Tab(text: "Okunmamış"),
              Tab(text: "İstekler"),
              Tab(text: "İleti dizisi"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _showMarkAllReadDialog,
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showChatFilterDialog,
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE0E0E0),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildConversationList(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 3,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewChatPage(),
              ),
            );

            _load();
          },
          child: const Icon(Icons.add_comment, color: Colors.black),
        ),
      ),
    );
  }
}

class _SmallFilterOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SmallFilterOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}


