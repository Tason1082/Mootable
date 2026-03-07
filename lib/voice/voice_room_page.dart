import 'package:flutter/material.dart';
import '../../voice/voice_service.dart';
import '../../voice/voice_signalr.dart';
import '../../voice/webrtc_voice_service.dart';
import '../core/auth_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  String? myUserId;

  final WebRTCVoiceService webrtc = WebRTCVoiceService();
  final VoiceSignalR signalR = VoiceSignalR();

  // Stream id -> userId map
  final Map<String, String> _streamUserMap = {};

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    await initUser();
    await loadMembers();
    await initVoice();
  }

  Future<void> initUser() async {
    myUserId = await AuthService.getUserId();
  }

  Future<void> loadMembers() async {
    try {
      final data = await VoiceService.getMembers(widget.roomId);
      setState(() {
        members = data; // Members should be userIds
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> initVoice() async {
    await webrtc.init();
    await signalR.connect();

    // Mikrofonu otomatik aç
    webrtc.toggleMic(micOn);

    /// ICE gönder
    webrtc.onIceCandidate = (userId, candidate, mid, index) {
      signalR.sendIce(widget.roomId.toString(), candidate, userId, mid, index);
    };

    /// Remote stream geldi
    webrtc.onRemoteStream = (String userId, MediaStream stream) {
      print("REMOTE STREAM GELDİ -> $userId");
      print("Remote stream tracks: ${stream.getAudioTracks().length}");
      _streamUserMap[stream.id] = userId;
    };

    /// Offer geldi
    signalR.onOffer = (roomId, offer, userId) async {
      if (userId == myUserId) return;

      print("RECEIVE OFFER FROM -> $userId");

      // Eğer local offer zaten gönderilmediyse, offer’ı set et ve cevap oluştur
      if (!webrtc.hasLocalOffer(userId)) {
        try {
          await webrtc.setRemote(userId, offer);
          String answer = await webrtc.createAnswer(userId);
          signalR.sendAnswer(roomId, answer, userId);
        } catch (e) {
          print("HATA: offer işlemede problem -> $e");
        }
      } else {
        print("Local offer zaten gönderilmiş, gelen offer ignored.");
      }
    };

    /// Answer geldi
    signalR.onAnswer = (roomId, answer, userId) async {
      if (userId == myUserId) return;

      print("ANSWER FROM -> $userId");

      try {
        await webrtc.setRemote(userId, answer); // answer her zaman kabul edilir
      } catch (e) {
        print("HATA: answer set edilemedi -> $e");
      }
    };

    /// ICE geldi
    signalR.onIce = (roomId, candidate, userId, mid, index) {
      if (userId == myUserId) return;
      webrtc.addIce(userId, candidate, mid, index);
    };

    /// Odaya girince otomatik call
    await signalR.joinRoom(widget.roomId.toString());

    for (var user in members) {
      if (user == myUserId) continue;

      try {
        // Offer oluştur
        String offer = await webrtc.createOffer(user);
        print("SEND OFFER -> $user");
        signalR.sendOffer(widget.roomId.toString(), offer, user);
      } catch (e) {
        print("HATA: offer gönderilemedi -> $e");
      }
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
      appBar: AppBar(title: Text("Oda ${widget.roomId}")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
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
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    micOn ? Icons.mic : Icons.mic_off,
                    color: micOn ? Colors.black : Colors.red,
                  ),
                  onPressed: () {
                    setState(() => micOn = !micOn);
                    webrtc.toggleMic(micOn);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}