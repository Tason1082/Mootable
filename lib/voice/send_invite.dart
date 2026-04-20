import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../profile_page.dart';

class SendInvitePage extends StatefulWidget {
  final int roomId;

  const SendInvitePage({super.key, required this.roomId});

  @override
  State<SendInvitePage> createState() => _SendInvitePageState();
}

class _SendInvitePageState extends State<SendInvitePage> {
  List users = [];
  List selectedUsers = [];
  bool sending = false;
  final TextEditingController controller = TextEditingController();

  Future<void> search(String value) async {
    if (value.isEmpty) {
      setState(() => users = []);
      return;
    }

    final result = await ApiService.searchUsers(value);

    setState(() {
      users = result;
    });
  }

  void addUser(user) {
    if (!selectedUsers.any((u) => u["id"] == user["id"])) {
      setState(() {
        selectedUsers.add(user);
      });
    }
  }

  void removeUser(user) {
    setState(() {
      selectedUsers.removeWhere((u) => u["id"] == user["id"]);
    });
  }

  void goToProfile(user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          username: user["username"], // 🔥 tıklanan kullanıcı
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Davet Gönder"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔍 SEARCH
            TextField(
              controller: controller,
              onChanged: search,
              decoration: const InputDecoration(
                hintText: "Kullanıcı ara...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            /// ✅ SELECTED USERS
            if (selectedUsers.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = selectedUsers[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              /// 👤 AVATAR
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: user["profileImageUrl"] != null
                                    ? NetworkImage(user["profileImageUrl"])
                                    : null,
                                child: user["profileImageUrl"] == null
                                    ? Text(
                                  (user["username"] ?? "?")[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                                    : null,
                              ),

                              /// ❌ REMOVE BUTTON
                              Positioned(
                                right: -6,
                                top: -6,
                                child: GestureDetector(
                                  onTap: () => removeUser(user),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          /// 🧑 USERNAME
                          SizedBox(
                            width: 60,
                            child: Text(
                              user["username"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            /// 📋 USER LIST
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  final isSelected = selectedUsers
                      .any((u) => u["id"] == user["id"]);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),

                    /// 👤 AVATAR (PROFILE NAV)
                    leading: GestureDetector(
                      onTap: () => goToProfile(user),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: user["profileImageUrl"] != null
                            ? NetworkImage(user["profileImageUrl"])
                            : null,
                        child: user["profileImageUrl"] == null
                            ? Text(
                          (user["username"] ?? "?")[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                            : null,
                      ),
                    ),

                    /// 🧑 USERNAME + BIO (PROFILE NAV)
                    title: GestureDetector(
                      onTap: () => goToProfile(user),
                      child: Text(
                        user["username"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user["fullName"] != null &&
                            user["fullName"].toString().isNotEmpty)
                          Text(
                            user["fullName"],
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        if (user["bio"] != null &&
                            user["bio"].toString().isNotEmpty)
                          Text(
                            user["bio"],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                      ],
                    ),

                    /// ✅ SELECT ICON
                    trailing: GestureDetector(
                      onTap: () => addUser(user),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: isSelected ? Colors.green : null,
                      ),
                    ),

                    /// 🔥 SATIR TIK → SELECT
                    onTap: () => addUser(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// 🚀 SEND BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: (selectedUsers.isEmpty || sending)
            ? null
            : () async {
          setState(() => sending = true);

          final receiverIds = selectedUsers
              .map<String>((u) => u["id"].toString())
              .toList();

          final success = await ApiService.sendVoiceRoomInvites(
            roomId: widget.roomId,
            receiverIds: receiverIds,
          );

          if (!mounted) return;

          setState(() => sending = false);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Davetler gönderildi")),
            );

            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Hata oluştu")),
            );
          }
        },
        child: sending
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.send),
      ),
    );
  }
}