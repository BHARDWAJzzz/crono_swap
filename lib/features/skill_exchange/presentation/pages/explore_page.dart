import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/skill_providers.dart';
import '../widgets/skill_card.dart';

import '../../../../core/widgets/shimmer_loader.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Tech', 'Repair', 'Cooking', 'Music', 'Design', 'Fitness'];

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Explore Skills', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(theme),
          Expanded(
            child: skillsAsync.when(
              data: (skills) {
                final filteredSkills = skills.where((s) {
                  final matchesSearch = s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      s.description.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredSkills.isEmpty) {
                  return const Center(child: Text('No skills found matching your search.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredSkills.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SkillCard(skill: filteredSkills[index]),
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: 3,
                itemBuilder: (e, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: ShimmerLoader(width: double.infinity, height: 120, borderRadius: 20),
                ),
              ),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search for skills...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
