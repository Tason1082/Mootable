import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mootable/core/register_page.dart';

import 'api_client.dart';
import 'api_config.dart';

import '../error/error_handler.dart';
import '../home/home_page.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _storage = const FlutterSecureStorage();

  Future<void> _login() async {
    try {
      ApiClient.allowSelfSignedCerts();

      final response = await ApiClient.dio.post(
        '/api/auth/login',
        data: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      if (!mounted) return;

      final data = response.data;

      // 🔥 WRAPPER KONTROL (posts ile aynı)
      if (data["success"] != true) {
        throw Exception(data["message"]);
      }

      // 🔥 TOKEN ARTIK data["data"] İÇİNDE
      final token = data["data"]["token"];

      await _storage.write(key: "token", value: token);

      final decoded = JwtDecoder.decode(token);
      final userId = decoded[
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
      ];

      await _storage.write(key: "userId", value: userId.toString());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );

    } catch (e, st) {
      ErrorHandler.showError(context, e, stackTrace: st);
    }
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logoTansparent.png', height: 100),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.login_email_label,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.login_password_label,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _login,
                  child: Text(l10n.login_button),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Text(
                  l10n.signup_link,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
