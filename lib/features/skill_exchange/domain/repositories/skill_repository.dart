import '../entities/skill.dart';

abstract class SkillRepository {
  Future<List<Skill>> getSkills();
  Future<Skill> getSkillById(String id);
  Future<void> addSkill(Skill skill);
  Future<void> updateSkill(Skill skill);
}
