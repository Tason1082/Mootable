import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'topic_data.dart';

class InterestSelectionPage extends StatefulWidget {
  final List<String>? initialSelected;

  const InterestSelectionPage({Key? key, this.initialSelected}) : super(key: key);

  @override
  State<InterestSelectionPage> createState() => _InterestSelectionPageState();
}

class _InterestSelectionPageState extends State<InterestSelectionPage> {
  late Map<String, List<String>> categories;
  final Set<String> selected = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // topic_data.dart'tan lokalizasyon ile kategorileri alıyoruz
    categories = getTopicsData(AppLocalizations.of(context)!);
  }

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

      // Yeni ilgi alanlarını ekle
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.interest_save_error}: $e")),
      );
    }
  }

  Widget _buildCategory(String title, List<String> tags) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title == l10n.category_travel)
                const Icon(Icons.public, size: 20)
              else if (title == l10n.category_qa)
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
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
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
    final l10n = AppLocalizations.of(context)!;
    final bool canContinue = selected.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          title: Text(l10n.interest_selection_title),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.select_at_least_one_topic,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                    ? "${l10n.continue_text} (${selected.length})"
                    : l10n.select_minimum_one_topic,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

