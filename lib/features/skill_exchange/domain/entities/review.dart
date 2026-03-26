class Review {
  final String id;
  final String swapId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final String revieweeId;
  final double rating; // 1.0 - 5.0
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.swapId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatarUrl,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
