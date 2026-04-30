import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static HubConnection? _connection;

  static Future<void> connect(String token) async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.Connected) {
      return;
    }

    _connection = HubConnectionBuilder()

        .withUrl(
      "http://10.0.2.2:5004/hubs/chat",
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
      ),
    )
        .withAutomaticReconnect()
        .build();


    await _connection!.start();
  }

  static Future<void> joinConversation(int conversationId) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke(
        "JoinConversation",
        args: [conversationId],
      );
    }
  }

  static Future<void> sendMessage(
      int conversationId, String content) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke(
        "SendMessage",
        args: [conversationId, content],
      );
    }
  }

  static void onMessage(void Function(List<Object?>?) handler) {
    _connection?.off("ReceiveMessage"); // 🔥 önce eski handler sil
    _connection?.on("ReceiveMessage", handler);
  }

  static Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}

