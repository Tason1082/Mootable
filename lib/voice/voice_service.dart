import 'package:dio/dio.dart';
import 'package:http/http.dart';
import '../core/api_client.dart';
import '../core/api_service.dart';

class VoiceService {

  /// 🎤 Oda oluştur
  static Future<int> createRoom({
    required String name,
    required int maxMembers,
  }) async {
    final response = await ApiClient.dio.post(
      "/api/voice/create-room",
      data: {
        "name": name,
        "maxMembers": maxMembers,
      },
    );

    return response.data;
  }
  static Future<List<dynamic>> getJoinedRooms() async {
    final response = await ApiClient.dio.get(
      "/api/voice/joined-rooms",
    );

    return response.data;
  }
  /// 🗑️ Odayı sil
  static Future<void> deleteRoom(int roomId) async {
    await ApiClient.dio.delete(
      "/api/voice/$roomId",
    );
  }
  /// 🚪 Odadan çık
  static Future<void> leaveRoom(int roomId) async {
    await ApiClient.dio.post(
      "/api/voice/leave/$roomId",
    );
  }
  /// 📋 Kullanıcının odalarını getir
  static Future<List<dynamic>> getMyRooms() async {
    final response =
    await ApiClient.dio.get("/api/voice/my-rooms");

    return response.data;
  }

  /// 🔗 Davet linki oluştur
  static Future<String> createInvite(int roomId) async {
    final response = await ApiClient.dio.post(
      "/api/voice/create-invite/$roomId",
    );

    return response.data;
  }

  /// 🚪 Davet linki ile odaya katıl
  static Future<int> joinByInvite(String code) async {
    final response = await ApiClient.dio.post(
      "/api/voice/join-by-invite/$code",
    );

    return response.data;
  }

  /// 👥 Odaya direkt katıl
  static Future<void> joinRoom(int roomId) async {
    await ApiClient.dio.post(
      "/api/voice/join/$roomId",
    );
  }

  /// 👤 Oda üyelerini getir
  static Future<List<String>> getMembers(int roomId) async {
    final response = await ApiClient.dio.get(
      "/api/voice/$roomId/members",
    );

    return List<String>.from(response.data);
  }


}