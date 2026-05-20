import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/parking_provider.dart';
import 'providers/booking_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with dummy options to bypass startup crash when config is missing
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "dummy-api-key-for-local-run",
        appId: "1:1234567890:android:1234567890",
        messagingSenderId: "1234567890",
        projectId: "mymove-dummy",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const MyMoveApp(),
    ),
  );
}