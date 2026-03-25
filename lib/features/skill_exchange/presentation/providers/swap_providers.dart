import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_swap_repository.dart';
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';
import 'auth_providers.dart';

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return FirestoreSwapRepository();
});

final incomingSwapsProvider = StreamProvider<List<SwapRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(swapRepositoryProvider).getIncomingRequests(user.uid);
});

final outgoingSwapsProvider = StreamProvider<List<SwapRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(swapRepositoryProvider).getOutgoingRequests(user.uid);
});
