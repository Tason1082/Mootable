import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  void _showMarkAllReadDialog(BuildContext context) {
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

  void _showChatFilterDialog(BuildContext context) {
    bool groupChats = true;
    bool directChats = true;
    bool modMail = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    onChanged: (v) => setState(() => groupChats = v),
                  ),
                  _SmallFilterOption(
                    label: "Doğrudan sohbetler",
                    value: directChats,
                    onChanged: (v) => setState(() => directChats = v),
                  ),
                  _SmallFilterOption(
                    label: "Mod mail",
                    value: modMail,
                    onChanged: (v) => setState(() => modMail = v),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
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
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: "Tümünü okundu işaretle",
              onPressed: () => _showMarkAllReadDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => _showChatFilterDialog(context),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE0E0E0),
              ),
            ),
          ],
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
        ),
        body: const TabBarView(
          children: [
            EmptyChatView(),
            EmptyChatView(),
            EmptyChatView(),
            EmptyChatView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 3,
          onPressed: () {},
          child: const Icon(Icons.add_comment, color: Colors.black),
        ),
      ),
    );
  }
}

class EmptyChatView extends StatelessWidget {
  const EmptyChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Sohbete hoş geldin.",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
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
      ),
    );
  }
}


