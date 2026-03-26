import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/skill_providers.dart';
import '../widgets/skill_card.dart';
import '../../domain/entities/skill.dart';
import 'skill_detail_page.dart';
import '../providers/auth_providers.dart';

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
          _buildFeaturedCarousel(skillsAsync),
          _buildSearchAndFilter(theme),
          Expanded(
            child: skillsAsync.when(
              data: (skills) {
                final featuredSkills = skills.take(3).toList();
                final remainingSkills = skills.skip(3).where((s) {
                  final matchesSearch = s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      s.description.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (remainingSkills.isEmpty && featuredSkills.isEmpty) {
                  return const Center(child: Text('No skills found matching your search.'));
                }

                // Smart matching: filter by user interests
                final userData = ref.watch(userDataProvider).value;
                final userInterests = userData?.interests ?? [];
                final recommendedSkills = skills.where((s) => 
                  userInterests.any((interest) => 
                    s.category.toLowerCase().contains(interest.toLowerCase()) ||
                    s.title.toLowerCase().contains(interest.toLowerCase())
                  ) && s.providerId != (userData?.id ?? '')
                ).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: remainingSkills.length + (recommendedSkills.isNotEmpty ? 2 : 1),
                  itemBuilder: (context, index) {
                    if (index == 0 && recommendedSkills.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.amber.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Recommended For You',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...recommendedSkills.take(3).map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SkillCard(skill: s),
                          )),
                          const SizedBox(height: 8),
                        ],
                      );
                    }
                    final adjustedIndex = recommendedSkills.isNotEmpty ? index - 1 : index;
                    if (adjustedIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Text(
                          _searchQuery.isEmpty ? 'All Skills' : 'Search Results',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      );
                    }
                    final skillIndex = adjustedIndex - 1;
                    if (skillIndex >= remainingSkills.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SkillCard(skill: remainingSkills[skillIndex]),
                    );
                  },
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

  Widget _buildFeaturedCarousel(AsyncValue<List<Skill>> skillsAsync) {
    return skillsAsync.when(
      data: (skills) {
        if (skills.isEmpty) return const SizedBox.shrink();
        final featured = skills.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Featured Skills',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: featured.length,
                itemBuilder: (context, index) {
                  final skill = featured[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => SkillDetailPage(skill: skill)),
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                skill.category,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              skill.title,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                               'By ${skill.providerName}',
                               style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 180),
      error: (e, s) => const SizedBox.shrink(),
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
