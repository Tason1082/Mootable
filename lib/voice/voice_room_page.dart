import 'package:flutter/material.dart';
import '../../voice/voice_service.dart';
import '../../voice/voice_signalr.dart';
import '../../voice/webrtc_voice_service.dart';

class VoiceRoomPage extends StatefulWidget {

  final int roomId;

  const VoiceRoomPage({super.key, required this.roomId});

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();

}

class _VoiceRoomPageState extends State<VoiceRoomPage> {

  bool loading = true;
  List<String> members = [];

  bool micOn = true;
  bool inCall = false;

  final WebRTCVoiceService webrtc = WebRTCVoiceService();
  final VoiceSignalR signalR = VoiceSignalR();

  @override
  void initState() {
    super.initState();
    loadMembers();
    initVoice();
  }

  Future<void> initVoice() async {

    await webrtc.init();
    await signalR.connect();

    webrtc.onIceCandidate =
        (userId, candidate, mid, index) {

      signalR.sendIce(
        widget.roomId.toString(),
        candidate,
        userId,
        mid,
        index,
      );
    };

    signalR.onOffer = (roomId, offer, userId) async {

      await webrtc.setRemote(userId, offer);

      String answer = await webrtc.createAnswer(userId);

      signalR.sendAnswer(roomId, answer, userId);

    };

    signalR.onAnswer = (roomId, answer, userId) async {

      await webrtc.setRemote(userId, answer);

    };

    signalR.onIce =
        (roomId, candidate, userId, mid, index) {

      webrtc.addIce(userId, candidate, mid, index);

    };

  }

  Future<void> startCall() async {

    await signalR.joinRoom(widget.roomId.toString());

    for (var user in members) {

      String offer = await webrtc.createOffer(user);

      signalR.sendOffer(
        widget.roomId.toString(),
        offer,
        user,
      );

    }

    setState(() {
      inCall = true;
    });

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
  void dispose() {

    webrtc.dispose();
    signalR.disconnect();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Oda ${widget.roomId}"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
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

        padding: const EdgeInsets.symmetric(vertical: 12),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: [

            IconButton(

              iconSize: 36,

              icon: Icon(
                inCall
                    ? Icons.phone_disabled
                    : Icons.phone,
                color: inCall
                    ? Colors.red
                    : Colors.green,
              ),

              onPressed: () {

                if (!inCall) {
                  startCall();
                }

              },

            ),

            IconButton(

              iconSize: 32,

              icon: Icon(
                micOn
                    ? Icons.mic
                    : Icons.mic_off,
                color: micOn
                    ? Colors.black
                    : Colors.red,
              ),

              onPressed: () {

                setState(() {
                  micOn = !micOn;
                });

                webrtc.toggleMic(micOn);

              },

            ),

            IconButton(

              iconSize: 34,

              icon: const Icon(
                Icons.call_end,
                color: Colors.red,
              ),

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