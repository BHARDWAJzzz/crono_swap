import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../../../core/services/credit_economy_service.dart';
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/gamification_service.dart';

class FirestoreSwapRepository implements SwapRepository {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  @override
  Stream<List<SwapRequest>> getIncomingRequests(String userId) {
    return _firestore
        .collection('swaps')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromMap(doc.id, doc.data())).toList());
  }

  @override
  Stream<List<SwapRequest>> getOutgoingRequests(String userId) {
    return _firestore
        .collection('swaps')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromMap(doc.id, doc.data())).toList());
  }

  @override
  Future<void> createRequest(SwapRequest request) async {
    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(request.senderId));
      if (!userDoc.exists) throw 'Sender user profile not found';

      final double balance = (userDoc.data()?['timeBalance'] ?? 0.0).toDouble();
      if (balance < 1.0) {
        throw 'Insufficient balance. You need at least 1 hour to request a skill swap.';
      }

      transaction.set(_firestore.collection('swaps').doc(request.id), _toMap(request));
    });
  }

  @override
  Future<void> updateRequestStatus(String requestId, SwapRequestStatus status) async {
    await _firestore.collection('swaps').doc(requestId).update({
      'status': status.name,
    });
  }

  @override
  Future<void> completeRequest(String requestId) async {
    final economyService = CreditEconomyService();

    return _firestore.runTransaction((transaction) async {
      final swapDoc = await transaction.get(_firestore.collection('swaps').doc(requestId));
      if (!swapDoc.exists) throw 'Swap request not found';
      
      final data = swapDoc.data()!;
      final status = data['status'] ?? 'pending';
      if (status != 'accepted') throw 'Only accepted swaps can be completed';

      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      final senderRef = _firestore.collection('users').doc(senderId);
      final receiverRef = _firestore.collection('users').doc(receiverId);

      // 1. Fetch all required documents
      final senderDoc = await transaction.get(senderRef);
      final receiverDoc = await transaction.get(receiverRef);

      if (!senderDoc.exists) throw 'Sender profile not found';
      if (!receiverDoc.exists) throw 'Receiver profile not found';

      final senderData = senderDoc.data()!;
      final receiverData = receiverDoc.data()!;

      final double duration = (data['timeValue'] ?? 1.0).toDouble();

      // 2. Calculate Economy 2.0 Allotment
      final economyResult = economyService.calculateAllotment(
        durationInHours: duration,
        mentorRating: (receiverData['averageRating'] ?? 0.0).toDouble(),
        isProfessional: receiverData['isVerifiedProfessional'] ?? false,
      );

      final Map<String, dynamic> senderUpdates = {
        'timeBalance': firestore.FieldValue.increment(-economyResult.baseAmount), // Learner always pays the base
        'hoursLearning': firestore.FieldValue.increment(economyResult.baseAmount),
        'swapsCompleted': firestore.FieldValue.increment(1),
      };
      
      final Map<String, dynamic> receiverUpdates = {
        'timeBalance': firestore.FieldValue.increment(economyResult.finalAmountToProvider),
        'hoursTeaching': firestore.FieldValue.increment(economyResult.baseAmount),
        'swapsCompleted': firestore.FieldValue.increment(1),
      };

      // Apply Gamification
      final gamification = GamificationService();
      senderUpdates.addAll(gamification.computeUpdateMap(
        userData: {...senderData, ...senderUpdates}, 
        addedXp: 50,
      ));
      receiverUpdates.addAll(gamification.computeUpdateMap(
        userData: {...receiverData, ...receiverUpdates}, 
        addedXp: 50,
      ));

      // Update streaks
      senderUpdates.addAll(gamification.computeStreakUpdate(userData: {...senderData, ...senderUpdates}));
      receiverUpdates.addAll(gamification.computeStreakUpdate(userData: {...receiverData, ...receiverUpdates}));

      // 3. Apply all updates
      transaction.update(swapDoc.reference, {'status': SwapRequestStatus.completed.name});
      transaction.update(senderRef, senderUpdates);
      transaction.update(receiverRef, receiverUpdates);

      // Update global economy treasury
      economyService.updateGlobalEconomy(transaction, economyResult.taxAmount, economyResult.bonusAmount);

      // Log transactions
      final now = DateTime.now();
      final senderTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: senderId,
        otherUserId: receiverId,
        otherUserName: data['receiverName'] ?? 'Partner',
        title: data['skillTitle'] ?? 'Skill Swap',
        amount: -economyResult.baseAmount,
        type: TransactionType.swap,
        createdAt: now,
      );

      final receiverTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: receiverId,
        otherUserId: senderId,
        otherUserName: data['senderName'] ?? 'Partner',
        title: data['skillTitle'] ?? 'Skill Swap',
        amount: economyResult.finalAmountToProvider,
        type: TransactionType.swap,
        createdAt: now,
        taxAmount: economyResult.taxAmount,
        bonusAmount: economyResult.bonusAmount,
        bonusReason: economyResult.bonusReason,
      );

      transaction.set(_firestore.collection('transactions').doc(senderTransaction.id), senderTransaction.toMap());
      transaction.set(_firestore.collection('transactions').doc(receiverTransaction.id), receiverTransaction.toMap());
    });
  }

  SwapRequest _fromMap(String id, Map<String, dynamic> data) {
    return SwapRequest(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatarUrl: data['senderAvatarUrl'],
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverAvatarUrl: data['receiverAvatarUrl'],
      skillId: data['skillId'] ?? '',
      skillTitle: data['skillTitle'] ?? '',
      timeValue: (data['timeValue'] ?? 1.0).toDouble(),
      status: SwapRequestStatus.values.byName(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
      scheduledAt: data['scheduledAt'] != null ? (data['scheduledAt'] as firestore.Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> _toMap(SwapRequest request) {
    return {
      'senderId': request.senderId,
      'senderName': request.senderName,
      'senderAvatarUrl': request.senderAvatarUrl,
      'receiverId': request.receiverId,
      'receiverName': request.receiverName,
      'receiverAvatarUrl': request.receiverAvatarUrl,
      'skillId': request.skillId,
      'skillTitle': request.skillTitle,
      'timeValue': request.timeValue,
      'status': request.status.name,
      'createdAt': firestore.Timestamp.fromDate(request.createdAt),
      'scheduledAt': request.scheduledAt != null ? firestore.Timestamp.fromDate(request.scheduledAt!) : null,
    };
  }
}
