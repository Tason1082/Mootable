import 'package:flutter/material.dart';

class CommunityTypePage extends StatefulWidget {
  final String name;
  final String description;
  final String? bannerUrl;
  final String? iconUrl;
  final List<String> selectedTopics;

  const CommunityTypePage({
    super.key,
    required this.name,
    required this.description,
    this.bannerUrl,
    this.iconUrl,
    required this.selectedTopics,
  });

  @override
  State<CommunityTypePage> createState() => _CommunityTypePageState();
}

class _CommunityTypePageState extends State<CommunityTypePage> {
  String communityType = "public"; // public, restricted, private
  bool isAdult = false;

  void _finish() async {
    // Burada Supabase kaydı yapılacak
    // Şimdi sadece başka sayfa gösterebiliriz
    Navigator.pop(context, {
      "name": widget.name,
      "description": widget.description,
      "banner": widget.bannerUrl,
      "icon": widget.iconUrl,
      "topics": widget.selectedTopics,
      "type": communityType,
      "adult": isAdult,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluk türünü seç"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text("Sonraki", style: TextStyle(fontSize: 16)),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Topluluğunu kimlerin görüntüleyip katkıda bulunabileceğini belirle. "
                  "Sadece açık topluluklar aramalarda görünür.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              "Önemli: Ayarlamalarını yaptıysan topluluk türünü yalnızca Reddit onayıyla değiştirebilirsin.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            _buildRadio(
              "Herkese açık",
              "Herkes arama yapabilir, görüntüleyebilir ve katkıda bulunabilir.",
              "public",
              Icons.add_circle_outline,
            ),

            _buildRadio(
              "Kısıtlanmış",
              "Herkes görüntüleyebilir ancak kimlerin katkıda bulunabileceğini kısıtla.",
              "restricted",
              Icons.remove_red_eye_outlined,
            ),

            _buildRadio(
              "Özel",
              "Sadece onaylı üyeler görüntüleyebilir ve katkıda bulunabilir.",
              "private",
              Icons.lock_outline,
            ),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Yetişkinlere Yönelik (18+) \nGörüntülemek için 18 yaşından büyük olmak gerekir",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Switch(
                  value: isAdult,
                  onChanged: (v) => setState(() => isAdult = v),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(
      String title, String subtitle, String value, IconData icon) {
    return InkWell(
      onTap: () => setState(() => communityType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                      const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Radio(
              value: value,
              groupValue: communityType,
              onChanged: (val) {
                setState(() => communityType = val!);
              },
            )
          ],
        ),
      ),
    );
  }
}
