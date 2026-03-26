import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';

class FirestoreSwapRepository implements SwapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Mark swap as completed
      transaction.update(swapDoc.reference, {'status': SwapRequestStatus.completed.name});

      // Atomically swap time balance (1 unit)
      transaction.update(_firestore.collection('users').doc(senderId), {
        'timeBalance': FieldValue.increment(-1),
      });
      transaction.update(_firestore.collection('users').doc(receiverId), {
        'timeBalance': FieldValue.increment(1),
      });
    });
  }

  SwapRequest _fromMap(String id, Map<String, dynamic> data) {
    return SwapRequest(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      skillId: data['skillId'] ?? '',
      skillTitle: data['skillTitle'] ?? '',
      status: SwapRequestStatus.values.byName(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toMap(SwapRequest request) {
    return {
      'senderId': request.senderId,
      'senderName': request.senderName,
      'receiverId': request.receiverId,
      'receiverName': request.receiverName,
      'skillId': request.skillId,
      'skillTitle': request.skillTitle,
      'status': request.status.name,
      'createdAt': Timestamp.fromDate(request.createdAt),
    };
  }
}
