import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../../../core/services/credit_economy_service.dart';
import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';
import '../../../../core/services/gamification_service.dart';
import 'package:uuid/uuid.dart';

class FirestoreQuestRepository implements QuestRepository {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  @override
  Stream<List<Quest>> getOpenQuests() {
    return _firestore
        .collection('quests')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Quest>> getFlashQuests() {
    return _firestore
        .collection('quests')
        .where('status', isEqualTo: 'open')
        .where('type', isEqualTo: 'flash')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Quest>> getUserQuests(String userId) {
    return _firestore
        .collection('quests')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Quest>> getQuestsForSkills(List<String> skillTags) {
    if (skillTags.isEmpty) return getOpenQuests();
    return _firestore
        .collection('quests')
        .where('status', isEqualTo: 'open')
        .where('skillTags', arrayContainsAny: skillTags.take(10).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> createQuest(Quest quest) async {
    return _firestore.runTransaction((transaction) async {
      // Escrow: deduct credits from creator immediately
      final userRef = _firestore.collection('users').doc(quest.createdBy);
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw 'User not found';

      final double balance = (userDoc.data()?['timeBalance'] ?? 0.0).toDouble();
      if (balance < quest.creditReward) {
        throw 'Insufficient balance. You need ${quest.creditReward} credits to post this quest.';
      }

      // Deduct credits (escrow)
      transaction.update(userRef, {
        'timeBalance': balance - quest.creditReward,
      });

      // Create the quest
      transaction.set(
        _firestore.collection('quests').doc(quest.id),
        _toMap(quest),
      );

      // Log transaction
      final txId = const Uuid().v4();
      transaction.set(_firestore.collection('transactions').doc(txId), {
        'id': txId,
        'userId': quest.createdBy,
        'otherUserId': 'system',
        'otherUserName': 'Quest Escrow',
        'title': 'Quest: ${quest.title}',
        'amount': -quest.creditReward,
        'type': 'quest',
        'createdAt': firestore.Timestamp.now(),
      });
    });
  }

  @override
  Future<void> applyToQuest(String questId, String userId, String userName) async {
    await _firestore.collection('quests').doc(questId).update({
      'applicantIds': firestore.FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> assignQuest(String questId, String assigneeId, String assigneeName) async {
    await _firestore.collection('quests').doc(questId).update({
      'assignedTo': assigneeId,
      'assigneeName': assigneeName,
      'status': 'active',
    });
  }

  @override
  Future<void> completeQuest(String questId) async {
    final economyService = CreditEconomyService();

    return _firestore.runTransaction((transaction) async {
      final questDoc = await transaction.get(_firestore.collection('quests').doc(questId));
      if (!questDoc.exists) throw 'Quest not found';

      final data = questDoc.data()!;
      if (data['status'] != 'active') throw 'Only active quests can be completed';

      final assigneeId = data['assignedTo'] as String?;
      if (assigneeId == null) throw 'No assignee for this quest';

      final creatorId = data['createdBy'] as String;
      final double creditReward = (data['creditReward'] ?? 0.0).toDouble();

      // Transfer escrowed credits to assignee
      final assigneeRef = _firestore.collection('users').doc(assigneeId);
      final assigneeDoc = await transaction.get(assigneeRef);
      if (!assigneeDoc.exists) throw 'Assignee not found';

      final assigneeData = assigneeDoc.data()!;

      // Calculate Economy 2.0 Allotment
      final economyResult = economyService.calculateAllotment(
        durationInHours: creditReward,
        mentorRating: (assigneeData['averageRating'] ?? 0.0).toDouble(),
        isProfessional: assigneeData['isVerifiedProfessional'] ?? false,
      );

      // Update assignee: add credits + gamification
      final gamification = GamificationService();
      final Map<String, dynamic> assigneeUpdates = {
        'timeBalance': firestore.FieldValue.increment(economyResult.finalAmountToProvider),
      };
      
      assigneeUpdates.addAll(gamification.computeUpdateMap(
        userData: {...assigneeData, ...assigneeUpdates},
        addedXp: GamificationService.defaultXpPerQuest,
      ));
      assigneeUpdates.addAll(gamification.computeStreakUpdate(
        userData: {...assigneeData, ...assigneeUpdates},
      ));

      transaction.update(assigneeRef, assigneeUpdates);

      // Update global economy treasury
      economyService.updateGlobalEconomy(transaction, economyResult.taxAmount, economyResult.bonusAmount);

      // Mark quest completed
      transaction.update(questDoc.reference, {
        'status': 'completed',
      });

      // Log transaction for assignee
      final now = DateTime.now();
      final txId = const Uuid().v4();
      transaction.set(_firestore.collection('transactions').doc(txId), {
        'id': txId,
        'userId': assigneeId,
        'otherUserId': creatorId,
        'otherUserName': data['creatorName'] ?? 'Quest Owner',
        'title': 'Quest Completed: ${data['title']}',
        'amount': economyResult.finalAmountToProvider,
        'type': 'quest',
        'createdAt': firestore.Timestamp.fromDate(now),
        'taxAmount': economyResult.taxAmount,
        'bonusAmount': economyResult.bonusAmount,
        'bonusReason': economyResult.bonusReason,
      });
    });
  }

  @override
  Future<void> cancelQuest(String questId) async {
    return _firestore.runTransaction((transaction) async {
      final questDoc = await transaction.get(_firestore.collection('quests').doc(questId));
      if (!questDoc.exists) throw 'Quest not found';

      final data = questDoc.data()!;
      if (data['status'] == 'completed') throw 'Cannot cancel a completed quest';

      final creatorId = data['createdBy'] as String;
      final creditReward = (data['creditReward'] ?? 0) as int;

      // Refund escrowed credits to creator
      transaction.update(_firestore.collection('users').doc(creatorId), {
        'timeBalance': firestore.FieldValue.increment(creditReward),
      });

      transaction.update(questDoc.reference, {
        'status': 'cancelled',
      });

      // Log refund
      final txId = const Uuid().v4();
      transaction.set(_firestore.collection('transactions').doc(txId), {
        'id': txId,
        'userId': creatorId,
        'otherUserId': 'system',
        'otherUserName': 'Quest Refund',
        'title': 'Refund: ${data['title']}',
        'amount': creditReward,
        'type': 'quest',
        'createdAt': firestore.Timestamp.now(),
      });
    });
  }

  Quest _fromMap(String id, Map<String, dynamic> data) {
    return Quest(
      id: id,
      type: QuestType.values.byName(data['type'] ?? 'openBounty'),
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorAvatarUrl: data['creatorAvatarUrl'],
      assignedTo: data['assignedTo'],
      assigneeName: data['assigneeName'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      skillTags: List<String>.from(data['skillTags'] ?? []),
      creditReward: (data['creditReward'] ?? 0.0).toDouble(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as firestore.Timestamp).toDate()
          : null,
      status: QuestStatus.values.byName(data['status'] ?? 'open'),
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
      applicantIds: List<String>.from(data['applicantIds'] ?? []),
    );
  }

  Map<String, dynamic> _toMap(Quest quest) {
    return {
      'type': quest.type.name,
      'createdBy': quest.createdBy,
      'creatorName': quest.creatorName,
      'creatorAvatarUrl': quest.creatorAvatarUrl,
      'assignedTo': quest.assignedTo,
      'assigneeName': quest.assigneeName,
      'title': quest.title,
      'description': quest.description,
      'skillTags': quest.skillTags,
      'creditReward': quest.creditReward,
      'expiresAt': quest.expiresAt != null
          ? firestore.Timestamp.fromDate(quest.expiresAt!)
          : null,
      'status': quest.status.name,
      'createdAt': firestore.Timestamp.fromDate(quest.createdAt),
      'applicantIds': quest.applicantIds,
    };
  }
}
