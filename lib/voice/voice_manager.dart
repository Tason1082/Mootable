import 'package:mootable/voice/voice_signalr.dart';
import 'package:mootable/voice/webrtc_voice_service.dart';

class VoiceManager {
  static final VoiceManager _instance = VoiceManager._internal();
  factory VoiceManager() => _instance;

  VoiceManager._internal();

  final WebRTCVoiceService webrtc = WebRTCVoiceService();
  final VoiceSignalR signalR = VoiceSignalR();

  bool initialized = false;
  int? currentRoomId;

  Future<void> init(int roomId) async {
    if (initialized) return;

    currentRoomId = roomId;

    await webrtc.init();
    await signalR.connect();
    await signalR.joinRoom(roomId.toString());

    initialized = true;
  }

  Future<void> leave() async {
    if (!initialized) return;

    await signalR.disconnect();
    await webrtc.dispose();

    initialized = false;
    currentRoomId = null;
  }
}