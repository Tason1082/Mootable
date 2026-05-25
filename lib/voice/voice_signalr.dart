import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../core/auth_service.dart';

class VoiceSignalR {
  late HubConnection connection;

  Function(Map<String, dynamic> invite)? onInvite;

  // CALLBACKS
  Function(
      String roomId,
      String senderId,
      String offer,
      )? onOffer;

  Function(
      String roomId,
      String senderId,
      String answer,
      )? onAnswer;

  Function(
      String roomId,
      String senderId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      )? onIce;

  Function(String userId)? onUserJoined;
  Function(String connectionId)? onPeerJoined;
  Function(String userId)? onUserLeft;
  Function(dynamic roomId)? onRoomDeleted;

  /// CONNECT
  Future<void> connect({
    int retries = 3,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    connection = HubConnectionBuilder()
        .withUrl(
      "http://10.0.2.2:5004/voicehub",
      options: HttpConnectionOptions(
        accessTokenFactory: () async {
          final token = await AuthService.getToken();
          return token ?? "";
        },
      ),
    )
        .withAutomaticReconnect()
        .build();

    // ================= OFFER =================
    connection.on("ReceiveOffer", (args) {
      if (args == null || args.length < 3) return;

      final roomId = args[0].toString();
      final offer = args[1].toString();
      final senderId = args[2].toString();

      onOffer?.call(
        roomId,
        senderId,
        offer,
      );
    });

    // ================= ANSWER =================
    connection.on("ReceiveAnswer", (args) {
      if (args == null || args.length < 3) return;

      final roomId = args[0].toString();
      final answer = args[1].toString();
      final senderId = args[2].toString();

      onAnswer?.call(
        roomId,
        senderId,
        answer,
      );
    });

    // ================= ICE =================
    connection.on("ReceiveIceCandidate", (args) {
      if (args == null || args.length < 5) return;

      final roomId = args[0].toString();
      final candidate = args[1].toString();
      final senderId = args[2].toString();
      final sdpMid = args[3].toString();
      final sdpIndex = args[4] as int;

      onIce?.call(
        roomId,
        senderId,
        candidate,
        sdpMid,
        sdpIndex,
      );
    });

    // ================= INVITE =================
    connection.on("ReceiveInvite", (args) {
      try {
        if (args == null || args.isEmpty) return;

        final raw = args[0];

        if (raw is! Map) return;

        final map = Map<String, dynamic>.from(raw);

        final invite = {
          "id": map["id"] ?? map["Id"],
          "roomId": map["roomId"] ?? map["RoomId"],
          "sender": {
            "id": map["sender"]?["id"] ??
                map["Sender"]?["Id"],
            "userName": map["sender"]?["userName"] ??
                map["sender"]?["username"] ??
                map["Sender"]?["UserName"],
            "profileImage": map["sender"]?["profileImage"] ??
                map["sender"]?["profileImageUrl"] ??
                map["Sender"]?["ProfileImageUrl"],
          }
        };

        if (invite["id"] == null ||
            invite["roomId"] == null) {
          return;
        }

        onInvite?.call(invite);
      } catch (e, s) {
        debugPrint("ReceiveInvite parse error: $e");
        debugPrintStack(stackTrace: s);
      }
    });

    // ================= PEER JOINED =================
    connection.on("PeerJoined", (args) {
      if (args == null || args.isEmpty) return;

      onPeerJoined?.call(args[0].toString());
    });

    // ================= USER JOINED =================
    connection.on("UserJoined", (args) {
      if (args == null || args.isEmpty) return;

      onUserJoined?.call(args[0].toString());
    });

    // ================= USER LEFT =================
    connection.on("UserLeft", (args) {
      if (args == null || args.isEmpty) return;

      onUserLeft?.call(args[0].toString());
    });

    // ================= ROOM DELETED =================
    connection.on("RoomDeleted", (args) {
      if (onRoomDeleted != null) {
        onRoomDeleted!(args![0]);
      }
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

    // ================= START =================
    int attempt = 0;

    while (attempt < retries) {
      attempt++;

      try {
        await connection.start()?.timeout(timeout);

        print("[SignalR] Connected on attempt $attempt");

        return;
      } on TimeoutException catch (_) {
        print(
          "[SignalR] Timeout on attempt $attempt",
        );

        if (attempt == retries) rethrow;
      } catch (e) {
        print("[SignalR] Connection error: $e");

        rethrow;
      }
    }
  }

  /// JOIN ROOM
  Future<void> joinRoom(
      String roomId, {
        Duration timeout = const Duration(seconds: 10),
      }) async {
    await connection
        .invoke(
      "JoinRoom",
      args: [roomId],
    )
        .timeout(timeout);
  }

  /// SEND OFFER
  Future<void> sendOffer(
      String roomId,
      String targetId,
      String offer,
      ) async {
    await connection.invoke(
      "SendOffer",
      args: [roomId, targetId, offer],
    );
  }

  /// SEND ANSWER
  Future<void> sendAnswer(
      String roomId,
      String targetId,
      String answer,
      ) async {
    await connection.invoke(
      "SendAnswer",
      args: [roomId, targetId, answer],
    );
  }

  /// SEND ICE
  Future<void> sendIce(
      String roomId,
      String targetId,
      String candidate,
      String sdpMid,
      int sdpIndex,
      ) async {
    await connection.invoke(
      "SendIceCandidate",
      args: [
        roomId,
        targetId,
        candidate,
        sdpMid,
        sdpIndex,
      ],
    );
  }

  /// DISCONNECT
  Future<void> disconnect() async {
    await connection.stop();
  }
}