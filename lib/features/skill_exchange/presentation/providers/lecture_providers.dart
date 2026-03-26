import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lecture.dart';
import '../../data/repositories/firestore_lecture_repository.dart';
import '../providers/auth_providers.dart';

final lectureRepositoryProvider = Provider((ref) => FirestoreLectureRepository());

final lectureListProvider = StreamProvider<List<Lecture>>((ref) {
  return ref.watch(lectureRepositoryProvider).getLectures();
});

final myPurchasedLecturesProvider = StreamProvider<List<Lecture>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(lectureRepositoryProvider).getMyPurchasedLectures(user.id);
});
