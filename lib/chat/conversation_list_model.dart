class ConversationListModel {
  final int id;
  final String name; // userId
  String? username;
  String? profileImageUrl; // 🔥 EKLENDİ

  final bool isGroup;
  final String lastMessage;
  final DateTime? lastMessageAt;

  ConversationListModel({
    required this.id,
    required this.name,
    this.username,
    this.profileImageUrl,
    required this.isGroup,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory ConversationListModel.fromJson(Map<String, dynamic> json) {
    return ConversationListModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      isGroup: json["isGroup"] ?? false,
      lastMessage: json["lastMessage"] ?? "",
      lastMessageAt: json["lastMessageAt"] != null
          ? DateTime.parse(json["lastMessageAt"])
          : null,
    );
  }
}
