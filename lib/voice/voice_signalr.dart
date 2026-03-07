import 'package:signalr_netcore/signalr_client.dart';

import '../core/auth_service.dart';


class VoiceSignalR {

  late HubConnection connection;

  Function(String roomId, String offer, String userId)? onOffer;
  Function(String roomId, String answer, String userId)? onAnswer;
  Function(String roomId, String candidate, String userId, String sdpMid, int sdpIndex)? onIce;

  Future<void> connect() async {

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

    /// OFFER
    connection.on("ReceiveOffer", (args) {

      if (args == null) return;

      final roomId = args[0] as String;
      final offer = args[1] as String;
      final userId = args[2] as String;

      onOffer?.call(roomId, offer, userId);
    });

    /// ANSWER
    connection.on("ReceiveAnswer", (args) {

      if (args == null) return;

      final roomId = args[0] as String;
      final answer = args[1] as String;
      final userId = args[2] as String;

      onAnswer?.call(roomId, answer, userId);
    });

    /// ICE
    connection.on("ReceiveIceCandidate", (args) {

      if (args == null) return;

      final roomId = args[0] as String;
      final candidate = args[1] as String;
      final userId = args[2] as String;
      final sdpMid = args[3] as String;
      final sdpIndex = args[4] as int;

      onIce?.call(roomId, candidate, userId, sdpMid, sdpIndex);
    });

    /// bağlantıyı başlat
    await connection.start();
  }

  Future joinRoom(String roomId) async {
    await connection.invoke("JoinRoom", args: [roomId]);
  }

  Future sendOffer(String roomId, String offer, String userId) async {
    await connection.invoke("SendOffer", args: [roomId, offer, userId]);
  }

  Future sendAnswer(String roomId, String answer, String userId) async {
    await connection.invoke("SendAnswer", args: [roomId, answer, userId]);
  }

  Future sendIce(
      String roomId,
      String candidate,
      String userId,
      String sdpMid,
      int sdpIndex) async {

    await connection.invoke(
      "SendIceCandidate",
      args: [roomId, candidate, userId, sdpMid, sdpIndex],
    );
  }

  Future disconnect() async {
    await connection.stop();
  }
}