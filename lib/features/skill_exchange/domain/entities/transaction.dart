enum TransactionType { swap, lecturePurchase, administrative, quest, bonus }

class Transaction {
  final String id;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String title; // "React Lesson", "Design Swap"
  final double amount; // positive for income, negative for expense
  final TransactionType type;
  final DateTime createdAt;
  
  // Economy 2.0 fields
  final double? taxAmount;
  final double? bonusAmount;
  final String? bonusReason;

  Transaction({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.taxAmount,
    this.bonusAmount,
    this.bonusReason,
  });
}
