import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import 'chat/chat_detail_page.dart';
import 'chat/conversation_service.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  List<UserDto> users = [];
  final Set<String> selectedUserIds = {};

  bool loading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // =========================
  // API → USERS
  // =========================
  Future<void> fetchUsers() async {
    try {
      final res = await ApiClient.dio.get("/api/users");
      final data = res.data as List;

      setState(() {
        users = data.map((e) => UserDto.fromJson(e)).toList();
        loading = false;
      });
    } on DioException catch (e) {
      debugPrint(e.message);
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcılar yüklenemedi")),
      );
    }
  }

  // =========================
  // USER SELECT
  // =========================
  void toggleUser(String id) {
    setState(() {
      if (selectedUserIds.contains(id)) {
        selectedUserIds.remove(id);
      } else {
        selectedUserIds.add(id);
      }
    });
  }

  // =========================
  // CREATE CONVERSATION
  // =========================
  Future<void> createChat() async {
    if (selectedUserIds.isEmpty) return;

    try {
      final ids = selectedUserIds.toList();
      final title = ids.length == 1 ? null : _groupNameController.text.trim();

      final conversationId = await ConversationService.create(
        title: title,
        userIds: ids,
      );

      if (!mounted) return;

      final isDm = ids.length == 1;

      // DM ise receiverId al
      String? receiverId;
      if (isDm) {
        receiverId = ids.first;
      }

      if (isDm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Var olan DM açıldı")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yeni grup sohbeti oluşturuldu")),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conversationId,
            receiverId: receiverId, // receiverId’yi ChatDetailPage’e gönder
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }


  @override
  Widget build(BuildContext context) {
    final filtered = users
        .where((u) => u.username.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final isGroup = selectedUserIds.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Sohbet"),
        actions: [
          TextButton(
            onPressed: createChat,
            child: const Text(
              "Oluştur",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => query = v),
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

          // 👥 Selected count
          if (selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${selectedUserIds.length} kişi seçildi",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

          // 🟢 GROUP NAME
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

          // 👤 USER LIST
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final user = filtered[i];
                final selected = selectedUserIds.contains(user.id);

                return ListTile(
                  leading: const CircleAvatar(),
                  title: Text(user.username),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (_) => toggleUser(user.id),
                  ),
                  onTap: () => toggleUser(user.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// DTO
// =========================
class UserDto {
  final String id;
  final String username;

  UserDto({
    required this.id,
    required this.username,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json["id"],
      username: json["username"],
    );
  }
}

