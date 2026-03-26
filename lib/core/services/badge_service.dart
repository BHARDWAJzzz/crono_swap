import 'package:cloud_firestore/cloud_firestore.dart';

/// Named badge definitions and award logic.
class BadgeService {
  static const Map<String, BadgeInfo> allBadges = {
    'top_mentor': BadgeInfo(
      id: 'top_mentor',
      name: 'Top Mentor',
      icon: '🎓',
      description: 'Completed 5+ skill swaps as a teacher',
      threshold: 5,
    ),
    'fast_learner': BadgeInfo(
      id: 'fast_learner',
      name: 'Fast Learner',
      icon: '⚡',
      description: 'Bought 3+ lectures',
      threshold: 3,
    ),
    'generous': BadgeInfo(
      id: 'generous',
      name: 'Generous',
      icon: '💝',
      description: 'Donated credits to the community',
      threshold: 1,
    ),
    'rising_star': BadgeInfo(
      id: 'rising_star',
      name: 'Rising Star',
      icon: '🌟',
      description: 'Reached Level 5',
      threshold: 5,
    ),
    'trusted': BadgeInfo(
      id: 'trusted',
      name: 'Trusted',
      icon: '✅',
      description: 'Received 5+ positive reviews',
      threshold: 5,
    ),
    'streak_master': BadgeInfo(
      id: 'streak_master',
      name: 'Streak Master',
      icon: '🔥',
      description: 'Maintained a 7-day streak',
      threshold: 7,
    ),
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and award badges based on user stats.
  Future<List<String>> checkAndAwardBadges(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    final currentBadges = List<String>.from(data['badgeIds'] ?? []);
    final newBadges = <String>[];

    // Top Mentor: 5+ swaps
    if (!currentBadges.contains('top_mentor') && (data['swapsCompleted'] ?? 0) >= 5) {
      newBadges.add('top_mentor');
    }

    // Fast Learner: 3+ lectures bought
    final boughtLectures = List.from(data['boughtLectureIds'] ?? []);
    if (!currentBadges.contains('fast_learner') && boughtLectures.length >= 3) {
      newBadges.add('fast_learner');
    }

    // Rising Star: Level 5+
    if (!currentBadges.contains('rising_star') && (data['level'] ?? 1) >= 5) {
      newBadges.add('rising_star');
    }

    // Trusted: 5+ reviews
    if (!currentBadges.contains('trusted') && (data['totalReviews'] ?? 0) >= 5) {
      newBadges.add('trusted');
    }

    // Streak Master: streak >= 7
    if (!currentBadges.contains('streak_master') && (data['streak'] ?? 0) >= 7) {
      newBadges.add('streak_master');
    }

    // Generous: check donations
    if (!currentBadges.contains('generous')) {
      final donations = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .limit(1)
          .get();
      if (donations.docs.isNotEmpty) {
        newBadges.add('generous');
      }
    }

    if (newBadges.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'badgeIds': FieldValue.arrayUnion(newBadges),
      });
    }

    return newBadges;
  }
}

class BadgeInfo {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int threshold;

  const BadgeInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.threshold,
  });
}
