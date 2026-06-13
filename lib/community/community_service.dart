import 'package:dio/dio.dart';
import 'package:mootable/core/api_client.dart';
import 'package:mootable/core/api_helper.dart';

class CommunityService {
  static Future<void> joinCommunity(String communityId) async {
    final response = await ApiClient.dio.post(
      "/api/communities/$communityId/join",
    );

    ApiHelper.parse(response, null);
  }

  static Future<void> leaveCommunity(String communityId) async {
    final response = await ApiClient.dio.delete(
      "/api/communities/$communityId/leave",
    );

    ApiHelper.parse(response, null);
  }

  static Future<String> createCommunity({
    required String name,
    required String description,
    required List<String> topics,
    required String type,
    required bool isAdult,
  }) async {
    final response = await ApiClient.dio.post(
      "/api/communities",
      data: {
        "name": name,
        "description": description,
        "topics": topics.map((e) => e.toLowerCase()).toList(),
        "type": type,
        "isAdult": isAdult,
      },
    );

    final result = ApiHelper.parse<String>(
      response,
          (json) => json["id"] as String,
    );

    return result.data!;
  }

  static Future<void> uploadImage({
    required String communityId,
    required String filePath,
    required String type,
  }) async {
    final fileName = filePath.split('/').last;

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
      "type": type,
    });

    final response = await ApiClient.dio.post(
      "/api/communities/$communityId/upload-image",
      data: formData,
    );

    ApiHelper.parse(response, null);
  }

  static Future<List<Map<String, dynamic>>> getAllCommunities() async {
    final response = await ApiClient.dio.get(
      "/api/communities",
    );

    final result = ApiHelper.parse<List<Map<String, dynamic>>>(
      response,
          (json) => List<Map<String, dynamic>>.from(json),
    );

    return result.data ?? [];
  }

  static Future<List<Map<String, dynamic>>> getRecommendedCommunities() async {
    final response = await ApiClient.dio.get(
      "/api/communities/recommended",
    );

    final result = ApiHelper.parse<List<Map<String, dynamic>>>(
      response,
          (json) => List<Map<String, dynamic>>.from(json),
    );

    return result.data ?? [];
  }

  static Future<List<Map<String, dynamic>>> getCategories({
    required String locale,
  }) async {
    final response = await ApiClient.dio.get(
      "/api/categories",
      queryParameters: {
        "locale": locale,
      },
    );

    final result = ApiHelper.parse<List<Map<String, dynamic>>>(
      response,
          (json) => List<Map<String, dynamic>>.from(json),
    );

    return result.data ?? [];
  }
}