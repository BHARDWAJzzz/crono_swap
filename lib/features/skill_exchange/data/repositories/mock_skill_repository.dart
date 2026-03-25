import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';
import '../models/skill_model.dart';

class MockSkillRepository implements SkillRepository {
  final List<Skill> _skills = [
    SkillModel(
      id: '1',
      title: 'Flutter Mentoring',
      description: 'Learn how to build beautiful apps with Flutter.',
      category: 'Tech',
      providerId: 'user1',
      providerName: 'Jane Doe',
      timeValue: 2,
    ),
    SkillModel(
      id: '2',
      title: 'Bike Repair',
      description: 'Fixing punctures, chain maintenance, and more.',
      category: 'Repair',
      providerId: 'user2',
      providerName: 'John Smith',
      timeValue: 1,
    ),
    SkillModel(
      id: '3',
      title: 'Cooking Lessons',
      description: 'Master the art of Italian pasta.',
      category: 'Cooking',
      providerId: 'user3',
      providerName: 'Alice Kitchen',
      timeValue: 3,
    ),
  ];

  @override
  Future<List<Skill>> getSkills() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _skills;
  }

  @override
  Future<Skill> getSkillById(String id) async {
    return _skills.firstWhere((skill) => skill.id == id);
  }

  @override
  Future<void> addSkill(Skill skill) async {
    _skills.add(skill);
  }

  @override
  Future<void> updateSkill(Skill skill) async {
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index != -1) {
      _skills[index] = skill;
    }
  }
}
