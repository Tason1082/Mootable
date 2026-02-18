class TopicModel {
  final String key;
  final String name;

  TopicModel({
    required this.key,
    required this.name,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      key: json['key'],
      name: json['name'],
    );
  }
}
