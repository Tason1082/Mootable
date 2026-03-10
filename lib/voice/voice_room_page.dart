import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../voice/voice_service.dart';
import '../../voice/voice_signalr.dart';
import '../../voice/webrtc_voice_service.dart';
import '../core/auth_service.dart';

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
  final Map<String, RTCVideoRenderer> _audioRenderers = {};
  final Map<String, RTCVideoRenderer> _renderers = {};

  @override
  void initState() {
    super.initState();
    initAll();
  }

  String normalize(String v) => v.trim().toLowerCase();

  Future<void> initAll() async {
    await initUser();
    await loadMembers();
    await initVoice();
  }

  Future<void> initUser() async {
    myUserId = await AuthService.getUserId();
    print("[DEBUG] MY USER ID -> $myUserId");
  }

  Future<void> loadMembers() async {
    try {
      final data = await VoiceService.getMembers(widget.roomId);
      setState(() {
        members = data;
        loading = false;
      });
    } catch (e) {
      print("[DEBUG] Load members error -> $e");
      setState(() => loading = false);
    }
  }

  Future<void> _initRenderer(String userId, MediaStream stream) async {
    if (stream.getVideoTracks().isNotEmpty) {
      if (!_renderers.containsKey(userId)) {
        RTCVideoRenderer renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _renderers[userId] = renderer;
      }
    }
    for (var track in stream.getAudioTracks()) {
      track.enabled = true;
      print("Audio track aktif edildi -> ${track.id} | user: $userId");
    }

    setState(() {});
  }

  bool _shouldSendOffer(String otherUserId) {
    if (myUserId == null || otherUserId.isEmpty) return false;
    return normalize(myUserId!).compareTo(normalize(otherUserId)) < 0;
  }

  Future<void> initVoice() async {
    logDebug("WebRTC başlatılıyor...");
    await webrtc.init();

    logDebug("SignalR bağlanıyor...");
    await signalR.connect();

    final myId = normalize(myUserId ?? "");

    // Mikrofon durumunu başlat
    webrtc.toggleMic(micOn);
    logDebug("Mic durumu: $micOn");
    webrtc.onAnswerCreated = (userId, sdp) {
      print("ANSWER OLUŞTU -> $userId");
      signalR.sendAnswer(widget.roomId.toString(), sdp);
    };

    /// REMOTE STREAM (sadece audio)
    webrtc.onRemoteStream = (userId, stream) async {
      print("REMOTE STREAM TRACKS: ${stream.getTracks().length}");
      print("AUDIO TRACKS: ${stream.getAudioTracks().length}");

      if (stream.getAudioTracks().isNotEmpty) {
        for (var track in stream.getAudioTracks()) {
          track.enabled = true; // audio çalması için
          print("Audio track aktif edildi -> ${track.id} | user: $userId");
        }
        setState(() {}); // sadece UI güncellemesi için
        print("REMOTE AUDIO BAĞLANDI -> $userId");
      }
    };

    /// LOCAL ICE -> SERVER
    webrtc.onIceCandidate = (userId, candidate, mid, index) {
      userId = normalize(userId);
      logDebug("ICE CANDIDATE -> $userId | mid: $mid | index: $index");

      signalR.sendIce(
        widget.roomId.toString(),
        candidate,
        mid,
        index,
      );
    };

    /// OFFER GELDİ
    signalR.onOffer = (roomId, offer, userId) async {
      userId = normalize(userId);
      if (userId == myId) return;

      logDebug("OFFER GELDİ -> from $userId");

      if (!webrtc.hasPeer(userId)) {
        logDebug("Peer oluşturuluyor -> $userId | polite:true");
        await webrtc.createPeer(userId, polite: true);
      }

      await webrtc.handleOffer(userId, offer);
      logDebug("Offer handle tamamlandı -> $userId");
    };

    /// ANSWER GELDİ
    signalR.onAnswer = (roomId, answer, userId) async {
      userId = normalize(userId);
      if (userId == myId) return;

      logDebug("ANSWER GELDİ -> from $userId");

      await webrtc.handleAnswer(userId, answer);
      logDebug("Answer handle tamamlandı -> $userId");
    };

    /// ICE GELDİ
    signalR.onIce = (roomId, candidate, userId, mid, index) async {
      userId = normalize(userId);
      if (userId == myId) return;

      if (!webrtc.hasPeer(userId)) {
        logDebug("Peer oluşturuluyor ICE için -> $userId");
        await webrtc.createPeer(userId, polite: false);
      }

      await webrtc.addIce(userId, candidate, mid, index);
      logDebug("ICE eklendi -> $userId");
    };

    /// YENİ USER
    signalR.onUserJoined = (connectionId) async {
      final user = normalize(connectionId);

      if (!webrtc.hasPeer(user)) {
        print("Yeni peer oluşturuluyor -> $user");
        await webrtc.createPeer(user, polite: false);

        if (_shouldSendOffer(user)) {
          final offer = await webrtc.createOffer(user);
          signalR.sendOffer(widget.roomId.toString(), offer);
        }
      }
    };

    /// ODAYA KATIL
    logDebug("Odaya katılınıyor -> ${widget.roomId}");
    await signalR.joinRoom(widget.roomId.toString());
    logDebug("Odaya katılım tamamlandı");

    /// MEVCUT USERLAR (sadece offer göndermek için)
    for (var user in members) {
      final otherUser = normalize(user);
      if (otherUser == myId) continue;

      if (_shouldSendOffer(otherUser)) {
        if (!webrtc.hasPeer(otherUser)) {
          logDebug("Peer oluşturuluyor -> $otherUser");
          await webrtc.createPeer(otherUser, polite: false);
        }

        final offer = await webrtc.createOffer(otherUser);
        logDebug("Offer gönderiliyor -> $otherUser");
        signalR.sendOffer(widget.roomId.toString(), offer);
      }
    }
  }

// Helper debug fonksiyonu
  void logDebug(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print("[DEBUG][$timestamp] $message");
  }

  @override
  void dispose() {
    webrtc.dispose();
    signalR.disconnect();

    for (var r in _renderers.values) {
      r.dispose();
    }

    for (var r in _audioRenderers.values) {
      r.dispose();
    }
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
                  childAspectRatio: 1,
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

            /// Görünmez audio renderer
            ..._renderers.values
                .map((r) => SizedBox(
              width: 0,
              height: 0,
              child: RTCVideoView(r),
            )),
            ..._audioRenderers.values.map((r) => SizedBox(
              width: 0,
              height: 0,
              child: RTCVideoView(r),
            )),
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
                    setState(() {
                      micOn = !micOn;
                    });
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