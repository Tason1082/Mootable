import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    // 1 saniyelik bekleme (animasyon etkisi için opsiyonel)
    await Future.delayed(const Duration(seconds: 1));

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Eğer kullanıcı zaten giriş yaptıysa direkt HomePage'e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Giriş yapmamışsa LoginPage'e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Basit yükleniyor animasyonu
      ),
    );
  }
}