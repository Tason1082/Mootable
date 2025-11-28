import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mootable/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'saved_posts_page.dart';

class RightProfileDrawer extends StatelessWidget {
  final String? profileImageUrl;
  final String? username;
  final String? bio;
  final VoidCallback onUploadProfileImage;
  final VoidCallback refreshProfile;

  const RightProfileDrawer({
    super.key,
    required this.profileImageUrl,
    required this.username,
    required this.bio,
    required this.onUploadProfileImage,
    required this.refreshProfile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profil Fotoğrafı
              GestureDetector(
                onTap: onUploadProfileImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                  profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                  child: profileImageUrl == null ? const Icon(Icons.person, size: 48) : null,
                ),
              ),

              const SizedBox(height: 20),

              // Kullanıcı adı
              Text(
                username ?? loc.username_label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              if (bio != null && bio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ],

              const SizedBox(height: 30),

              // Profili Düzenle
              _cardButton(
                icon: Icons.edit,
                title: loc.editProfile,
                onTap: () async {
                  Navigator.pop(context);
                  Future.microtask(() async {
                    final updated = await Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          userId: Supabase.instance.client.auth.currentUser!.id,
                          initialUsername: username,
                          initialBio: bio,
                        ),
                      ),
                    );
                    if (updated == true) refreshProfile();
                  });
                },
              ),

              // Kaydedilenler
              _cardButton(
                icon: Icons.bookmark,
                title: loc.savedPosts,
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => SavedPostsPage(
                          userId: Supabase.instance.client.auth.currentUser!.id,
                        ),
                      ),
                    );
                  });
                },
              ),

              // Ayarlar
              _cardButton(
                icon: Icons.settings,
                title: loc.settings,
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  });
                },
              ),

              const Spacer(),

              _cardButton(
                icon: Icons.logout,
                title: loc.logout,
                color: Colors.redAccent,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false, // önceki tüm sayfaları stackten temizle
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _cardButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: color ?? Colors.black),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: color ?? Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





