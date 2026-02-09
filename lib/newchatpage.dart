import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  final List<String> _allUsers = [
    "Ahmet",
    "Ayşe",
    "Mehmet",
    "Zeynep",
    "Can",
    "Elif",
  ];

  final Set<String> _selectedUsers = {};

  String _query = "";

  void _toggleUser(String user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _createChat() {
    if (_selectedUsers.isEmpty) return;

    if (_selectedUsers.length == 1) {
      /// Direkt sohbet
      final user = _selectedUsers.first;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$user ile sohbet başlatıldı")),
      );
    } else {
      /// Grup sohbeti
      final groupName = _groupNameController.text.trim();

      if (groupName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grup adı giriniz")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "$groupName adlı grup oluşturuldu (${_selectedUsers.length} kişi)"),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _allUsers
        .where((u) => u.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final isGroup = _selectedUsers.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Sohbet"),
        actions: [
          TextButton(
            onPressed: _createChat,
            child: const Text(
              "Oluştur",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// 🔍 Arama
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Kullanıcı ara",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 👥 Seçim sayacı
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${_selectedUsers.length} kişi seçildi",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

          /// 🟢 Grup adı (2+ kişi seçilince)
          if (isGroup)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: "Grup adı gir",
                  prefixIcon: const Icon(Icons.group),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          /// 👤 Kullanıcı listesi
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (_, index) {
                final user = filteredUsers[index];
                final selected = _selectedUsers.contains(user);

                return ListTile(
                  leading: const CircleAvatar(),
                  title: Text(user),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleUser(user),
                  ),
                  onTap: () => _toggleUser(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
