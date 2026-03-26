import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final firebase.FirebaseFirestore _firestore = firebase.FirebaseFirestore.instance;

  @override
  Stream<List<Transaction>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map<Transaction>((doc) => TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<void> logTransaction(Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      userId: transaction.userId,
      otherUserId: transaction.otherUserId,
      otherUserName: transaction.otherUserName,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      createdAt: transaction.createdAt,
    );
    
    // Note: Usually logged within another repository's transaction
    await _firestore.collection('transactions').doc(transaction.id).set(model.toMap());
  }
}
