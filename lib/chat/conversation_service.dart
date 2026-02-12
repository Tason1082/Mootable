import '../core/api_client.dart';
import 'conversation_list_model.dart';
import 'conversation_model.dart';


class ConversationService {

  // LIST
  static Future<List<ConversationListModel>> getAll() async {
    final res = await ApiClient.dio.get("/api/conversations");

    final data = res.data as List;

    return data
        .map((e) => ConversationListModel.fromJson(e))
        .toList();
  }


  // CREATE
  static Future<int> create({
    String? title,
    required List<String> userIds, // user id string olabilir
  }) async {
    final res = await ApiClient.dio.post(
      "/api/conversations",
      data: {
        "title": title,
        "userIds": userIds,
      },
    );

    return res.data as int; // 🔥 int
  }

  // DETAIL
  static Future<ConversationModel> get(int id) async {
    final res = await ApiClient.dio.get("/api/conversations/$id");

    return ConversationModel.fromJson(res.data);
  }

  // SEND
  static Future<void> sendMessage(
      int conversationId,
      String text,
      ) async {
    await ApiClient.dio.post(
      "/api/messages",
      data: {
        "conversationId": conversationId,
        "content": text,
      },
    );
  }
}
