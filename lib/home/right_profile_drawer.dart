import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/auth_service.dart';
import '../core/api_client.dart';
import '../edit_profile_page.dart';
import '../saved_posts_page.dart';
import '../settings_page.dart';
import '../core/login_page.dart';
import '../error_handler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RightProfileDrawer extends StatefulWidget {
  final VoidCallback refreshProfile;

  const RightProfileDrawer({
    super.key,
    required this.refreshProfile,
  });

  @override
  State<RightProfileDrawer> createState() => _RightProfileDrawerState();
}

class _RightProfileDrawerState extends State<RightProfileDrawer> {
  String? userId;
  String? username;
  String? bio;
  String? profileImageUrl;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    userId = await AuthService.getUserId();
    if (userId == null) return;

    setState(() => loading = true);

    try {
      final response = await ApiClient.dio.get('/api/users/$userId');
      if (!mounted) return;

      final profile = response.data;
      setState(() {
        username = profile['username'] ?? "Anonim";
        bio = profile['bio'];
        profileImageUrl = profile['profileImageUrl'];
      });
    } catch (e, st) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, stackTrace: st);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    if (userId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final file = File(picked.path);
      final fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final uploadResponse = await ApiClient.dio.post(
        "/api/users/$userId/upload-avatar",
        data: formData,
      );

      setState(() {
        profileImageUrl = uploadResponse.data['profileImageUrl'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil fotoğrafı güncellendi")),
      );
    } catch (e, st) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (loading) return const Center(child: CircularProgressIndicator());

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadProfileImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: colors.surfaceVariant,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person, size: 48, color: colors.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                username ?? loc.username_label,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (bio != null && bio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 30),
              _menuTile(
                context,
                icon: Icons.edit,
                title: loc.editProfile,
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      initialUsername: username,
                      initialBio: bio,
                    ),
                  ));
                  if (updated == true) _fetchUserProfile();
                },
              ),
              _menuTile(
                context,
                icon: Icons.bookmark,
                title: loc.savedPosts,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(builder: (_) => SavedPostsPage()));
                },
              ),
              _menuTile(
                context,
                icon: Icons.settings,
                title: loc.settings,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              const Spacer(),
              _menuTile(
                context,
                icon: Icons.logout,
                title: loc.logout,
                isDestructive: true,
                onTap: () async {
                  await AuthService.logout();
                  Navigator.of(context, rootNavigator: true)
                      .pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 26, color: isDestructive ? colors.error : colors.onSurfaceVariant),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



