import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_quest_repository.dart';
import '../../domain/entities/quest.dart';
import 'auth_providers.dart';

final questRepositoryProvider = Provider<FirestoreQuestRepository>((ref) {
  return FirestoreQuestRepository();
});

final openQuestsProvider = StreamProvider<List<Quest>>((ref) {
  return ref.watch(questRepositoryProvider).getOpenQuests();
});

final flashQuestsProvider = StreamProvider<List<Quest>>((ref) {
  return ref.watch(questRepositoryProvider).getFlashQuests();
});

final userQuestsProvider = StreamProvider<List<Quest>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(questRepositoryProvider).getUserQuests(user.id);
});

final matchingQuestsProvider = StreamProvider<List<Quest>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  final skills = user.skillIds;
  if (skills.isEmpty) return ref.watch(questRepositoryProvider).getOpenQuests();
  return ref.watch(questRepositoryProvider).getQuestsForSkills(skills);
});
