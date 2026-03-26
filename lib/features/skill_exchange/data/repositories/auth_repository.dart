import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String bio,
    required List<String> interests,
    required DateTime dob,
    String? avatarUrl,
  });
  Future<void> signOut();
  Future<AppUser?> getCurrentUserData();
  Future<void> updateUserProfile({required String name, required String bio, required List<String> interests, String? avatarUrl});
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
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
        'role': role,
        'avatarUrl': avatarUrl,
      });
    }
  }

  @override
  Future<void> signOut() async {
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
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      skillIds: List<String>.from(data['skillIds'] ?? []),
      timeBalance: data['timeBalance'] ?? 0,
      role: role,
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      status: status,
      avatarUrl: data['avatarUrl'],
    );
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required String bio,
    required List<String> interests,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'bio': bio,
      'interests': interests,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
  }
}
