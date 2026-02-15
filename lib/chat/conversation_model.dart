import 'message_model.dart';

class ConversationModel {
  final int id;
  final String? title;
  final List<MessageModel> messages;

  ConversationModel({
    required this.id,
    this.title,
    required this.messages,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((e) => MessageModel.fromJson(e))
          .toList(),
    );
  }
}

