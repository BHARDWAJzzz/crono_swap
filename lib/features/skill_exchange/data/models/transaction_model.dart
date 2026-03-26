import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required super.id,
    required super.userId,
    required super.otherUserId,
    required super.otherUserName,
    required super.title,
    required super.amount,
    required super.type,
    required super.createdAt,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      otherUserId: data['otherUserId'] ?? '',
      otherUserName: data['otherUserName'] ?? '',
      title: data['title'] ?? '',
      amount: data['amount'] ?? 0,
      type: TransactionType.values.byName(data['type'] ?? 'swap'),
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'title': title,
      'amount': amount,
      'type': type.name,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}
