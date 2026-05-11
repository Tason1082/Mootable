class MessageModel {
  final int id;
  final int conversationId;
  final String senderId;
  final String? receiverId;

  final String content;

  final int? postId;
  final PostModel? post;

  final DateTime createdAt;

  final List<MessageMediaModel> medias;

  // UI enrichment
  String? senderUsername;
  String? senderProfileImage;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.medias,

    this.receiverId,
    this.postId,
    this.post,

    this.senderUsername,
    this.senderProfileImage,
  });

  factory MessageModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MessageModel(
      id: json["id"] ?? 0,

      conversationId:
      json["conversationId"] ?? 0,

      senderId:
      json["senderId"]?.toString() ?? "",

      receiverId:
      json["receiverId"]?.toString(),

      content: json["content"] ?? "",

      postId: json["postId"],

      post: json["post"] != null
          ? PostModel.fromJson(
        Map<String, dynamic>.from(
          json["post"],
        ),
      )
          : null,

      senderUsername:
      json["senderUsername"],

      senderProfileImage:
      json["senderProfileImage"],

      medias:
      (json["medias"] as List<dynamic>? ??
          [])
          .map(
            (e) =>
            MessageMediaModel.fromJson(
              Map<String, dynamic>.from(
                e,
              ),
            ),
      )
          .toList(),

      createdAt: json["createdAt"] != null
          ? DateTime.parse(
        json["createdAt"],
      )
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
      Map<String, dynamic> json,
      ) {
    return MessageMediaModel(
      url: json["url"] ?? "",
      type: json["type"] ?? "",
    );
  }
}

class PostModel {
  final int id;

  final String userId;
  final String username;

  final String? profileImageUrl;

  final String title;
  final String content;

  final String communityId;

  final DateTime createdAt;

  final int commentCount;

  final List<PostMediaModel> medias;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.content,
    required this.communityId,
    required this.createdAt,
    required this.commentCount,
    required this.medias,

    this.profileImageUrl,
  });

  factory PostModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PostModel(
      id: json["id"] ?? 0,

      userId:
      json["userId"]?.toString() ?? "",

      username:
      json["username"] ?? "",

      profileImageUrl:
      json["profileImageUrl"],

      title: json["title"] ?? "",

      content: json["content"] ?? "",

      communityId:
      json["communityId"]?.toString() ??
          "",

      createdAt: json["createdAt"] != null
          ? DateTime.parse(
        json["createdAt"],
      )
          : DateTime.now(),

      commentCount:
      json["commentCount"] ?? 0,

      medias:
      (json["medias"] as List<dynamic>? ??
          [])
          .map(
            (e) =>
            PostMediaModel.fromJson(
              Map<String, dynamic>.from(
                e,
              ),
            ),
      )
          .toList(),
    );
  }
}

class PostMediaModel {
  final String url;
  final String type;

  PostMediaModel({
    required this.url,
    required this.type,
  });

  factory PostMediaModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PostMediaModel(
      url: json["url"] ?? "",
      type: json["type"] ?? "",
    );
  }
}