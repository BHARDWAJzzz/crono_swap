import '../entities/swap_request.dart';

abstract class SwapRepository {
  Stream<List<SwapRequest>> getIncomingRequests(String userId);
  Stream<List<SwapRequest>> getOutgoingRequests(String userId);
  Future<void> createRequest(SwapRequest request);
  Future<void> updateRequestStatus(String requestId, SwapRequestStatus status);
  Future<void> completeRequest(String requestId);
}
