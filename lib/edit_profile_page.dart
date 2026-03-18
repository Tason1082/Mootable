import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/auth_service.dart';
import '../core/api_client.dart';
import '../error_handler.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialUsername;
  final String? initialBio;

  const EditProfilePage({
    super.key,
    this.initialUsername,
    this.initialBio,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _saving = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername ?? '');
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _initUserId();
  }

  Future<void> _initUserId() async {
    userId = await AuthService.getUserId();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (userId == null) return;

    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      await ApiClient.dio.put(
        '/api/users/$userId',
        data: {
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profile_saved_success)),
        );
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profile_saved_error)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.edit_profile_title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(l10n.username_label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: l10n.username_hint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.username_empty_error;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(l10n.bio_label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.bio_hint,
                  prefixIcon: const Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(_saving ? l10n.saving_button : l10n.save_button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

