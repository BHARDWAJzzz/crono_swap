class AppUser {
  final String id;
  final String name;
  final String bio;
  final List<String> interests;
  final List<String> skillIds;
  final int timeBalance; // Total "Crono" units available
  final String role; // 'user', 'moderator', 'superadmin'
  final DateTime? dob;
  final String status; // 'pending', 'approved', 'rejected'

  AppUser({
    required this.id,
    required this.name,
    this.bio = '',
    this.interests = const [],
    required this.skillIds,
    required this.timeBalance,
    this.role = 'user',
    this.dob,
    this.status = 'pending',
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isModerator => role == 'moderator' || role == 'superadmin';
  bool get isApproved => status == 'approved' || isSuperAdmin;
}
