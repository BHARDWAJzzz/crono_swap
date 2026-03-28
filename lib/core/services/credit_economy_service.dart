import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

class CreditAllotmentResult {
  final double baseAmount;
  final double taxAmount;
  final double bonusAmount;
  final double finalAmountToProvider;
  final String bonusReason;

  CreditAllotmentResult({
    required this.baseAmount,
    required this.taxAmount,
    required this.bonusAmount,
    required this.finalAmountToProvider,
    this.bonusReason = '',
  });
}

class CreditEconomyService {
  static const double taxRate = 0.01; // 1% Community Tax
  static const double highRatingThreshold = 4.5;
  static const double eliteRatingThreshold = 4.8;
  static const double highRatingBonus = 0.10; // 10%
  static const double eliteRatingBonus = 0.15; // 15%
  static const double professionalHonorarium = 0.5; // +0.5 credits

  /// Calculates the dynamic credit distribution for a completed swap or quest.
  CreditAllotmentResult calculateAllotment({
    required double durationInHours,
    required double mentorRating,
    required bool isProfessional,
  }) {
    final double base = durationInHours;
    final double tax = base * taxRate;
    
    double bonus = 0;
    String reason = '';

    // 1. Quality Multiplier
    if (mentorRating >= eliteRatingThreshold) {
      bonus += base * eliteRatingBonus;
      reason = 'Elite Mentor Bonus (${(eliteRatingBonus * 100).toInt()}%)';
    } else if (mentorRating >= highRatingThreshold) {
      bonus += base * highRatingBonus;
      reason = 'Top Mentor Bonus (${(highRatingBonus * 100).toInt()}%)';
    }

    // 2. Professional honorarium
    if (isProfessional) {
      bonus += professionalHonorarium;
      reason += (reason.isEmpty ? '' : ' + ') + 'Professional Honorarium';
    }

    final double finalToProvider = (base - tax) + bonus;

    return CreditAllotmentResult(
      baseAmount: base,
      taxAmount: tax,
      bonusAmount: bonus,
      finalAmountToProvider: finalToProvider,
      bonusReason: reason,
    );
  }

  /// Updates the global treasury and economy metrics in Firestore.
  /// This should be called WITHIN the same transaction as the credit transfer.
  void updateGlobalEconomy(firebase.Transaction transaction, double taxAmount, double bonusAmount) {
    final economyRef = firebase.FirebaseFirestore.instance.collection('system_metrics').doc('economy_v1');
    
    transaction.update(economyRef, {
      'total_treasury_balance': firebase.FieldValue.increment(taxAmount),
      'total_bonuses_paid': firebase.FieldValue.increment(bonusAmount),
      'last_updated': firebase.FieldValue.serverTimestamp(),
    });
  }
}
