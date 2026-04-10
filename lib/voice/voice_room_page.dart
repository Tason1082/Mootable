import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mootable/voice/voice_manager.dart';
import 'package:mootable/voice/voice_service.dart';

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

  String? myUserId;


  final voiceManager = VoiceManager();
  final Map<String, RTCVideoRenderer> _audioRenderers = {};
  final Map<String, RTCVideoRenderer> _renderers = {};

  @override
  void initState() {
    super.initState();
    initAll();
    VoiceManager().micOn.value = true;
  }

  String normalize(String v) => v.trim().toLowerCase();

  Future<void> initAll() async {
    await initUser();
    await loadMembers();
    if (!voiceManager.initialized) {
      await voiceManager.init(
        roomId: widget.roomId,
        userId: myUserId!,
        initialMembers: members,
      );
    }
  }

  Future<void> initUser() async {
    myUserId = await AuthService.getUserId();
    print("[DEBUG] MY USER ID -> $myUserId");
  }
  Future<void> leaveRoom() async {
    try {
      logDebug("Odadan çıkılıyor...");

      /// 🔥 Önce backend'e bildir
      await VoiceService.leaveRoom(widget.roomId);

      /// 🔌 Sonra bağlantıları kapat
      await voiceManager.leave();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      logDebug("Leave error -> $e");
    }
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



// Helper debug fonksiyonu
  void logDebug(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print("[DEBUG][$timestamp] $message");
  }

  @override
  void dispose() {
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Oda ${widget.roomId}")),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// 👥 USER GRID
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: VoiceManager().members,
                  builder: (context, members, _) {
                    return GridView.builder(
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
                    );
                  },
                ),
              ),

              /// 🔇 INVISIBLE AUDIO RENDERERS
              ..._renderers.values.map((r) => SizedBox(
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

              /// 🎮 CONTROLS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// 🎤 BURAYA KOY
                  ValueListenableBuilder<bool>(
                    valueListenable: VoiceManager().micOn,
                    builder: (_, micOn, __) {
                      return IconButton(
                        iconSize: 32,
                        icon: Icon(
                          micOn ? Icons.mic : Icons.mic_off,
                          color: micOn ? Colors.black : Colors.red,
                        ),
                        onPressed: () {
                          VoiceManager().toggleMic();
                        },
                      );
                    },
                  ),

                  const SizedBox(width: 24),

                  /// 🚪 Ayrıl (aynı kalır)
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    onPressed: () async {
                      await leaveRoom();
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}