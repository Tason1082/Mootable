import 'package:flutter/material.dart';
import 'package:mootable/voice/voice_room_page.dart';
import 'package:mootable/voice/voice_service.dart';

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

class DavetlerView extends StatelessWidget {
  const DavetlerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.person),
          title: Text("Ahmet seni davet etti"),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text("Ayşe seni davet etti"),
        ),
      ],
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

  Future<void> _createRoom() async {
    setState(() => _creating = true);

    try {
      final roomId = await VoiceService.createRoom();

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// 🔵 ÜSTTE BUTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _creating ? null : _createRoom,
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
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 📋 ALTTA ODA LİSTESİ
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
                final room = _rooms[index];

                return InkWell(
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
                      color: const Color(0xFF4B5CFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                          "Oda ${room["id"]}",
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