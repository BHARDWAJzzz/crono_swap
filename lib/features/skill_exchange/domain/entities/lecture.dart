enum LectureType { video, document, audio }

class Lecture {
  final String id;
  final String title;
  final String description;
  final String providerId;
  final String providerName;
  final String? previewUrl;
  final String contentUrl; // The actual file (video/PDF)
  final double priceInHours;
  final int durationMinutes;
  final LectureType type;
  final DateTime createdAt;
  final List<String> categories;

  Lecture({
    required this.id,
    required this.title,
    required this.description,
    required this.providerId,
    required this.providerName,
    this.previewUrl,
    required this.contentUrl,
    required this.priceInHours,
    required this.durationMinutes,
    required this.type,
    required this.createdAt,
    required this.categories,
  });
}
