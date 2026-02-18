import 'topic_model.dart';

class CategoryModel {
  final String key;
  final String name;
  final List<TopicModel> topics;

  CategoryModel({
    required this.key,
    required this.name,
    required this.topics,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      key: json['key'],
      name: json['name'],
      topics: (json['topics'] as List)
          .map((e) => TopicModel.fromJson(e))
          .toList(),
    );
  }
}
