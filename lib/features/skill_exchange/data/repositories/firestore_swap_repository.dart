import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

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

      final balance = userDoc.data()?['timeBalance'] ?? 0;
      if (balance < 1) {
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
    return _firestore.runTransaction((transaction) async {
      final swapDoc = await transaction.get(_firestore.collection('swaps').doc(requestId));
      if (!swapDoc.exists) throw 'Swap request not found';
      
      final data = swapDoc.data()!;
      final status = data['status'] ?? 'pending';
      if (status != 'accepted') throw 'Only accepted swaps can be completed';

      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      final int timeValue = data['timeValue'] ?? 1;

      // Mark swap as completed
      transaction.update(swapDoc.reference, {'status': SwapRequestStatus.completed.name});

      // Atomically swap time balance
      transaction.update(_firestore.collection('users').doc(senderId), {
        'timeBalance': firestore.FieldValue.increment(-timeValue),
      });
      transaction.update(_firestore.collection('users').doc(receiverId), {
        'timeBalance': firestore.FieldValue.increment(timeValue),
      });

      // Log transactions for history
      final now = DateTime.now();
      final senderTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: senderId,
        otherUserId: receiverId,
        otherUserName: data['receiverName'] ?? 'Partner',
        title: data['skillTitle'] ?? 'Skill Swap',
        amount: -timeValue,
        type: TransactionType.swap,
        createdAt: now,
      );
      final receiverTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: receiverId,
        otherUserId: senderId,
        otherUserName: data['senderName'] ?? 'Partner',
        title: data['skillTitle'] ?? 'Skill Swap',
        amount: timeValue,
        type: TransactionType.swap,
        createdAt: now,
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
      timeValue: data['timeValue'] ?? 1,
      status: SwapRequestStatus.values.byName(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
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
    };
  }
}
