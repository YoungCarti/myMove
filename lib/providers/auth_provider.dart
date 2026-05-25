import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _authSubscription;
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialChecked = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialChecked => _isInitialChecked;

  AuthProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialChecked = true;
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
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
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
        
        _user = _auth.currentUser;
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

  // Sign In with Google & create user profile in Cloud Firestore if new
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      // 1. Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        _setLoading(false);
        return false;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _setLoading(false);
        return false;
      }

      // Synchronously update _user here to guarantee the UI has the state instantly
      _user = firebaseUser;
      
      try {
        // 5. Check if the user document already exists in Firestore to avoid overwriting existing data
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          // Store user details in Cloud Firestore if this is a new sign-in
          await _firestore.collection('users').doc(firebaseUser.uid).set({
            'uid': firebaseUser.uid,
            'name': firebaseUser.displayName ?? '',
            'email': firebaseUser.email ?? '',
            'role': 'user', // Default user role
            'phoneNumber': firebaseUser.phoneNumber ?? '',
            'profileImageUrl': firebaseUser.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (firestoreError) {
        // Rollback Firebase auth session on Firestore failure
        _user = null;
        await _auth.signOut();
        await _googleSignIn.signOut();
        rethrow;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to sign in with Google: ${e.toString()}');
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
    _user = null;
    await _auth.signOut();
    await _googleSignIn.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
