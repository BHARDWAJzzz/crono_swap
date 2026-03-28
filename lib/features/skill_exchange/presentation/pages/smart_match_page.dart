import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/matching_service.dart';
import '../providers/auth_providers.dart';
import 'profile_page.dart';
import '../../domain/entities/skill.dart';
import '../widgets/exchange_bottom_sheet.dart';

class SmartMatchPage extends ConsumerStatefulWidget {
  const SmartMatchPage({super.key});

  @override
  ConsumerState<SmartMatchPage> createState() => _SmartMatchPageState();
}

class _SmartMatchPageState extends ConsumerState<SmartMatchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<MatchResult>? _results;
  bool _isLoading = false;
  String _searchedSkill = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Smart Match', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'AI-Powered Matching',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell us what you want to learn — we\'ll find the best mentors based on skills, rating, activity, and availability.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _runMatch(),
                        decoration: InputDecoration(
                          hintText: 'e.g., Flutter, Design, Guitar...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _runMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_rounded, size: 20),
                    ),
                  ],
                ),
                // Quick tags from user's skillsWanted
                if (user != null && user.skillsWanted.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: user.skillsWanted.map((skill) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(skill, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            _searchController.text = skill;
                            _runMatch();
                          },
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results
          if (_results != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'MATCHES FOR "$_searchedSkill"',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2),
                  ),
                  const Spacer(),
                  Text(
                    '${_results!.length} found',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: _results == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text(
                          'Search for a skill to find matches',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : _results!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text('No matches found for "$_searchedSkill"', style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _results!.length,
                        itemBuilder: (context, index) => _buildMatchCard(_results![index], index),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchResult match, int index) {
    final theme = Theme.of(context);
    final mentor = match.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: index == 0 ? theme.colorScheme.secondary.withOpacity(0.3) : Colors.grey.shade100,
          width: index == 0 ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: mentor.id))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: mentor.avatarUrl != null ? NetworkImage(mentor.avatarUrl!) : null,
                        child: mentor.avatarUrl == null
                            ? Text(mentor.name.isNotEmpty ? mentor.name[0] : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))
                            : null,
                      ),
                      if (index == 0)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(mentor.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (mentor.isVerifiedProfessional) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded, size: 16, color: Colors.blue.shade400),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${mentor.level} • ${mentor.levelTitle}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Match percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getMatchColor(match.matchPercentage),
                          _getMatchColor(match.matchPercentage).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${match.matchPercentage}%',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Match reasons
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.matchReasons.map((reason) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(reason, style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildMiniStat(Icons.star_rounded, Colors.amber.shade600, mentor.averageRating > 0 ? mentor.averageRating.toStringAsFixed(1) : 'N/A'),
                  const SizedBox(width: 16),
                  _buildMiniStat(Icons.swap_horiz_rounded, Colors.blue, '${mentor.swapsCompleted}'),
                  const SizedBox(width: 16),
                  _buildMiniStat(Icons.local_fire_department_rounded, Colors.orange, '${mentor.streak}'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to exchange bottom sheet or skill detail
                      // Create a temporary skill for the exchange bottom sheet
                      final skill = Skill(
                        id: 'smart_match_${mentor.id}',
                        title: _searchedSkill,
                        description: 'Matched via Smart Match for $_searchedSkill',
                        category: 'Smart Match',
                        providerId: mentor.id,
                        providerName: mentor.name,
                        providerAvatarUrl: mentor.avatarUrl,
                        timeValue: 1, // Default to 1 unit
                      );
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ExchangeBottomSheet(skill: skill),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Request', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 70) return Colors.green.shade600;
    if (percentage >= 40) return Colors.orange.shade600;
    return Colors.grey.shade500;
  }

  void _runMatch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final user = ref.read(userDataProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _searchedSkill = query;
    });

    try {
      final service = MatchingService();
      final results = await service.findMatches(learner: user, desiredSkill: query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
