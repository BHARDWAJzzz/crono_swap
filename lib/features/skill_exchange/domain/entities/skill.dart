class Skill {
  final String id;
  final String title;
  final String description;
  final String category;
  final String providerId;
  final String providerName;
  final String? providerAvatarUrl;
  final double timeValue; // In "Crono" units or hours

  Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.providerId,
    required this.providerName,
    this.providerAvatarUrl,
    required this.timeValue,
  });
}
