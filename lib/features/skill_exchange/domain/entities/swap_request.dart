enum SwapRequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled
}

class SwapRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String skillId;
  final String skillTitle;
  final SwapRequestStatus status;
  final DateTime createdAt;

  SwapRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.skillId,
    required this.skillTitle,
    this.status = SwapRequestStatus.pending,
    required this.createdAt,
  });

  SwapRequest copyWith({
    SwapRequestStatus? status,
  }) {
    return SwapRequest(
      id: id,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      skillId: skillId,
      skillTitle: skillTitle,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
