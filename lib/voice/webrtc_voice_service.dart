import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCVoiceService {

  final Map<String, RTCPeerConnection> peers = {};
  MediaStream? localStream;

  Function(
      String userId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      )? onIceCandidate;

  Function(String userId, MediaStream stream)? onRemoteStream;

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"}
    ]
  };

  Future<void> init() async {

    localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false
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

    return pc;
  }

  Future<String> createOffer(String userId) async {

    RTCPeerConnection pc = await createPeer(userId);

    RTCSessionDescription offer = await pc.createOffer();

    await pc.setLocalDescription(offer);

    return jsonEncode({
      "sdp": offer.sdp,
      "type": offer.type
    });
  }

  Future<String> createAnswer(String userId) async {

    RTCPeerConnection pc = peers[userId]!;

    RTCSessionDescription answer = await pc.createAnswer();

    await pc.setLocalDescription(answer);

    return jsonEncode({
      "sdp": answer.sdp,
      "type": answer.type
    });
  }

  Future<void> setRemote(String userId, String data) async {

    final json = jsonDecode(data);

    RTCPeerConnection pc =
        peers[userId] ?? await createPeer(userId);

    RTCSessionDescription desc =
    RTCSessionDescription(json["sdp"], json["type"]);

    await pc.setRemoteDescription(desc);
  }

  Future<void> addIce(
      String userId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      ) async {

    if (!peers.containsKey(userId)) return;

    RTCPeerConnection pc = peers[userId]!;

    RTCIceCandidate ice =
    RTCIceCandidate(candidate, sdpMid, sdpIndex);

    await pc.addCandidate(ice);
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

    await localStream?.dispose();
  }
}