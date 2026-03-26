enum TransactionType { swap, lecturePurchase, administrative }

class Transaction {
  final String id;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String title; // "React Lesson", "Design Swap"
  final int amount; // positive for income, negative for expense
  final TransactionType type;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
  });
}
