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
  final String? senderAvatarUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatarUrl;
  final String skillId;
  final String skillTitle;
  final double timeValue;
  final SwapRequestStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;

  SwapRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatarUrl,
    required this.skillId,
    required this.skillTitle,
    required this.timeValue,
    this.status = SwapRequestStatus.pending,
    required this.createdAt,
    this.scheduledAt,
  });

  SwapRequest copyWith({
    SwapRequestStatus? status,
    DateTime? scheduledAt,
  }) {
    return SwapRequest(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatarUrl: receiverAvatarUrl,
      skillId: skillId,
      skillTitle: skillTitle,
      timeValue: timeValue,
      status: status ?? this.status,
      createdAt: createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}
