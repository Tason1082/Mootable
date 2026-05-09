class MessageModel {
  final int id;
  final int conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final List<MessageMediaModel> medias;
  // 🔥 UI enrichment alanları
  String? senderUsername;
  String? senderProfileImage;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    required this.medias,
    this.senderUsername,
    this.senderProfileImage,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json["id"] ?? 0,
      conversationId: json["conversationId"] ?? 0,
      senderId: json["senderId"]?.toString() ?? "",
      content: json["content"] ?? "",
      medias: (json["medias"] as List<dynamic>? ?? [])
          .map(
            (e) => MessageMediaModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
    );
  }
}
class MessageMediaModel {
  final String url;
  final String type;

  MessageMediaModel({
    required this.url,
    required this.type,
  });

  factory MessageMediaModel.fromJson(
      Map<String, dynamic> json) {
    return MessageMediaModel(
      url: json["url"],
      type: json["type"],
    );
  }
}