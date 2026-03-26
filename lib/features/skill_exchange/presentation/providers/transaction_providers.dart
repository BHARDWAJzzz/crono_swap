import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_transaction_repository.dart';
import '../providers/auth_providers.dart';
import '../../domain/entities/transaction.dart';

final transactionRepositoryProvider = Provider((ref) => FirestoreTransactionRepository());

final userTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(transactionRepositoryProvider).getUserTransactions(user.id);
});
