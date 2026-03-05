import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebVoiceService {

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Function(String candidate)? onIceCandidate;

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"}
    ]
  };

  Future<void> init() async {

    /// Mikrofon al
    localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false
    });

    /// Peer oluştur
    peerConnection = await createPeerConnection(configuration);

    /// Local audio ekle
    for (var track in localStream!.getTracks()) {
      peerConnection!.addTrack(track, localStream!);
    }

    /// Remote stream geldiğinde
    peerConnection!.onTrack = (event) {
      remoteStream = event.streams.first;
    };

    /// ICE candidate üretildiğinde
    peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(candidate.candidate!);
      }
    };
  }

  Future<String> createOffer() async {

    RTCSessionDescription offer =
    await peerConnection!.createOffer();

    await peerConnection!.setLocalDescription(offer);

    return offer.sdp!;
  }

  Future<String> createAnswer() async {

    RTCSessionDescription answer =
    await peerConnection!.createAnswer();

    await peerConnection!.setLocalDescription(answer);

    return answer.sdp!;
  }

  Future<void> setRemote(String sdp, String type) async {

    RTCSessionDescription desc =
    RTCSessionDescription(sdp, type);

    await peerConnection!.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(String candidate) async {

    RTCIceCandidate ice =
    RTCIceCandidate(candidate, null, null);

    await peerConnection!.addCandidate(ice);
  }
}