import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';
import '../core/auth_service.dart';

class VoiceSignalR {
  late HubConnection connection;

  // Callbacks
  Function(String roomId, String offer, String userId)? onOffer;
  Function(String roomId, String answer, String userId)? onAnswer;
  Function(String roomId, String candidate, String userId, String sdpMid, int sdpIndex)? onIce;
  Function(String connectionId)? onUserJoined;

  /// Bağlantıyı başlat (retry + timeout destekli)
  Future<void> connect({int retries = 3, Duration timeout = const Duration(seconds: 10)}) async {
    connection = HubConnectionBuilder()
        .withUrl(
      "http://192.168.1.156:5004/voicehub",
      options: HttpConnectionOptions(
        accessTokenFactory: () async {
          final token = await AuthService.getToken();
          return token ?? "";
        },
      ),
    )
        .withAutomaticReconnect()
        .build();

    // SignalR eventleri
    connection.on("ReceiveOffer", (args) {
      if (args == null || args.length < 3) return;
      onOffer?.call(args[0].toString(), args[1].toString(), args[2].toString());
    });

    connection.on("ReceiveAnswer", (args) {
      if (args == null || args.length < 3) return;
      onAnswer?.call(args[0].toString(), args[1].toString(), args[2].toString());
    });

    connection.on("ReceiveIceCandidate", (args) {
      if (args == null || args.length < 5) return;
      onIce?.call(
        args[0].toString(),
        args[1].toString(),
        args[2].toString(),
        args[3].toString(),
        args[4] as int,
      );
    });

    connection.on("UserJoined", (args) {
      if (args == null || args.isEmpty) return;
      onUserJoined?.call(args[0].toString());
    });

    connection.onreconnecting(({Exception? error}) {
      print("[SignalR] Reconnecting -> $error");
    });

    connection.onreconnected(({String? connectionId}) {
      print("[SignalR] Reconnected -> $connectionId");
    });

    connection.onclose(({Exception? error}) {
      print("[SignalR] Connection closed -> $error");
    });

    // Retry ve timeout ile bağlantı başlat
    int attempt = 0;
    while (attempt < retries) {
      attempt++;
      try {
        await connection.start()?.timeout(timeout);
        print("[SignalR] Connected on attempt $attempt");
        return;
      } on TimeoutException catch (_) {
        print("[SignalR] Timeout on attempt $attempt, retrying...");
        if (attempt == retries) rethrow;
      } catch (e) {
        print("[SignalR] Connection error: $e");
        rethrow;
      }
    }
  }

  /// Odaya katıl (timeout destekli)
  Future<void> joinRoom(String roomId, {Duration timeout = const Duration(seconds: 10)}) async {
    await connection.invoke("JoinRoom", args: [roomId]).timeout(timeout);
  }

  /// Offer gönder
  Future<void> sendOffer(String roomId, String offer, {Duration timeout = const Duration(seconds: 10)}) async {
    await connection.invoke("SendOffer", args: [roomId, offer]).timeout(timeout);
  }

  /// Answer gönder
  Future<void> sendAnswer(String roomId, String answer, {Duration timeout = const Duration(seconds: 10)}) async {
    await connection.invoke("SendAnswer", args: [roomId, answer]).timeout(timeout);
  }

  /// ICE gönder
  Future<void> sendIce(String roomId, String candidate, String sdpMid, int sdpIndex,
      {Duration timeout = const Duration(seconds: 10)}) async {
    await connection.invoke("SendIceCandidate", args: [roomId, candidate, sdpMid, sdpIndex])
        .timeout(timeout);
  }

  /// Bağlantıyı kapat
  Future<void> disconnect() async {
    await connection.stop();
  }
}