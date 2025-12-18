import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mootable/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../edit_profile_page.dart';
import '../login_page.dart';
import '../saved_posts_page.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// AVATAR
              GestureDetector(
                onTap: onUploadProfileImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: colors.surfaceVariant,
                  backgroundImage:
                  profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person, size: 48, color: colors.onSurfaceVariant)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              /// USERNAME
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

              /// ACTIONS
              _menuTile(
                context,
                icon: Icons.edit,
                title: loc.editProfile,
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.of(context, rootNavigator: true)
                      .push(
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        userId:
                        Supabase.instance.client.auth.currentUser!.id,
                        initialUsername: username,
                        initialBio: bio,
                      ),
                    ),
                  );
                  if (updated == true) refreshProfile();
                },
              ),

              _menuTile(
                context,
                icon: Icons.bookmark,
                title: loc.savedPosts,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => SavedPostsPage(
                        userId:
                        Supabase.instance.client.auth.currentUser!.id,
                      ),
                    ),
                  );
                },
              ),

              _menuTile(
                context,
                icon: Icons.settings,
                title: loc.settings,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),

              const Spacer(),

              _menuTile(
                context,
                icon: Icons.logout,
                title: loc.logout,
                isDestructive: true,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
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
                Icon(
                  icon,
                  size: 26,
                  color:
                  isDestructive ? colors.error : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? colors.error
                        : colors.onSurfaceVariant,
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




