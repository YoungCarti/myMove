import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSubscription;
  
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Set loading state helper
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Sign In using Firebase Auth
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Register using Firebase Auth & create user profile in Cloud Firestore
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      // 1. Create user in Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser != null) {
        // 2. Update display name in Firebase Auth
        await firebaseUser.updateDisplayName(name);
        await firebaseUser.reload();

        // 3. Store user details in Cloud Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'name': name,
          'email': email,
          'role': 'user', // Default user role
          'phoneNumber': '',
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to register account: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  // Sign out of the app
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
