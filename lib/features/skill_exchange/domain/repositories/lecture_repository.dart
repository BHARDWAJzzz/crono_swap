import '../entities/lecture.dart';

abstract class LectureRepository {
  Stream<List<Lecture>> getLectures();
  Stream<List<Lecture>> getMyPurchasedLectures(String userId);
  Future<void> uploadLecture(Lecture lecture);
  Future<String> uploadLectureFile(String path, String name);
  Future<void> buyLecture(String userId, Lecture lecture);
}
