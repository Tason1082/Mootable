import 'package:flutter/material.dart';
import 'main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDark = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    isDark = brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!; // Çeviri objesi

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings), // Ayarlar / Settings
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // 🌙 Karanlık Mod / Dark Mode
          SwitchListTile(
            title: Text(loc.darkMode),
            subtitle: Text(loc.darkModeSubtitle),
            value: isDark,
            onChanged: (val) {
              setState(() => isDark = val);
              MyApp.setTheme(context, val);
            },
          ),

          const Divider(),

          // 🌍 Dil Ayarları / Language Settings
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(
              locale.languageCode == 'tr'
                  ? "${loc.current}: Türkçe"
                  : "${loc.current}: English",
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.selectLanguage),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Text("🇹🇷"),
                        title: const Text("Türkçe"),
                        onTap: () {
                          MyApp.setLocale(context, const Locale('tr'));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Text("🇬🇧"),
                        title: const Text("English"),
                        onTap: () {
                          MyApp.setLocale(context, const Locale('en'));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(loc.notifications),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Bildirimler eklenecek")),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.about),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Mootable",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Mootable Ekibi",
              );
            },
          ),
        ],
      ),
    );
  }
}


