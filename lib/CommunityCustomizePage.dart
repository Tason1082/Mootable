import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'topic_selection_page.dart'; // <-- BUNU KENDİ PATH’İNE GÖRE DÜZENLE

class CommunityCustomizePage extends StatelessWidget {
  const CommunityCustomizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluğunu şekillendir'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TopicSelectionPage(),
                ),
              );
            },
            child: const Text(
              "Sonraki",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Banner ve avatar sayesinde üyelerin ilgisini çekebilir ve "
                  "topluluğunun kültürünü oluşturabilirsin. Bunu daha sonra "
                  "istediğin zaman yapabilirsin.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),

            const Text("Ön izleme",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text("Topluluk Önizleme")),
            ),

            const SizedBox(height: 30),
            const Text("Banner", style: TextStyle(fontSize: 16)),
            const Text("10:3 oranında görüntülenir"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Ekle"),
            ),

            const SizedBox(height: 20),
            const Text("Simge", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
