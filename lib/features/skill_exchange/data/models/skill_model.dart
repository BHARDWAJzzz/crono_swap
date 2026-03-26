import '../../domain/entities/skill.dart';

class SkillModel extends Skill {
  SkillModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.providerId,
    required super.providerName,
    super.providerAvatarUrl,
    required super.timeValue,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      providerId: json['providerId'],
      providerName: json['providerName'] ?? 'Unknown',
      providerAvatarUrl: json['providerAvatarUrl'],
      timeValue: json['timeValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'providerId': providerId,
      'providerName': providerName,
      'providerAvatarUrl': providerAvatarUrl,
      'timeValue': timeValue,
    };
  }
}
