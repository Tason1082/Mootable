import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {

  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final Map<String, dynamic> data = jsonDecode(payload);

    print("JWT PAYLOAD -> $data");

    // Yeni key: WS nameidentifier
    return data["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"]?.toString();
  }
}