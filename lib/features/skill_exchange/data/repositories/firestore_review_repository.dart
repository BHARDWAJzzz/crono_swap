import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart';

final reviewRepositoryProvider = Provider((ref) => FirestoreReviewRepository());

class FirestoreReviewRepository {
  final firebase.FirebaseFirestore _firestore = firebase.FirebaseFirestore.instance;

  Stream<List<Review>> getReviewsForUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Review(
                id: doc.id,
                swapId: data['swapId'] ?? '',
                reviewerId: data['reviewerId'] ?? '',
                reviewerName: data['reviewerName'] ?? '',
                reviewerAvatarUrl: data['reviewerAvatarUrl'],
                revieweeId: data['revieweeId'] ?? '',
                rating: (data['rating'] ?? 0).toDouble(),
                comment: data['comment'] ?? '',
                createdAt: (data['createdAt'] as firebase.Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  Future<bool> hasReviewed(String swapId, String reviewerId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('swapId', isEqualTo: swapId)
        .where('reviewerId', isEqualTo: reviewerId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> submitReview({
    required String swapId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatarUrl,
    required String revieweeId,
    required double rating,
    required String comment,
  }) async {
    final batch = _firestore.batch();

    // 1. Create the review
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, {
      'swapId': swapId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatarUrl': reviewerAvatarUrl,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'createdAt': firebase.Timestamp.now(),
    });

    // 2. Update reviewee's aggregate rating atomically
    final userRef = _firestore.collection('users').doc(revieweeId);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};
    final currentTotal = (userData['totalReviews'] ?? 0) as int;
    final currentAvg = (userData['averageRating'] ?? 0).toDouble();

    final newTotal = currentTotal + 1;
    final newAvg = ((currentAvg * currentTotal) + rating) / newTotal;

    batch.update(userRef, {
      'averageRating': double.parse(newAvg.toStringAsFixed(2)),
      'totalReviews': newTotal,
    });

    // 3. Award XP to reviewer for giving a review
    final reviewerRef = _firestore.collection('users').doc(reviewerId);
    batch.update(reviewerRef, {
      'xp': firebase.FieldValue.increment(10),
    });

    await batch.commit();
  }
}
