enum QuestType { openBounty, flash, guild }
enum QuestStatus { open, active, completed, expired, cancelled }

class Quest {
  final String id;
  final QuestType type;
  final String createdBy;
  final String creatorName;
  final String? creatorAvatarUrl;
  final String? assignedTo;
  final String? assigneeName;
  final String title;
  final String description;
  final List<String> skillTags;
  final double creditReward;
  final DateTime? expiresAt;
  final QuestStatus status;
  final DateTime createdAt;
  final List<String> applicantIds;

  Quest({
    required this.id,
    required this.type,
    required this.createdBy,
    required this.creatorName,
    this.creatorAvatarUrl,
    this.assignedTo,
    this.assigneeName,
    required this.title,
    required this.description,
    required this.skillTags,
    required this.creditReward,
    this.expiresAt,
    this.status = QuestStatus.open,
    required this.createdAt,
    this.applicantIds = const [],
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isFlash => type == QuestType.flash;

  Duration? get timeRemaining =>
      expiresAt != null ? expiresAt!.difference(DateTime.now()) : null;

  String get typeLabel {
    switch (type) {
      case QuestType.openBounty:
        return 'Open Bounty';
      case QuestType.flash:
        return 'Flash Quest';
      case QuestType.guild:
        return 'Guild Quest';
    }
  }

  String get typeEmoji {
    switch (type) {
      case QuestType.openBounty:
        return '🎯';
      case QuestType.flash:
        return '⚡';
      case QuestType.guild:
        return '🏰';
    }
  }

  Quest copyWith({
    QuestStatus? status,
    String? assignedTo,
    String? assigneeName,
    List<String>? applicantIds,
  }) {
    return Quest(
      id: id,
      type: type,
      createdBy: createdBy,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      assignedTo: assignedTo ?? this.assignedTo,
      assigneeName: assigneeName ?? this.assigneeName,
      title: title,
      description: description,
      skillTags: skillTags,
      creditReward: creditReward,
      expiresAt: expiresAt,
      status: status ?? this.status,
      createdAt: createdAt,
      applicantIds: applicantIds ?? this.applicantIds,
    );
  }
}
