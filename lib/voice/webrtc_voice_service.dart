import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCVoiceService {
  final Map<String, RTCPeerConnection> peers = {};
  MediaStream? localStream;

  final Map<String, List<RTCIceCandidate>> pendingIce = {};
  final Map<String, bool> localOfferSent = {}; // ✅ local offer durumu

  Function(
      String userId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      )? onIceCandidate;

  Function(String userId, MediaStream stream)? onRemoteStream;

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"},
      {
        "urls": "turn:TURN_SERVER_IP:3478",
        "username": "user",
        "credential": "pass"
      }
    ]
  };

  /// local offer gönderilip gönderilmediğini kontrol eder
  bool hasLocalOffer(String userId) => localOfferSent[userId] ?? false;

  Future<void> init() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false,
    });
  }

  Future<RTCPeerConnection> createPeer(String userId) async {
    if (peers.containsKey(userId)) {
      return peers[userId]!;
    }

    RTCPeerConnection pc = await createPeerConnection(configuration);

    for (var track in localStream!.getTracks()) {
      pc.addTrack(track, localStream!);
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(userId, event.streams.first);
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(
          userId,
          candidate.candidate!,
          candidate.sdpMid ?? "",
          candidate.sdpMLineIndex ?? 0,
        );
      }
    };

    peers[userId] = pc;

    /// Eğer ICE candidate peer oluşmadan geldiyse ekle
    if (pendingIce.containsKey(userId)) {
      for (var ice in pendingIce[userId]!) {
        pc.addCandidate(ice);
      }
      pendingIce.remove(userId);
    }

    return pc;
  }

  Future<String> createOffer(String userId) async {
    RTCPeerConnection pc = await createPeer(userId);

    RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    localOfferSent[userId] = true; // ✅ Offer gönderildi işaretle

    return jsonEncode({
      "sdp": offer.sdp,
      "type": offer.type,
    });
  }

  Future<String> createAnswer(String userId) async {
    RTCPeerConnection pc = peers[userId]!;

    RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    return jsonEncode({
      "sdp": answer.sdp,
      "type": answer.type,
    });
  }

  Future<void> setRemote(String userId, String data) async {
    final json = jsonDecode(data);

    RTCPeerConnection pc = peers[userId] ?? await createPeer(userId);

    RTCSessionDescription desc =
    RTCSessionDescription(json["sdp"], json["type"]);

    // Eğer local offer zaten gönderildiyse ve remote offer gelirse ignore et
    if (desc.type == "offer" && hasLocalOffer(userId)) {
      print("Local offer var, gelen remote offer ignored -> $userId");
      return;
    }

    await pc.setRemoteDescription(desc);
  }

  Future<void> addIce(
      String userId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      ) async {
    RTCIceCandidate ice = RTCIceCandidate(candidate, sdpMid, sdpIndex);

    if (!peers.containsKey(userId)) {
      pendingIce.putIfAbsent(userId, () => []);
      pendingIce[userId]!.add(ice);
      return;
    }

    await peers[userId]!.addCandidate(ice);
  }

  void toggleMic(bool enabled) {
    for (var track in localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> dispose() async {
    for (var pc in peers.values) {
      await pc.close();
    }

    peers.clear();
    localOfferSent.clear();

    for (var track in localStream?.getTracks() ?? []) {
      await track.stop();
    }

    await localStream?.dispose();
  }
}