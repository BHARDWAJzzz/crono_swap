import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_skill_repository.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return FirestoreSkillRepository();
});

final skillListProvider = FutureProvider<List<Skill>>((ref) async {
  final repository = ref.watch(skillRepositoryProvider);
  return repository.getSkills();
});

// timeBalanceProvider is now handled by userDataProvider in auth_providers.dart
