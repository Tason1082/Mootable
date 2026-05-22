import 'package:flutter/material.dart';
import 'auth_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final birthDateController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String gender = "Male";

  bool loading = false;
  Future<void> register() async {

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifreler eşleşmiyor"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {

      final result = await AuthApi.register(
        username: usernameController.text,
        fullName: fullNameController.text,
        email: emailController.text,
        birthDate: birthDateController.text,
        gender: gender,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      if (!mounted) return;

      // 🔥 başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );

      // ⬇️ kısa bekleme (UI görünsün diye)
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔥 login sayfasına dön
      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  InputDecoration input(String label) {

    return InputDecoration(
      labelText: label,

      filled: true,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 30),

              const Text(
                "Hesap Oluştur",

                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Devam etmek için kayıt ol",

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 40),

              // Kullanıcı adı
              TextField(
                controller: usernameController,
                decoration: input("Kullanıcı Adı"),
              ),

              const SizedBox(height: 16),

              // Ad soyad
              TextField(
                controller: fullNameController,
                decoration: input("Ad Soyad"),
              ),

              const SizedBox(height: 16),

              // Email
              TextField(
                controller: emailController,
                decoration: input("E-posta"),
              ),

              const SizedBox(height: 16),

              // Doğum tarihi
              TextField(
                controller: birthDateController,
                readOnly: true,
                decoration: input("Doğum Tarihi").copyWith(
                  suffixIcon: const Icon(Icons.calendar_today),
                ),

                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );

                  if (pickedDate != null) {
                    final isoDate = pickedDate.toUtc().toIso8601String();
                    birthDateController.text = isoDate;
                  }
                },
              ),

              const SizedBox(height: 16),

              // Cinsiyet
              DropdownButtonFormField<String>(

                value: gender,

                decoration: input("Cinsiyet"),

                items: const [

                  DropdownMenuItem(
                    value: "Male",
                    child: Text("Erkek"),
                  ),

                  DropdownMenuItem(
                    value: "Female",
                    child: Text("Kadın"),
                  ),
                ],

                onChanged: (v) {

                  setState(() {
                    gender = v!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Şifre
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: input("Şifre"),
              ),

              const SizedBox(height: 16),

              // Şifre tekrar
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: input("Şifre Tekrar"),
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,
                height: 55,

                child: ElevatedButton(

                  onPressed: loading ? null : register,

                  style: ElevatedButton.styleFrom(

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text(
                    "Kayıt Ol",
                    style: TextStyle(fontSize: 16),
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