class MessageModel {
  final int id;
  final int conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;


  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json["id"] ?? 0,
      conversationId: json["conversationId"] ?? 0,
      senderId: json["senderId"]?.toString() ?? "",
      content: json["content"] ?? "",
      mediaUrl: json["mediaUrl"],
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
    );
  }
}
