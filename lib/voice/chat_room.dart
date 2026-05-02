import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mootable/voice/voice_manager.dart';
import 'package:mootable/voice/voice_room_page.dart';
import 'package:mootable/voice/voice_service.dart';
import 'package:mootable/voice/voice_signalr.dart';

import '../core/api_service.dart';


class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text("Sohbet Odası"),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF4B5CFF),
            tabs: [
              Tab(text: "Link Gir"),
              Tab(text: "Davetler"),
              Tab(text: "Sohbet Başlat"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            LinkGirView(),
            DavetlerView(),
            SohbetBaslatView(),
          ],
        ),
      ),
    );
  }
}

class LinkGirView extends StatefulWidget {
  const LinkGirView({super.key});

  @override
  State<LinkGirView> createState() => _LinkGirViewState();
}

class _LinkGirViewState extends State<LinkGirView> {
  final TextEditingController _controller = TextEditingController();

  List<dynamic> joinedRooms = [];
  bool loading = false;
  bool fetchingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadJoinedRooms();
  }

  Future<void> _loadJoinedRooms() async {
    setState(() => fetchingRooms = true);
    try {
      final rooms = await VoiceService.getJoinedRooms();
      setState(() => joinedRooms = rooms);
    } catch (e) {
      debugPrint("Joined rooms yükleme hatası: $e");
    }
    setState(() => fetchingRooms = false);
  }

  Future<void> joinRoom() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => loading = true);

    try {
      final roomId = await VoiceService.joinByInvite(code);
      _controller.clear();

      // Katıldığın odaları yeniden yükle
      await _loadJoinedRooms();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Odaya katıldın!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçersiz davet kodu")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          /// LINK INPUT
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Davet kodunu yapıştır",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// KATIL BUTONU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : joinRoom,
              child: loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text("Katıl"),
            ),
          ),

          const SizedBox(height: 25),

          /// ALTTA KATILDIĞI ODALAR
          Expanded(
            child: fetchingRooms
                ? const Center(child: CircularProgressIndicator())
                : joinedRooms.isEmpty
                ? const Center(child: Text("Henüz katıldığın oda yok"))
                : GridView.builder(
              itemCount: joinedRooms.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final room = joinedRooms[index];
                final roomId = room["id"];

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5CFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VoiceRoomPage(roomId: roomId),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Oda $roomId",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DavetlerView extends StatefulWidget {
  const DavetlerView({super.key});

  @override
  State<DavetlerView> createState() => _DavetlerViewState();
}

class _DavetlerViewState extends State<DavetlerView> {
  List<Map<String, dynamic>> invites = [];
  bool isLoading = true;

  late VoiceSignalR signalR;

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    signalR = VoiceSignalR();

    // 🔴 REAL-TIME INVITE
    signalR.onInvite = (invite) {
      setState(() {
        invites.insert(0, invite);
      });
    };

    await signalR.connect();

    await fetchInvites();
  }

  Future<void> fetchInvites() async {
    final data = await ApiService.getMyInvites();

    setState(() {
      for (var newInvite in data) {
        final exists = invites.any((x) => x["id"] == newInvite["id"]);
        if (!exists) {
          invites.add(newInvite);
        }
      }

      isLoading = false;
    });
  }
  Future<void> handleAccept(Map<String, dynamic> invite) async {
    final inviteId = invite["id"];
    final roomId = invite["roomId"] ?? invite["RoomId"] ?? invite["voiceRoomId"];

    final success = await ApiService.acceptInvite(inviteId);

    if (success) {
      // listeden kaldır
      setState(() {
        invites.removeWhere((x) => x["id"] == inviteId);
      });

      // odaya katıl
      await signalR.joinRoom(roomId.toString());

      // voice ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(roomId: roomId),
        ),
      );
    }
  }

  Future<void> handleReject(Map<String, dynamic> invite) async {
    final inviteId = invite["id"];

    final success = await ApiService.rejectInvite(inviteId);

    if (success) {
      setState(() {
        invites.removeWhere((x) => x["id"] == inviteId);
      });
    }
  }

  @override
  void dispose() {
    signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invites.isEmpty) {
      return const Center(child: Text("Hiç davetin yok"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];


        final sender = invite["sender"] ?? invite["Sender"] ?? {};

        final senderName =
            sender["userName"] ??
                sender["username"] ??
                sender["UserName"] ??
                "Biri";

        final senderImage =
            sender["profileImage"] ??
                sender["profileImageUrl"] ??
                sender["ProfileImageUrl"];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: senderImage != null
                  ? NetworkImage(senderImage)
                  : null,
              child: senderImage == null ? const Icon(Icons.person) : null,
            ),
            title: Text("$senderName seni odaya davet etti"),
            subtitle: Row(
              children: [
                ElevatedButton(
                  onPressed: () => handleAccept(invite),
                  child: const Text("Kabul Et"),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => handleReject(invite),
                  child: const Text("Reddet"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class SohbetBaslatView extends StatefulWidget {
  const SohbetBaslatView({super.key});

  @override
  State<SohbetBaslatView> createState() => _SohbetBaslatViewState();
}

class _SohbetBaslatViewState extends State<SohbetBaslatView> {
  bool _loading = true;
  bool _creating = false;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await VoiceService.getMyRooms();
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Oda yükleme hatası: $e");
    }
  }

  Future<void> _createRoom(String name, int maxMembers) async {
    setState(() => _creating = true);

    try {
      final roomId = await VoiceService.createRoom(
        name: name,
        maxMembers: maxMembers,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(roomId: roomId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Oda oluşturuldu! ID: $roomId")),
      );

      await _loadRooms();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oda oluşturulamadı")),
      );
    }

    setState(() => _creating = false);
  }

  Future<void> _showCreateRoomDialog() async {
    final nameController = TextEditingController();
    final countController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Oda Oluştur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Oda adı"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Kişi sayısı"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final count = int.tryParse(countController.text) ?? 0;

                if (name.isEmpty || count <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bilgileri doğru gir")),
                  );
                  return;
                }

                Navigator.pop(context);
                _createRoom(name, count);
              },
              child: const Text("Oluştur"),
            ),
          ],
        );
      },
    );
  }

  /// 🔥 DISCORD TARZI CARD
  Widget _buildRoomCard(dynamic room) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        final roomId = room["id"];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceRoomPage(roomId: roomId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2D31),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Color(0xFF5865F2),
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              room["name"] ?? "Oda ${room["id"]}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  "${room["maxMembers"] ?? "-"} kişi",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1F22), // 🔥 arka plan
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔵 BUTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _showCreateRoomDialog,
                icon: _creating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.add),
                label: const Text("Yeni Sohbet Başlat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5865F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📋 LİSTE
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rooms.isEmpty
                  ? const Center(child: Text("Henüz oda yok"))
                  : GridView.builder(
                itemCount: _rooms.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return _buildRoomCard(_rooms[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}