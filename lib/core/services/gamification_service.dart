import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

/// Centralized XP + Level + Streak engine. All XP rewards are configurable via app_config.
class GamificationService {
  final firebase.FirebaseFirestore _firestore = firebase.FirebaseFirestore.instance;

  // Default XP values (overridden by app_config if available)
  static const int defaultXpPerSwap = 50;
  static const int defaultXpPerReview = 10;
  static const int defaultXpPerLecture = 30;
  static const int defaultStreakBonus = 20;
  static const int defaultXpPerQuest = 40;

  /// Pure logic: Calculate the update map given current user data and added XP.
  /// This can be used inside other transactions where you've already fetched the user doc.
  Map<String, dynamic> computeUpdateMap({
    required Map<String, dynamic> userData,
    required int addedXp,
  }) {
    final currentXP = (userData['xp'] ?? 0) as int;
    
    final newXP = currentXP + addedXp;
    final newLevel = _calculateLevel(newXP);

    final badges = List<String>.from(userData['badgeIds'] ?? []);
    
    final swapsCompleted = (userData['swapsCompleted'] ?? 0) as int;
    final hoursTeaching = (userData['hoursTeaching'] ?? 0) as int;
    final streak = (userData['streak'] ?? 0) as int;

    if (swapsCompleted > 0 && !badges.contains('first_swap')) {
      badges.add('first_swap');
    }
    if (hoursTeaching >= 10 && !badges.contains('teacher_novice')) {
      badges.add('teacher_novice');
    }
    if (streak >= 7 && !badges.contains('week_streak')) {
      badges.add('week_streak');
    }
    if (newLevel >= 5 && !badges.contains('rising_star')) {
      badges.add('rising_star');
    }

    return {
      'xp': newXP,
      'level': newLevel,
      'badgeIds': badges,
    };
  }

  /// Check and update streak for a user based on lastActiveDate.
  /// Returns a map of updates to merge into a transaction.
  Map<String, dynamic> computeStreakUpdate({
    required Map<String, dynamic> userData,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastActiveDateRaw = userData['lastActiveDate'];
    DateTime? lastActiveDate;
    if (lastActiveDateRaw is firebase.Timestamp) {
      lastActiveDate = lastActiveDateRaw.toDate();
    }

    final currentStreak = (userData['streak'] ?? 0) as int;
    final hasShield = userData['hasStreakShield'] ?? false;

    int newStreak = currentStreak;
    bool newShieldStatus = hasShield;

    if (lastActiveDate != null) {
      final lastActiveDay = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
      final daysDiff = today.difference(lastActiveDay).inDays;

      if (daysDiff == 0) {
        // Already active today — no change
        return {
          'lastActiveDate': firebase.Timestamp.fromDate(now),
        };
      } else if (daysDiff == 1) {
        // Consecutive day — increment streak
        newStreak = currentStreak + 1;
      } else if (daysDiff == 2 && hasShield) {
        // Missed one day but has shield — consume shield, keep streak
        newShieldStatus = false;
        newStreak = currentStreak + 1;
      } else {
        // Missed too many days — reset
        newStreak = 1;
        newShieldStatus = false;
      }
    } else {
      // First activity ever
      newStreak = 1;
    }

    // Award streak bonus XP
    int streakBonusXp = 0;
    if (newStreak > currentStreak) {
      streakBonusXp = defaultStreakBonus;
      // Milestone bonuses
      if (newStreak == 7) streakBonusXp += 50;   // Week streak bonus
      if (newStreak == 30) streakBonusXp += 200;  // Month streak bonus
    }

    final updates = <String, dynamic>{
      'streak': newStreak,
      'lastActiveDate': firebase.Timestamp.fromDate(now),
      'hasStreakShield': newShieldStatus,
    };

    // Merge XP update if there's a streak bonus
    if (streakBonusXp > 0) {
      final xpUpdates = computeUpdateMap(
        userData: {...userData, 'streak': newStreak},
        addedXp: streakBonusXp,
      );
      updates.addAll(xpUpdates);
    }

    return updates;
  }

  /// Award XP to a user and recalculate their level and badges.
  Future<void> awardXP(String userId, int amount, {firebase.Transaction? transaction}) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    Future<void> updateLogic(firebase.Transaction tx) async {
      final snapshot = await tx.get(userRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      final updates = computeUpdateMap(userData: data, addedXp: amount);
      tx.update(userRef, updates);
    }

    if (transaction != null) {
      await updateLogic(transaction);
    } else {
      await _firestore.runTransaction(updateLogic);
    }
  }

  // Award XP for completing a swap (to both participants).
  Future<void> onSwapCompleted(String userId1, String userId2, {int? xpOverride, firebase.Transaction? transaction}) async {
    final xp = xpOverride ?? defaultXpPerSwap;
    if (transaction != null) {
      await awardXP(userId1, xp, transaction: transaction);
      await awardXP(userId2, xp, transaction: transaction);
    } else {
      await Future.wait([
        awardXP(userId1, xp),
        awardXP(userId2, xp),
      ]);
    }
  }

  /// Award XP for selling a lecture.
  Future<void> onLectureSold(String sellerId, {int? xpOverride, firebase.Transaction? transaction}) async {
    final xp = xpOverride ?? defaultXpPerLecture;
    await awardXP(sellerId, xp, transaction: transaction);
  }

  /// Award XP for completing a quest.
  Future<void> onQuestCompleted(String userId, {int? xpOverride, firebase.Transaction? transaction}) async {
    final xp = xpOverride ?? defaultXpPerQuest;
    await awardXP(userId, xp, transaction: transaction);
  }

  /// Increment streak for a user (called daily or weekly).
  Future<void> incrementStreak(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'streak': firebase.FieldValue.increment(1),
      'xp': firebase.FieldValue.increment(defaultStreakBonus),
    });
    await awardXP(userId, 0);
  }

  /// Reset streak if user missed a week.
  Future<void> resetStreak(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'streak': 0,
    });
  }

  /// Award a badge to a user.
  Future<void> awardBadge(String userId, String badgeId) async {
    await _firestore.collection('users').doc(userId).update({
      'badgeIds': firebase.FieldValue.arrayUnion([badgeId]),
    });
  }

  /// Grant a streak shield to a user.
  Future<void> grantStreakShield(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'hasStreakShield': true,
    });
  }

  /// Calculate level from total XP. Each level requires level * 500 XP.
  int _calculateLevel(int totalXP) {
    int level = 1;
    int xpRequired = 500;
    int accumulated = 0;

    while (accumulated + xpRequired <= totalXP) {
      accumulated += xpRequired;
      level++;
      xpRequired = level * 500;
    }

    return level;
  }
}
