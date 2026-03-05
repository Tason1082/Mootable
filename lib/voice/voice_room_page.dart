import 'package:flutter/material.dart';
import '../../voice/voice_service.dart';

class VoiceRoomPage extends StatefulWidget {
  final int roomId;

  const VoiceRoomPage({super.key, required this.roomId});

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {

  bool loading = true;
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final data = await VoiceService.getMembers(widget.roomId);

      setState(() {
        members = data;
        loading = false;
      });

    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Oda ${widget.roomId}"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
          ? const Center(child: Text("Odada kimse yok"))
          : GridView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: members.length,

        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),

        itemBuilder: (context, index) {

          final user = members[index];

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4B5CFF),
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person),
                ),

                const SizedBox(height: 8),

                Text(
                  user,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )

              ],
            ),
          );
        },
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.headphones),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

          ],
        ),
      ),
    );
  }
}