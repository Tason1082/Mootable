import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mootable/voice/peer_state.dart';

class WebRTCVoiceService {
  MediaStream? _localStream;

  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, List<RTCIceCandidate>> _iceQueue = {};
  final Map<String, PeerState> _peerStates = {};

  Function(String userId, MediaStream stream)? onRemoteStream;
  Function(String userId, String candidate, String mid, int index)? onIceCandidate;
  Function(String userId, String sdp)? onAnswerCreated; // ⚡ callback eklendi

  Map<String, RTCPeerConnection> get peerConnections => _peers;

  final Map<String, dynamic> _config = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"}
    ]
  };

  /// Local stream ve speakerphone init
  Future<void> init() async {
    await Helper.setSpeakerphoneOn(true);
    _localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false,
    });
  }

  bool hasPeer(String userId) => _peers.containsKey(userId);

  /// Peer oluştur
  Future<RTCPeerConnection> createPeer(String userId, {required bool polite}) async {
    if (hasPeer(userId)) return _peers[userId]!;

    await Helper.setSpeakerphoneOn(true);

    final pc = await createPeerConnection(_config);

    _peers[userId] = pc;
    _peerStates[userId] = PeerState(polite);

    // Local audio stream ekle
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }

    // ICE candidate oluştuğunda
    pc.onIceCandidate = (candidate) {
      if (candidate == null) return;
      onIceCandidate?.call(
        userId,
        candidate.candidate!,
        candidate.sdpMid!,
        candidate.sdpMLineIndex!,
      );
    };

    // Remote audio geldiğinde
    pc.onTrack = (event) {
      if (event.track.kind != "audio") return;
      if (event.streams.isEmpty) return;
      final stream = event.streams.first;
      onRemoteStream?.call(userId, stream);
    };

    // Önceden gelen ICE candidate’lar varsa ekle
    if (_iceQueue.containsKey(userId)) {
      for (var ice in _iceQueue[userId]!) {
        pc.addCandidate(ice);
      }
      _iceQueue.remove(userId);
    }

    return pc;
  }

  /// Offer oluştur
  Future<String> createOffer(String userId) async {
    final pc = _peers[userId]!;
    final state = _peerStates[userId]!;

    state.makingOffer = true;
    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      return offer.sdp!;
    } finally {
      state.makingOffer = false;
    }
  }

  /// Answer oluştur
  Future<String> createAnswer(String userId) async {
    final pc = _peers[userId]!;
    final answer = await pc.createAnswer({"offerToReceiveAudio": true});
    await pc.setLocalDescription(answer);
    return answer.sdp!;
  }

  /// Offer handle
  Future<void> handleOffer(String userId, String sdp) async {
    final pc = _peers[userId]!;
    final state = _peerStates[userId]!;

    final offer = RTCSessionDescription(sdp, "offer");

    final offerCollision =
        state.makingOffer || pc.signalingState != RTCSignalingState.RTCSignalingStateStable;
    state.ignoreOffer = !state.polite && offerCollision;

    if (state.ignoreOffer) return;

    await pc.setRemoteDescription(offer);

    // Answer oluştur ve callback ile SignalR’a gönder
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    onAnswerCreated?.call(userId, answer.sdp!); // ⚡ burada answer gönderilecek
  }

  /// Answer handle
  Future<void> handleAnswer(String userId, String sdp) async {
    final pc = _peers[userId]!;
    final answer = RTCSessionDescription(sdp, "answer");
    await pc.setRemoteDescription(answer);
  }

  /// ICE ekle
  Future<void> addIce(String userId, String candidate, String mid, int index) async {
    final ice = RTCIceCandidate(candidate, mid, index);

    if (!hasPeer(userId)) {
      _iceQueue.putIfAbsent(userId, () => []).add(ice);
      return;
    }

    await _peers[userId]!.addCandidate(ice);
  }

  /// Microphone toggle
  void toggleMic(bool enabled) {
    if (_localStream == null) return;
    for (var track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  /// Dispose
  Future<void> dispose() async {
    for (var pc in _peers.values) {
      await pc.close();
    }
    _peers.clear();

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) track.stop();
      await _localStream!.dispose();
    }
  }
}