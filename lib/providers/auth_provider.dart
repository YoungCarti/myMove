import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Authentication methods will be implemented in Sprint 3
  Future<bool> signIn(String email, String password) async {
    // TODO: Implement in Sprint 3
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    // TODO: Implement in Sprint 3
    return false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
