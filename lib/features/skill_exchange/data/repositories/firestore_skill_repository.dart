import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';
import '../models/skill_model.dart';

class FirestoreSkillRepository implements SkillRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'skills';

  @override
  Future<List<Skill>> getSkills() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => SkillModel.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<Skill> getSkillById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return SkillModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> addSkill(Skill skill) async {
    final model = SkillModel(
      id: skill.id,
      title: skill.title,
      description: skill.description,
      category: skill.category,
      timeValue: skill.timeValue,
      providerId: skill.providerId,
      providerName: skill.providerName,
      providerAvatarUrl: skill.providerAvatarUrl,
    );
    await _firestore.collection(_collection).doc(skill.id).set(model.toJson());
  }

  @override
  Future<void> updateSkill(Skill skill) async {
    final model = SkillModel(
      id: skill.id,
      title: skill.title,
      description: skill.description,
      category: skill.category,
      timeValue: skill.timeValue,
      providerId: skill.providerId,
      providerName: skill.providerName,
      providerAvatarUrl: skill.providerAvatarUrl,
    );
    await _firestore.collection(_collection).doc(skill.id).update(model.toJson());
  }
}
