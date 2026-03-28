import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart';
import '../../../../core/services/gamification_service.dart';

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
    List<String> endorsedSkills = const [],
  }) async {
    return _firestore.runTransaction((transaction) async {
      // 1. Create the review
      final reviewRef = _firestore.collection('reviews').doc();
      transaction.set(reviewRef, {
        'swapId': swapId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerAvatarUrl': reviewerAvatarUrl,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'endorsedSkills': endorsedSkills,
        'createdAt': firebase.Timestamp.now(),
      });

      // 2. Update reviewee's aggregate rating and endorsements atomically
      final userRef = _firestore.collection('users').doc(revieweeId);
      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data() ?? {};
      
      final currentTotal = (userData['totalReviews'] ?? 0) as int;
      final currentAvg = (userData['averageRating'] ?? 0).toDouble();
      final endorsements = Map<String, int>.from(userData['endorsements'] ?? {});

      // Increment endorsement counts
      for (final skill in endorsedSkills) {
        endorsements[skill] = (endorsements[skill] ?? 0) + 1;
      }

      final newTotal = currentTotal + 1;
      final newAvg = ((currentAvg * currentTotal) + rating) / newTotal;

      transaction.update(userRef, {
        'averageRating': double.parse(newAvg.toStringAsFixed(2)),
        'totalReviews': newTotal,
        'endorsements': endorsements,
      });

      // 3. Award XP to reviewer for giving a review
      await GamificationService().awardXP(reviewerId, 10, transaction: transaction);
    });
  }
}
