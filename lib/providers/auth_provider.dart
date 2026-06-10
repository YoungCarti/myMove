import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/totp_utils.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  
  User? _user;
  Map<String, dynamic>? _firestoreUserData;
  bool _isLoading = false;
  bool _isInitialChecked = false;
  bool _didJustSignOut = false;
  bool _is2FAPending = false;

  User? get user => _user;
  Map<String, dynamic>? get firestoreUserData => _firestoreUserData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && !_is2FAPending;
  bool get isInitialChecked => _isInitialChecked;
  bool get didJustSignOut => _didJustSignOut;
  bool get is2FAPending => _is2FAPending;
  bool get is2FAEnabled => _firestoreUserData?['is2FAEnabled'] ?? false;
  String get totpSecret => _firestoreUserData?['totpSecret'] ?? '';

  // Reactive user profile getters
  String get displayName => _firestoreUserData?['name'] ?? _user?.displayName ?? '';
  String get username => _firestoreUserData?['username'] ?? '';
  String get phoneNumber => _firestoreUserData?['phoneNumber'] ?? _user?.phoneNumber ?? '';
  String get email => _firestoreUserData?['email'] ?? _user?.email ?? '';
  String get profileImageUrl => _firestoreUserData?['profileImageUrl'] ?? _user?.photoURL ?? '';
  String get bio => _firestoreUserData?['bio'] ?? '';

  List<Map<String, dynamic>> get vehicles {
    if (_firestoreUserData == null) return [];
    if (_firestoreUserData!['vehicles'] != null) {
      return List<Map<String, dynamic>>.from(_firestoreUserData!['vehicles'].map((e) => Map<String, dynamic>.from(e)));
    }
    // Fallback/Migration for older accounts
    final oldMake = _firestoreUserData!['vehicleMake'] as String?;
    final oldPlate = _firestoreUserData!['vehiclePlate'] as String?;
    if ((oldMake != null && oldMake.isNotEmpty) || (oldPlate != null && oldPlate.isNotEmpty)) {
      return [
        {
          'make': oldMake ?? '',
          'plate': oldPlate ?? '',
          'isPrimary': true,
        }
      ];
    }
    return [];
  }

  String get vehicleMake {
    final v = vehicles;
    if (v.isEmpty) return '';
    final primary = v.firstWhere((e) => e['isPrimary'] == true, orElse: () => v.first);
    return primary['make'] as String? ?? '';
  }

  String get vehiclePlate {
    final v = vehicles;
    if (v.isEmpty) return '';
    final primary = v.firstWhere((e) => e['isPrimary'] == true, orElse: () => v.first);
    return primary['plate'] as String? ?? '';
  }

  void resetDidJustSignOut() {
    _didJustSignOut = false;
  }

  AuthProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null && !_isInitialChecked) {
        // App just loaded and we detected an active Firebase session.
        // We must check if they have 2FA enabled before letting them into the app.
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            final data = doc.data();
            final is2FA = data?['is2FAEnabled'] ?? false;
            final secret = (data?['totpSecret'] ?? '').toString().trim();
            if (is2FA && secret.isNotEmpty) {
              _is2FAPending = true;
            }
          }
        } catch (e) {
          debugPrint("Error performing 2FA startup check: $e");
        }
      }

      _user = user;
      _isInitialChecked = true;
      _setupFirestoreSubscription(user);
      notifyListeners();
    });
  }

  // Setup/cancel Firestore subscription reactively
  void _setupFirestoreSubscription(User? user) {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    if (user == null) {
      _firestoreUserData = null;
      notifyListeners();
      return;
    }

    _userDocSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _firestoreUserData = snapshot.data();
      } else {
        _firestoreUserData = null;
      }
      notifyListeners();
    });
  }

  // Set loading state helper
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Sign In using Firebase Auth
  Future<bool> signIn(String emailOrUsername, String password) async {
    _setLoading(true);
    try {
      String emailToUse = emailOrUsername.trim();
      
      // Check if it looks like an email. If not, treat as a username.
      final bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(emailToUse);
      if (!isEmail) {
        // Use Cloud Function to safely resolve username to email
        // without exposing user documents to unauthenticated queries.
        try {
          final callable = FirebaseFunctions.instance.httpsCallable('lookupUsername');
          final result = await callable.call({'username': emailToUse});
          emailToUse = result.data['email'] as String;
        } on FirebaseFunctionsException catch (e) {
          throw Exception(e.message ?? 'Username lookup failed.');
        }
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
      final user = userCredential.user;
      
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        final is2FA = data?['is2FAEnabled'] ?? false;
        final secret = (data?['totpSecret'] ?? '').toString().trim();
        if (is2FA && secret.isNotEmpty) {
          _user = user;
          _firestoreUserData = data;
          _is2FAPending = true;
          _setLoading(false);
          return true;
        }
      }
      
      _user = userCredential.user;
      _is2FAPending = false;
      _setLoading(false);
      return true;
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      if (e is Exception || e is FirebaseAuthException) {
        rethrow;
      }
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
          'username': '',
          'username_lowercase': '',
          'phoneNumber': '',
          'profileImageUrl': '',
          'bio': '',
          'vehicleMake': '',
          'vehiclePlate': '',
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
        Map<String, dynamic>? userData;

        if (!userDoc.exists) {
          // Store user details in Cloud Firestore if this is a new sign-in
          userData = {
            'uid': firebaseUser.uid,
            'name': firebaseUser.displayName ?? '',
            'email': firebaseUser.email ?? '',
            'role': 'user', // Default user role
            'username': '',
            'username_lowercase': '',
            'phoneNumber': firebaseUser.phoneNumber ?? '',
            'profileImageUrl': firebaseUser.photoURL ?? '',
            'bio': '',
            'vehicleMake': '',
            'vehiclePlate': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
        } else {
          userData = userDoc.data() as Map<String, dynamic>?;
        }

        final is2FA = userData?['is2FAEnabled'] ?? false;
        final secret = (userData?['totpSecret'] ?? '').toString().trim();
        if (is2FA && secret.isNotEmpty) {
          _firestoreUserData = userData;
          _is2FAPending = true;
          _setLoading(false);
          return true;
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
    _is2FAPending = false;
    _didJustSignOut = true;
    _setupFirestoreSubscription(null);
    await _auth.signOut();
    await _googleSignIn.signOut();
    notifyListeners();
  }

  // Check if username is already taken by another user (case-insensitively)
  // Uses a Cloud Function to avoid needing collection-level read access.
  Future<bool> isUsernameAvailable(String username) async {
    final cleaned = username.trim().toLowerCase();
    if (cleaned.isEmpty) return false;
    
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('checkUsernameAvailable');
      final result = await callable.call({'username': username.trim()});
      return result.data['available'] as bool;
    } catch (e) {
      // If there's an error (e.g. offline/network), default to false
      return false;
    }
  }

  // Update Username in Firestore
  Future<void> updateUsername(String newUsername) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    
    _setLoading(true);
    try {
      // Verify availability
      final isAvailable = await isUsernameAvailable(newUsername);
      if (!isAvailable) {
        throw Exception('This username is already taken. Please choose another.');
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'username': newUsername.trim(),
        'username_lowercase': newUsername.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to update username: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Update Profile details in Firestore
  Future<void> updateProfile({
    required String name,
    required String bio,
    required List<Map<String, dynamic>> vehicles,
    File? profileImage,
  }) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    
    _setLoading(true);
    try {
      String? imageUrl;
      
      if (profileImage != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${currentUser.uid}.jpg');
              
          final uploadTask = ref.putFile(profileImage);
          final snapshot = await uploadTask.whenComplete(() {});
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          if (e.toString().contains('object-not-found') || e.toString().contains('-13010')) {
             throw Exception('Storage not initialized. Please enable Firebase Storage in the Firebase Console.');
          }
          throw Exception('Failed to upload image: $e');
        }
      }

      await currentUser.updateDisplayName(name.trim());
      if (imageUrl != null) {
        await currentUser.updatePhotoURL(imageUrl);
      }
      
      List<Map<String, dynamic>> sanitizedVehicles = [];
      bool primaryFound = false;
      for (var v in vehicles) {
        final make = (v['make'] as String?)?.trim() ?? '';
        final plate = (v['plate'] as String?)?.trim() ?? '';
        if (make.isEmpty && plate.isEmpty) continue;
        
        bool isPrimary = v['isPrimary'] == true;
        if (isPrimary) {
          if (primaryFound) {
            isPrimary = false; // only one primary allowed
          } else {
            primaryFound = true;
          }
        }
        
        sanitizedVehicles.add({
          'make': make,
          'plate': plate,
          'isPrimary': isPrimary,
        });
      }
      
      if (sanitizedVehicles.isNotEmpty && !primaryFound) {
        sanitizedVehicles.first['isPrimary'] = true;
      }

      final Map<String, dynamic> updates = {
        'name': name.trim(),
        'bio': bio.trim(),
        'vehicles': sanitizedVehicles,
        // Update top-level fields for backwards compatibility with any other code
        'vehicleMake': sanitizedVehicles.isNotEmpty ? sanitizedVehicles.firstWhere((v) => v['isPrimary'] == true, orElse: () => sanitizedVehicles.first)['make'] : '',
        'vehiclePlate': sanitizedVehicles.isNotEmpty ? sanitizedVehicles.firstWhere((v) => v['isPrimary'] == true, orElse: () => sanitizedVehicles.first)['plate'] : '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (imageUrl != null) {
        updates['profileImageUrl'] = imageUrl;
      }

      await _firestore.collection('users').doc(currentUser.uid).update(updates);

      // Sync to publicVehicles collection
      if (sanitizedVehicles.isNotEmpty) {
        final primary = sanitizedVehicles.firstWhere((v) => v['isPrimary'] == true, orElse: () => sanitizedVehicles.first);
        final publicVehicleData = <String, dynamic>{
          'ownerId': currentUser.uid,
          'vehicleId': currentUser.uid,
          'plateNumber': primary['plate'],
          'brand': primary['make'],
          'ownerName': name.trim(),
          'displayName': name.trim(),
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final docRef = _firestore.collection('publicVehicles').doc(currentUser.uid);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.update(publicVehicleData);
        } else {
          publicVehicleData['createdAt'] = FieldValue.serverTimestamp();
          await docRef.set(publicVehicleData);
        }
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Verify Phone Number with Firebase Auth (Sends real SMS)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    _setLoading(true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // If auto-verification succeeds (Android only)
          try {
            final currentUser = _user;
            if (currentUser != null) {
              await currentUser.linkWithCredential(credential);
              await _firestore.collection('users').doc(currentUser.uid).update({
                'phoneNumber': phoneNumber.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            verificationCompleted(credential);
          } catch (e) {
            // Log/ignore errors during auto-linking or handle fallback
          } finally {
            _setLoading(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          verificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _setLoading(false);
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _setLoading(false);
          codeAutoRetrievalTimeout(verificationId);
        },
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Link verified SMS credential to user account and save in Firestore
  Future<void> linkPhoneNumber({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Link Phone to existing Auth account
      await currentUser.linkWithCredential(credential);
      
      // Save phone number in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'phoneNumber': phoneNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      // Fallback: If credential was already linked, or if there is another error,
      // we still want to make sure the Firestore is updated if it matches.
      if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'phoneNumber': phoneNumber.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        rethrow;
      }
    }
  }

  // Update Phone Number directly in Firestore (fallback / administrative)
  Future<void> updatePhoneNumber(String newPhoneNumber) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'phoneNumber': newPhoneNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to update phone number: ${e.toString()}');
    }
  }

  // Delete user account from Firestore and Firebase Auth
  Future<void> deleteAccount() async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    _setLoading(true);
    try {
      // 1. Delete user record in Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();
      // 2. Delete user account in Firebase Auth
      await currentUser.delete();
      // 3. Sign out clean up
      await signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Toggle 2FA in Firestore
  Future<void> toggle2FA(bool enabled) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    if (!enabled) {
      throw Exception('Use disable2FA() with a verification code to turn off Two-Factor Authentication.');
    }
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'is2FAEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to update 2FA status: ${e.toString()}');
    }
  }

  // Disable 2FA with verification code
  Future<void> disable2FA(String code) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    
    final secret = totpSecret;
    if (secret.isEmpty) throw Exception('2FA is not configured for this account.');
    
    _setLoading(true);
    try {
      final isValid = TOTP.verifyCode(secret, code);
      if (!isValid) {
        throw Exception('Invalid 6-digit code. Please try again.');
      }
      
      await _firestore.collection('users').doc(currentUser.uid).update({
        'is2FAEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      throw Exception('Failed to disable 2FA: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Cancel 2FA process during login
  Future<void> cancel2FA() async {
    _is2FAPending = false;
    await signOut();
  }

  // Verify 2FA Authenticator code during login
  Future<void> verify2FACTOTPCode(String code) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    
    final secret = totpSecret;
    if (secret.isEmpty) throw Exception('2FA is not configured for this account.');
    
    _setLoading(true);
    try {
      final isValid = TOTP.verifyCode(secret, code);
      if (!isValid) {
        throw Exception('Invalid 6-digit code. Please try again.');
      }
      
      // Success! Clear the pending 2FA state
      _is2FAPending = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Setup 2FA: Verify the setup code, and if valid, enable 2FA and save the secret in Firestore
  Future<void> setup2FA({
    required String secret,
    required String code,
  }) async {
    final currentUser = _user;
    if (currentUser == null) throw Exception('No user signed in.');
    
    _setLoading(true);
    try {
      final isValid = TOTP.verifyCode(secret, code);
      if (!isValid) {
        throw Exception('Invalid 6-digit code. Please check your authenticator app and try again.');
      }
      
      // Save secret and enable 2FA in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'totpSecret': secret,
        'is2FAEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
