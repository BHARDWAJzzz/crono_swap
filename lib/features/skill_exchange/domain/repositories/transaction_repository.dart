import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> getUserTransactions(String userId);
  Future<void> logTransaction(Transaction transaction);
}
