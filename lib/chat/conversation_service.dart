import '../core/api_client.dart';
import 'conversation_list_model.dart';
import 'conversation_model.dart';
import 'message_model.dart';


class ConversationService {

  // LIST
  static Future<List<ConversationListModel>> getAll() async {
    final res = await ApiClient.dio.get("/api/conversations");

    final data = res.data as List;

    return data
        .map((e) => ConversationListModel.fromJson(e))
        .toList();
  }
  static Future<List<MessageModel>> getHistory(
      int conversationId,
      ) async {

    final res = await ApiClient.dio.get(
      "/api/messages/$conversationId",
    );

    final data = res.data as List;

    return data
        .map((e) => MessageModel.fromJson(e))
        .toList();
  }
  // CREATE
  static Future<int> create({
    String? title,
    required List<String> userIds,
  }) async {
    final res = await ApiClient.dio.post(
      "/api/conversations",
      data: {
        "name": title,
        "memberIds": userIds,
      },
    );
    return res.data as int;
  }

  // DETAIL
  static Future<ConversationModel> get(int id) async {
    final res = await ApiClient.dio.get("/api/conversations/$id");

    return ConversationModel.fromJson(res.data);
  }

  // SEND
  // SEND
  static Future<void> sendMessage({
    required int conversationId,
    required String content,
    String? receiverId,
    List<Map<String, dynamic>> medias = const [],
  }) async {

    await ApiClient.dio.post(
      "/api/messages",
      data: {
        "conversationId": conversationId,
        "receiverId": receiverId,
        "content": content,
        "medias": medias,
      },
    );
  }

}
