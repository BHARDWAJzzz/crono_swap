import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lecture.dart';

class LectureModel extends Lecture {
  LectureModel({
    required super.id,
    required super.title,
    required super.description,
    required super.providerId,
    required super.providerName,
    super.previewUrl,
    required super.contentUrl,
    required super.priceInHours,
    required super.durationMinutes,
    required super.type,
    required super.createdAt,
    required super.categories,
  });

  factory LectureModel.fromMap(String id, Map<String, dynamic> data) {
    return LectureModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      previewUrl: data['previewUrl'],
      contentUrl: data['contentUrl'] ?? '',
      priceInHours: (data['priceInHours'] ?? 1).toInt(),
      durationMinutes: (data['durationMinutes'] ?? 0).toInt(),
      type: _parseType(data['type']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      categories: List<String>.from(data['categories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'providerId': providerId,
      'providerName': providerName,
      'previewUrl': previewUrl,
      'contentUrl': contentUrl,
      'priceInHours': priceInHours,
      'durationMinutes': durationMinutes,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'categories': categories,
    };
  }

  static LectureType _parseType(String? type) {
    try {
      if (type == null) return LectureType.video;
      return LectureType.values.byName(type);
    } catch (_) {
      return LectureType.video; // Fallback
    }
  }
}
