import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/skill_exchange/domain/entities/user.dart';

/// Pure Dart scoring engine for AI-powered smart matching.
/// No external API needed — uses multi-factor scoring.
class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scoring weights (total = 1.0)
  static const double weightSkillOverlap = 0.40;
  static const double weightRating = 0.25;
  static const double weightActivity = 0.20;
  static const double weightAvailability = 0.15;

  /// Find top mentor matches for a learner seeking a specific skill or interest.
  Future<List<MatchResult>> findMatches({
    required AppUser learner,
    required String desiredSkill,
    int limit = 20,
  }) async {
    // Fetch approved users who are not the learner
    final snapshot = await _firestore
        .collection('users')
        .where('status', isEqualTo: 'approved')
        .limit(100)
        .get();

    final candidates = <MatchResult>[];

    for (final doc in snapshot.docs) {
      if (doc.id == learner.id) continue;

      final data = doc.data();
      final candidate = AppUser.fromFirestore(data, doc.id);

      final score = _calculateScore(
        learner: learner,
        mentor: candidate,
        desiredSkill: desiredSkill,
      );

      if (score > 0.05) {
        candidates.add(MatchResult(
          user: candidate,
          matchPercentage: (score * 100).round(),
          matchReasons: _getMatchReasons(learner, candidate, desiredSkill),
        ));
      }
    }

    // Sort by match percentage descending
    candidates.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    return candidates.take(limit).toList();
  }

  /// Find recommended matches based on user's skillsWanted.
  Future<List<MatchResult>> findRecommended({
    required AppUser learner,
    int limit = 5,
  }) async {
    if (learner.skillsWanted.isEmpty && learner.interests.isEmpty) {
      return [];
    }

    // Use first skill wanted or interest as the search term
    final searchTerm = learner.skillsWanted.isNotEmpty
        ? learner.skillsWanted.first
        : learner.interests.first;

    return findMatches(
      learner: learner,
      desiredSkill: searchTerm,
      limit: limit,
    );
  }

  double _calculateScore({
    required AppUser learner,
    required AppUser mentor,
    required String desiredSkill,
  }) {
    double score = 0;

    // 1. Skill Overlap Score (40%)
    final skillScore = _skillOverlapScore(learner, mentor, desiredSkill);
    score += skillScore * weightSkillOverlap;

    // 2. Rating Score (25%)
    final ratingScore = _ratingScore(mentor);
    score += ratingScore * weightRating;

    // 3. Activity Score (20%)
    final activityScore = _activityScore(mentor);
    score += activityScore * weightActivity;

    // 4. Availability Score (15%)
    final availScore = _availabilityScore(learner, mentor);
    score += availScore * weightAvailability;

    return score.clamp(0.0, 1.0);
  }

  /// Score based on skill/interest match
  double _skillOverlapScore(AppUser learner, AppUser mentor, String desiredSkill) {
    double score = 0;
    final desired = desiredSkill.toLowerCase();

    // Check if mentor's interests contain the desired skill
    for (final interest in mentor.interests) {
      if (interest.toLowerCase().contains(desired) ||
          desired.contains(interest.toLowerCase())) {
        score += 0.5;
        break;
      }
    }

    // Check if mentor teaches what learner wants
    for (final wantedSkill in learner.skillsWanted) {
      for (final mentorInterest in mentor.interests) {
        if (mentorInterest.toLowerCase().contains(wantedSkill.toLowerCase()) ||
            wantedSkill.toLowerCase().contains(mentorInterest.toLowerCase())) {
          score += 0.3;
          break;
        }
      }
    }

    // Bonus if mentor wants what learner can teach (reciprocal)
    for (final learnerInterest in learner.interests) {
      for (final mentorWanted in mentor.skillsWanted) {
        if (learnerInterest.toLowerCase().contains(mentorWanted.toLowerCase()) ||
            mentorWanted.toLowerCase().contains(learnerInterest.toLowerCase())) {
          score += 0.2; // Reciprocal match bonus
          break;
        }
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Score based on rating and reviews
  double _ratingScore(AppUser mentor) {
    if (mentor.totalReviews == 0) return 0.3; // Neutral for new users
    // Normalize: 5.0 rating = 1.0 score
    final ratingNorm = mentor.averageRating / 5.0;
    // Weight by review count (more reviews = more confidence)
    final reviewWeight = (mentor.totalReviews / 10.0).clamp(0.0, 1.0);
    return ratingNorm * (0.5 + 0.5 * reviewWeight);
  }

  /// Score based on activity level (streak, XP, swaps)
  double _activityScore(AppUser mentor) {
    double score = 0;

    // Streak bonus (up to 0.3)
    score += (mentor.streak / 30.0).clamp(0.0, 0.3);

    // XP level bonus (up to 0.3)
    score += (mentor.level / 10.0).clamp(0.0, 0.3);

    // Swaps completed bonus (up to 0.2)
    score += (mentor.swapsCompleted / 20.0).clamp(0.0, 0.2);

    // Teaching hours bonus (up to 0.2)
    score += (mentor.hoursTeaching / 50.0).clamp(0.0, 0.2);

    return score.clamp(0.0, 1.0);
  }

  /// Score based on availability overlap
  double _availabilityScore(AppUser learner, AppUser mentor) {
    if (learner.availability.isEmpty || mentor.availability.isEmpty) {
      return 0.3; // Neutral if no availability set
    }

    int overlaps = 0;
    for (final learnSlot in learner.availability) {
      for (final mentorSlot in mentor.availability) {
        if (_slotsOverlap(learnSlot, mentorSlot)) {
          overlaps++;
        }
      }
    }

    if (overlaps == 0) return 0.0;
    return (overlaps / learner.availability.length).clamp(0.0, 1.0);
  }

  bool _slotsOverlap(String slot1, String slot2) {
    // Simple day-based overlap check
    // Format: "Mon 10-12" or "Wed 14-16"
    final day1 = slot1.split(' ').first.toLowerCase();
    final day2 = slot2.split(' ').first.toLowerCase();
    return day1 == day2;
  }

  List<String> _getMatchReasons(AppUser learner, AppUser mentor, String desiredSkill) {
    final reasons = <String>[];

    // Skill match
    for (final interest in mentor.interests) {
      if (interest.toLowerCase().contains(desiredSkill.toLowerCase())) {
        reasons.add('Teaches ${interest}');
        break;
      }
    }

    // Reciprocal match
    for (final learnerInterest in learner.interests) {
      for (final mentorWanted in mentor.skillsWanted) {
        if (learnerInterest.toLowerCase().contains(mentorWanted.toLowerCase())) {
          reasons.add('Wants to learn ${learnerInterest} from you');
          break;
        }
      }
      if (reasons.length >= 2) break;
    }

    // Rating
    if (mentor.averageRating >= 4.0 && mentor.totalReviews > 0) {
      reasons.add('${mentor.averageRating.toStringAsFixed(1)}★ rating');
    }

    // Activity
    if (mentor.streak >= 3) {
      reasons.add('${mentor.streak}-day streak 🔥');
    }

    if (reasons.isEmpty) {
      reasons.add('Matching interests');
    }

    return reasons;
  }
}

class MatchResult {
  final AppUser user;
  final int matchPercentage;
  final List<String> matchReasons;

  MatchResult({
    required this.user,
    required this.matchPercentage,
    required this.matchReasons,
  });
}
