import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'login_page.dart'; // BackButton için import

class InterestSelectionPage extends StatefulWidget {
  final List<String>? initialSelected;
  const InterestSelectionPage({Key? key, this.initialSelected}) : super(key: key);

  @override
  State<InterestSelectionPage> createState() => _InterestSelectionPageState();
}

class _InterestSelectionPageState extends State<InterestSelectionPage> {
  final Map<String, List<String>> categories = {
    "İş Dünyası ve Finans": [
      "Hisse Senetleri ve Yatırım",
      "Bireysel Finans",
      "borsavefon",
      "Fırsatlar ve Pazar Yeri",
      "Emlak",
      "Finanzen",
      "İş Dünyasından Haberler ve Tartışmalar",
      "Kripto",
      "WallStreetBets",
      "Startup ve Girişimcilik",
    ],
    "Eğitim ve Kariyer": [
      "liseliler",
      "Okul ve Eğitim",
      "ODTU",
      "Kariyer",
      "YurtdisiUni",
      "turkishlearning",
      "Teaching",
      "remotework",
      "sysadmin",
      "jobs",
    ],
    "Beşeri Bilimler ve Hukuk": [
      "Kamalizm",
      "Hukuk",
      "TarihiSeyler",
      "Geçmiş",
      "felsefe",
      "Etik ve Felsefe",
      "Legal News & Discussion",
      "Yabancı Dil",
      "Legal advice",
      "Legal advice UK",
    ],
    "Spor": [
      "Futbol",
      "realmadrid",
      "Formula 1",
      "superlig",
      "formula1TR",
      "Motor Sporları",
      "NBA",
      "FenerbahceSK",
      "Basketbol",
      "Güreş ve Dövüş Sporları",
    ],
    "Oyunlar": [
      "Aksiyon Oyunları",
      "EA Sports FC",
      "ClashRoyale",
      "Path of Exile 2",
      "Rol Yapma Oyunları",
      "Cyberpunk 2077",
      "Oyun Haberleri ve Tartışmaları",
      "Genshin Impact",
      "Strateji Oyunları",
      "Macera Oyunları",
    ],
    "İnternet Kültürü": [
      "tamamahbapengelli",
      "SacmaBirSub",
      "bbaldiback",
      "Komik",
      "Meme'ler",
      "İlginç",
      "Cringe ve Facepalm",
      "Reddit Meta",
      "Hayvanlar ve Evcil Hayvanlar",
      "dewrim",
    ],
    "Gezilecek Yerler": [
      "Orta Doğu'daki Yerler",
      "Avrupa'daki Yerler",
      "istanbul",
      "Seyahat ve Tatil",
      "Kuzey Amerika'daki Yerler",
      "Europe",
      "Asya'daki Yerler",
      "Izmir",
      "Travel inspiration",
      "germany",
    ],
    "Soru-Cevap/Öykü": [
      "Soru-Cevap",
      "AskTurkey",
      "Am I the A**hole",
      "Am I Overreacting",
      "No Stupid Questions",
      "Advice",
    ],
  };


  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      selected.addAll(widget.initialSelected!);
    }
  }

  void _toggleSelection(String tag) {
    setState(() {
      if (selected.contains(tag)) {
        selected.remove(tag);
      } else {
        selected.add(tag);
      }
    });
  }

  Future<void> _onContinue() async {
    if (selected.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception("Kullanıcı oturumu bulunamadı");

      // Eski kayıtları sil
      await supabase.from('user_interests').delete().eq('user_id', user.id);

      // Yeni hobileri user_interests tablosuna ekle
      final List<Map<String, dynamic>> rows = selected.map((interest) {
        return {
          'user_id': user.id,
          'interest_name': interest,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await supabase.from('user_interests').insert(rows);

      // HomePage'e yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İlgi alanları kaydedilemedi: $e")),
      );
    }
  }

  Widget _buildCategory(String title, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title == "Gezilecek Yerler")
                const Icon(Icons.public, size: 20)
              else if (title == "Soru-Cevap/Öykü")
                const Icon(Icons.edit, size: 20)
              else
                const Icon(Icons.insert_emoticon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = selected.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) => _toggleSelection(tag),
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = selected.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        // Sistem geri tuşuna basarsa LoginPage'e dön
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return false; // default pop'u engelle
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // BackButton ile LoginPage'e dön
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          title: const Text("İlgi Alanlarını Seç"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "En az 1 konu seçin",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in categories.entries)
                      _buildCategory(entry.key, entry.value),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? null : Colors.grey.shade300,
                foregroundColor: canContinue ? null : Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                canContinue
                    ? "Devam Et (${selected.length})"
                    : "Devam etmek için en az 1 konu seç",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
