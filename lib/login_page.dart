import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';
import 'error_handler.dart';
import 'InterestSelectionPage.dart';
import 'home/home_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;

      if (user != null) {
        final supabase = Supabase.instance.client;

        final existingInterests = await supabase
            .from('user_interests')
            .select()
            .eq('user_id', user.id);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => existingInterests.isNotEmpty
                ? const HomePage()
                : const InterestSelectionPage(),
          ),
        );
      } else {
        ErrorHandler.showError(context, l10n.login_failed);
      }
    } catch (e) {
      ErrorHandler.showError(context, e);
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
              Image.asset(
                'assets/logoTansparent.png',
                height: 100,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.login_email_label,
                ),
                keyboardType: TextInputType.emailAddress,
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
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
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
