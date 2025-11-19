import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'topic_selection_page.dart';

class CommunityCustomizePage extends StatelessWidget {
  final String name;
  final String description;

  const CommunityCustomizePage({
    super.key,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.community_customize_title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicSelectionPage(
                    name: name,
                    description: description,
                    bannerUrl: null,
                    iconUrl: null,
                  ),
                ),
              );
            },
            child: Text(
              l10n.next_button,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.preview_text,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.preview_label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  l10n.community_preview_label, // Çok dilli yazı
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30), // <-- Column içinde, Container'dan sonra

            Text(l10n.banner_label, style: const TextStyle(fontSize: 16)),
            Text(l10n.banner_ratio),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: Text(l10n.add_button),
            ),
            const SizedBox(height: 20),
            Text(l10n.icon_label, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: Text(l10n.add_button),
            ),
          ],
        ),
      ),
    );
  }
}
