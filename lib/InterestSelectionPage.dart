import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home/home_page.dart';
import 'login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../l10n/category_model.dart';
import '../l10n/category_service.dart';

class InterestSelectionPage extends StatefulWidget {
  final List<String>? initialSelected;

  const InterestSelectionPage({Key? key, this.initialSelected}) : super(key: key);

  @override
  State<InterestSelectionPage> createState() => _InterestSelectionPageState();
}

class _InterestSelectionPageState extends State<InterestSelectionPage> {

  late Future<List<CategoryModel>> _categoriesFuture;
  final CategoryService _categoryService = CategoryService();

  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      selected.addAll(widget.initialSelected!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    _categoriesFuture = _categoryService.getCategories(locale);
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

      await supabase.from('user_interests').delete().eq('user_id', user.id);

      final rows = selected.map((interest) {
        return {
          'user_id': user.id,
          'interest_name': interest,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await supabase.from('user_interests').insert(rows);

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

  Widget _buildCategory(CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.topics.map((topic) {
              final isSelected = selected.contains(topic.name);

              return FilterChip(
                label: Text(topic.name),
                selected: isSelected,
                onSelected: (_) => _toggleSelection(topic.name),
                selectedColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                checkmarkColor:
                Theme.of(context).colorScheme.primary,
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
          title: Text(l10n.interest_selection_title),
        ),
        body: FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Bir hata oluştu"));
            }

            final categories = snapshot.data!;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.select_at_least_one_topic,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...categories.map((category) =>
                      _buildCategory(category)).toList(),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue ? _onContinue : null,
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

