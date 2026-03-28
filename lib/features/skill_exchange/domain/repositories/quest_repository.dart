import '../entities/quest.dart';

abstract class QuestRepository {
  Stream<List<Quest>> getOpenQuests();
  Stream<List<Quest>> getFlashQuests();
  Stream<List<Quest>> getUserQuests(String userId);
  Stream<List<Quest>> getQuestsForSkills(List<String> skillTags);
  Future<void> createQuest(Quest quest);
  Future<void> applyToQuest(String questId, String userId, String userName);
  Future<void> assignQuest(String questId, String assigneeId, String assigneeName);
  Future<void> completeQuest(String questId);
  Future<void> cancelQuest(String questId);
}
