import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../../../core/services/credit_economy_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../domain/entities/lecture.dart';
import '../../domain/repositories/lecture_repository.dart';
import '../models/lecture_model.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/gamification_service.dart';

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
      priceInHours: lecture.priceInHours.toDouble(),
      durationMinutes: lecture.durationMinutes,
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
    final economyService = CreditEconomyService();

    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(userId));
      final sellerDoc = await transaction.get(_firestore.collection('users').doc(lecture.providerId));

      if (!userDoc.exists) throw 'Buyer profile not found';
      if (!sellerDoc.exists) throw 'Seller profile not found';

      final userData = userDoc.data()!;
      final sellerData = sellerDoc.data()!;
      
      final double buyerBalance = (userData['timeBalance'] ?? 0.0).toDouble();
      final boughtIds = List<String>.from(userData['boughtLectureIds'] ?? []);

      if (boughtIds.contains(lecture.id)) throw 'You already own this lecture';
      if (buyerBalance < lecture.priceInHours) {
        throw 'Insufficient balance. You need ${lecture.priceInHours} hours to buy this lecture.';
      }

      final double price = (lecture.priceInHours ?? 0.0).toDouble();

      // Calculate Economy 2.0 Allotment for Seller
      final economyResult = economyService.calculateAllotment(
        durationInHours: price,
        mentorRating: (sellerData['averageRating'] ?? 0.0).toDouble(),
        isProfessional: sellerData['isVerifiedProfessional'] ?? false,
      );

      // 1. Calculate Buyer Updates
      final Map<String, dynamic> buyerUpdates = {
        'timeBalance': firestore.FieldValue.increment(-economyResult.baseAmount),
        'boughtLectureIds': firestore.FieldValue.arrayUnion([lecture.id]),
        'hoursLearning': firestore.FieldValue.increment(economyResult.baseAmount),
      };
      
      // Calculate Seller Updates
      final Map<String, dynamic> sellerUpdates = {
        'timeBalance': firestore.FieldValue.increment(economyResult.finalAmountToProvider),
        'lecturesSold': firestore.FieldValue.increment(1),
        'hoursTeaching': firestore.FieldValue.increment(economyResult.baseAmount),
      };

      // 2. Apply Gamification logic
      final gamification = GamificationService();
      
      // Award XP to seller (30 XP for selling)
      sellerUpdates.addAll(gamification.computeUpdateMap(
        userData: {...sellerData, ...sellerUpdates},
        addedXp: 30,
      ));

      // 3. Update global economy treasury
      economyService.updateGlobalEconomy(transaction, economyResult.taxAmount, economyResult.bonusAmount);

      // 4. Batch all updates
      transaction.update(userDoc.reference, buyerUpdates);
      transaction.update(sellerDoc.reference, sellerUpdates);

      // Log transactions for history
      final now = DateTime.now();
      final buyerTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: userId,
        otherUserId: lecture.providerId,
        otherUserName: lecture.providerName,
        title: 'Bought: ${lecture.title}',
        amount: -economyResult.baseAmount,
        type: TransactionType.lecturePurchase,
        createdAt: now,
      );
      final sellerTransaction = TransactionModel(
        id: const Uuid().v4(),
        userId: lecture.providerId,
        otherUserId: userId,
        otherUserName: userData['name'] ?? 'Buyer',
        title: 'Sold: ${lecture.title}',
        amount: economyResult.finalAmountToProvider,
        type: TransactionType.lecturePurchase,
        createdAt: now,
        taxAmount: economyResult.taxAmount,
        bonusAmount: economyResult.bonusAmount,
        bonusReason: economyResult.bonusReason,
      );

      transaction.set(_firestore.collection('transactions').doc(buyerTransaction.id), buyerTransaction.toMap());
      transaction.set(_firestore.collection('transactions').doc(sellerTransaction.id), sellerTransaction.toMap());
    });
  }
}
