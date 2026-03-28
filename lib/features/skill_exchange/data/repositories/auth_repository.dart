import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String bio,
    required List<String> interests,
    required DateTime dob,
    String? avatarUrl,
    String? certificateUrl,
    String? resumeUrl,
    String? linkedinUrl,
  });
  Future<void> signOut();
  Future<AppUser?> getCurrentUserData();
  Future<void> updateUserProfile({
    required String name,
    required String bio,
    required List<String> interests,
    String? avatarUrl,
    String? certificateUrl,
    String? resumeUrl,
    String? linkedinUrl,
    List<String>? skillsWanted,
    List<String>? availability,
  });
  Future<void> createProfileForExistingUser({
    required String name,
    required String bio,
    required List<String> interests,
    required DateTime dob,
  });
  Future<String> uploadProfileImage(File image);
  Future<void> saveFcmToken(String token);
  Future<String> uploadVerificationFile(File file, String type);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    try {
      await googleSignIn.initialize();
    } catch (_) {
      // Already initialized
    }
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw 'Google sign-in failed';

    // Check if user doc already exists
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // First-time Google user — create profile
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'bio': '',
        'interests': [],
        'status': 'pending',
        'timeBalance': 10,
        'skillIds': [],
        'skillsWanted': [],
        'boughtLectureIds': [],
        'role': 'user',
        'avatarUrl': user.photoURL,
        'hoursTeaching': 0,
        'hoursLearning': 0,
        'swapsCompleted': 0,
        'lecturesSold': 0,
        'availability': [],
        'xp': 0,
        'level': 1,
        'streak': 0,
        'badgeIds': [],
        'averageRating': 0,
        'totalReviews': 0,
      });
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String bio,
    required List<String> interests,
    required DateTime dob,
    String? avatarUrl,
    String? certificateUrl,
    String? resumeUrl,
    String? linkedinUrl,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final role = email.toLowerCase() == 'superadmin@gmail.com' ? 'superadmin' : 'user';
      final status = role == 'superadmin' ? 'approved' : 'pending';
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'bio': bio,
        'interests': interests,
        'dob': Timestamp.fromDate(dob),
        'status': status,
        'timeBalance': 10,
        'skillIds': [],
        'skillsWanted': [],
        'boughtLectureIds': [],
        'role': role,
        'avatarUrl': avatarUrl,
        'certificateUrl': certificateUrl,
        'resumeUrl': resumeUrl,
        'linkedinUrl': linkedinUrl,
        'hoursTeaching': 0,
        'hoursLearning': 0,
        'swapsCompleted': 0,
        'lecturesSold': 0,
        'availability': [],
        'xp': 0,
        'level': 1,
        'streak': 0,
        'badgeIds': [],
        'averageRating': 0,
        'totalReviews': 0,
      });
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    String role = data['role'] ?? 'user';
    String status = data['status'] ?? 'pending';
    
    if (user.email?.toLowerCase() == 'superadmin@gmail.com') {
      role = 'superadmin';
      status = 'approved';
    }

    return AppUser(
      id: user.uid,
      name: data['name'] ?? '',
      email: user.email ?? data['email'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      skillIds: List<String>.from(data['skillIds'] ?? []),
      skillsWanted: List<String>.from(data['skillsWanted'] ?? []),
      boughtLectureIds: List<String>.from(data['boughtLectureIds'] ?? []),
      timeBalance: (data['timeBalance'] ?? 0).toInt(),
      role: role,
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      status: status,
      avatarUrl: data['avatarUrl'],
      certificateUrl: data['certificateUrl'],
      resumeUrl: data['resumeUrl'],
      linkedinUrl: data['linkedinUrl'],
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalReviews: (data['totalReviews'] ?? 0).toInt(),
      isVerifiedProfessional: data['isVerifiedProfessional'] ?? false,
      level: (data['level'] ?? 1).toInt(),
      xp: (data['xp'] ?? 0).toInt(),
      streak: (data['streak'] ?? 0).toInt(),
      badgeIds: List<String>.from(data['badgeIds'] ?? []),
      hoursTeaching: (data['hoursTeaching'] ?? 0).toInt(),
      hoursLearning: (data['hoursLearning'] ?? 0).toInt(),
      swapsCompleted: (data['swapsCompleted'] ?? 0).toInt(),
      lecturesSold: (data['lecturesSold'] ?? 0).toInt(),
      availability: List<String>.from(data['availability'] ?? []),
    );
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required String bio,
    required List<String> interests,
    String? avatarUrl,
    String? certificateUrl,
    String? resumeUrl,
    String? linkedinUrl,
    List<String>? skillsWanted,
    List<String>? availability,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'bio': bio,
      'interests': interests,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
      if (skillsWanted != null) 'skillsWanted': skillsWanted,
      if (availability != null) 'availability': availability,
    });
  }

  @override
  Future<void> createProfileForExistingUser({
    required String name,
    required String bio,
    required List<String> interests,
    required DateTime dob,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final role = user.email?.toLowerCase() == 'superadmin@gmail.com' ? 'superadmin' : 'user';
    final status = role == 'superadmin' ? 'approved' : 'pending';

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email,
      'bio': bio,
      'interests': interests,
      'dob': Timestamp.fromDate(dob),
      'status': status,
      'timeBalance': 10,
      'skillIds': [],
      'skillsWanted': [],
      'boughtLectureIds': [],
      'role': role,
      'hoursTeaching': 0,
      'hoursLearning': 0,
      'swapsCompleted': 0,
      'lecturesSold': 0,
      'availability': [],
      'xp': 0,
      'level': 1,
      'streak': 0,
      'badgeIds': [],
      'averageRating': 0,
      'totalReviews': 0,
    });
  }

  @override
  Future<String> uploadProfileImage(File image) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final ref = _storage.ref().child('profile_images').child('${user.uid}.jpg');
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> saveFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  @override
  Future<String> uploadVerificationFile(File file, String type) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final extension = file.path.split('.').last;
    final ref = _storage.ref().child('verification').child(user.uid).child('$type.$extension');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
