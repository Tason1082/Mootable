import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// ==============================================
/// WebRTC Sesli Arama Servisi
/// ==============================================
class WebVoiceService {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"}
    ]
  };

  /// 🔹 WebRTC başlat
  Future<void> init() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false,
    });

    peerConnection = await createPeerConnection(configuration);

    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });
  }

  /// 🔹 Teklif oluştur
  Future<String?> createOffer() async {
    if (peerConnection == null) return null;

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    return offer.sdp;
  }

  /// 🔹 Uzak SDP ayarla
  Future<void> setRemote(String sdp, String type) async {
    if (peerConnection == null) return;

    RTCSessionDescription desc = RTCSessionDescription(sdp, type);
    await peerConnection!.setRemoteDescription(desc);
  }

  /// 🔹 Cevap oluştur
  Future<String?> createAnswer() async {
    if (peerConnection == null) return null;

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    return answer.sdp;
  }
}

/// ==============================================
/// SignalR Sesli Arama Servisi
/// ==============================================
typedef OnOfferCallback = void Function(String userId, String offer);
typedef OnAnswerCallback = void Function(String userId, String answer);
typedef OnIceCallback = void Function(String userId, String candidate);

class VoiceSignalR {
  late HubConnection connection;

  OnOfferCallback? onOffer;
  OnAnswerCallback? onAnswer;
  OnIceCallback? onIce;

  /// 🔹 SignalR bağlantısı başlat
  Future<void> connect(String url) async {
    connection = HubConnectionBuilder().withUrl(url).build();

    // Eventleri tanımla
    connection.on("ReceiveOffer", (args) {
      if (args == null || args.length < 2) return;
      final userId = args[0] as String;
      final offer = args[1] as String;
      onOffer?.call(userId, offer);
    });

    connection.on("ReceiveAnswer", (args) {
      if (args == null || args.length < 2) return;
      final userId = args[0] as String;
      final answer = args[1] as String;
      onAnswer?.call(userId, answer);
    });

    connection.on("ReceiveIceCandidate", (args) {
      if (args == null || args.length < 2) return;
      final userId = args[0] as String;
      final candidate = args[1] as String;
      onIce?.call(userId, candidate);
    });

    await connection.start();
  }

  /// 🔹 Odaya katıl
  Future<void> joinRoom(String roomId) async {
    await connection.invoke("JoinRoom", args: [roomId]);
  }

  /// 🔹 Teklif gönder
  Future<void> sendOffer(String roomId, String offer, String userId) async {
    await connection.invoke("SendOffer", args: [roomId, offer, userId]);
  }

  /// 🔹 Cevap gönder
  Future<void> sendAnswer(String roomId, String answer, String userId) async {
    await connection.invoke("SendAnswer", args: [roomId, answer, userId]);
  }

  /// 🔹 ICE candidate gönder
  Future<void> sendIce(String roomId, String candidate) async {
    await connection.invoke("SendIceCandidate", args: [roomId, candidate]);
  }
}