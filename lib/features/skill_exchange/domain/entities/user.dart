class AppUser {
  final String id;
  final String name;
  final String bio;
  final List<String> interests;
  final List<String> skillIds;
  final List<String> skillsWanted;
  final int timeBalance;
  final String role;
  final DateTime? dob;
  final String? avatarUrl;
  final String email;
  final String status;
  final List<String> boughtLectureIds;
  final String? certificateUrl;
  final String? resumeUrl;
  final String? linkedinUrl;

  // Reputation
  final double averageRating;
  final int totalReviews;
  final bool isVerifiedProfessional;

  // Gamification
  final int level;
  final int xp;
  final int streak;
  final List<String> badgeIds;

  // Progress Tracking
  final int hoursTeaching;
  final int hoursLearning;
  final int swapsCompleted;
  final int lecturesSold;

  // Availability
  final List<String> availability; // e.g. ['Mon 10-12', 'Wed 14-16']

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio = '',
    this.interests = const [],
    required this.skillIds,
    this.skillsWanted = const [],
    required this.timeBalance,
    this.role = 'user',
    this.dob,
    this.status = 'pending',
    this.boughtLectureIds = const [],
    this.certificateUrl,
    this.resumeUrl,
    this.linkedinUrl,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isVerifiedProfessional = false,
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.badgeIds = const [],
    this.hoursTeaching = 0,
    this.hoursLearning = 0,
    this.swapsCompleted = 0,
    this.lecturesSold = 0,
    this.availability = const [],
  });

  bool get isSuperAdmin => role == 'superadmin' || email.toLowerCase() == 'superadmin@gmail.com';
  bool get isModerator => role == 'moderator' || role == 'superadmin';
  bool get isApproved => status == 'approved' || isSuperAdmin;

  String get levelTitle {
    if (level >= 10) return 'Grandmaster';
    if (level >= 8) return 'Expert';
    if (level >= 6) return 'Advanced';
    if (level >= 4) return 'Intermediate';
    if (level >= 2) return 'Beginner';
    return 'Newcomer';
  }

  int get xpForNextLevel => level * 500;
  double get levelProgress => xp / xpForNextLevel;

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      skillIds: List<String>.from(data['skillIds'] ?? []),
      skillsWanted: List<String>.from(data['skillsWanted'] ?? []),
      timeBalance: (data['timeBalance'] ?? 0).toInt(),
      role: data['role'] ?? 'user',
      dob: data['dob'] != null ? (data['dob'] as dynamic).toDate() : null,
      status: data['status'] ?? 'pending',
      boughtLectureIds: List<String>.from(data['boughtLectureIds'] ?? []),
      certificateUrl: data['certificateUrl'],
      resumeUrl: data['resumeUrl'],
      linkedinUrl: data['linkedinUrl'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: (data['totalReviews'] ?? 0).toInt(),
      isVerifiedProfessional: data['isVerifiedProfessional'] ?? false,
      level: (data['level'] ?? 1).toInt(),
      xp: (data['xp'] ?? 0).toInt(),
      streak: (data['streak'] ?? 0).toInt(),
      badgeIds: List<String>.from(data['badgeIds'] ?? []),
      hoursTeaching: (data['hoursTeaching'] ?? 0).toInt(),
      hoursLearning: (data['hoursLearning'] ?? 0).toInt(),
      swapsCompleted: (data['swapsCompleted'] ?? 0).toInt(),
      lecturesSold: (data['lecturesSold'] ?? 0).toInt(),
      availability: List<String>.from(data['availability'] ?? []),
    );
  }
}
