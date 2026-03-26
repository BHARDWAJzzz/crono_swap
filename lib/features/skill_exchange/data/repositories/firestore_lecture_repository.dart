import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../domain/entities/lecture.dart';
import '../../domain/repositories/lecture_repository.dart';
import '../models/lecture_model.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreLectureRepository implements LectureRepository {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<Lecture>> getLectures() {
    return _firestore
        .collection('lectures')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LectureModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Lecture>> getMyPurchasedLectures(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
          final boughtIds = List<String>.from(userDoc.data()?['boughtLectureIds'] ?? []);
          if (boughtIds.isEmpty) return [];

          final lectureDocs = await _firestore
              .collection('lectures')
              .where(firestore.FieldPath.documentId, whereIn: boughtIds)
              .get();

          return lectureDocs.docs
              .map((doc) => LectureModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Future<void> uploadLecture(Lecture lecture) async {
    await _firestore.collection('lectures').doc(lecture.id).set(LectureModel(
      id: lecture.id,
      title: lecture.title,
      description: lecture.description,
      providerId: lecture.providerId,
      providerName: lecture.providerName,
      priceInHours: lecture.priceInHours,
      type: lecture.type,
      contentUrl: lecture.contentUrl,
      createdAt: lecture.createdAt,
      categories: lecture.categories,
    ).toMap());
  }

  @override
  Future<String> uploadLectureFile(String path, String name) async {
    final ref = _storage.ref().child('lectures').child(name);
    final uploadTask = await ref.putFile(File(path));
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> buyLecture(String userId, Lecture lecture) async {
    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(userId));
      final sellerDoc = await transaction.get(_firestore.collection('users').doc(lecture.providerId));

      if (!userDoc.exists) throw 'Buyer profile not found';
      if (!sellerDoc.exists) throw 'Seller profile not found';

      final buyerBalance = userDoc.data()?['timeBalance'] ?? 0;
      final boughtIds = List<String>.from(userDoc.data()?['boughtLectureIds'] ?? []);

      if (boughtIds.contains(lecture.id)) throw 'You already own this lecture';
      if (buyerBalance < lecture.priceInHours) {
        throw 'Insufficient balance. You need ${lecture.priceInHours} hours to buy this lecture.';
      }

      // 1. Deduct from buyer
      transaction.update(userDoc.reference, {
        'boughtLectureIds': firestore.FieldValue.arrayUnion([lecture.id]),
        'timeBalance': firestore.FieldValue.increment(-lecture.priceInHours),
      });

      // 2. Add to seller
      transaction.update(sellerDoc.reference, {
        'timeBalance': firestore.FieldValue.increment(lecture.priceInHours),
      });

      // Log transactions for history
      final now = DateTime.now();
      final buyerTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: userId,
        otherUserId: lecture.providerId,
        otherUserName: lecture.providerName,
        title: 'Bought: ${lecture.title}',
        amount: -lecture.priceInHours,
        type: TransactionType.lecturePurchase,
        createdAt: now,
      );
      final sellerTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: lecture.providerId,
        otherUserId: userId,
        otherUserName: userDoc.data()?['name'] ?? 'Buyer',
        title: 'Sold: ${lecture.title}',
        amount: lecture.priceInHours,
        type: TransactionType.lecturePurchase,
        createdAt: now,
      );

      transaction.set(_firestore.collection('transactions').doc(buyerTransaction.id), buyerTransaction.toMap());
      transaction.set(_firestore.collection('transactions').doc(sellerTransaction.id), sellerTransaction.toMap());
    });
  }
}
