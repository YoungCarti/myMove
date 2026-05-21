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
  
  // Initialize Firebase with the real options for our project
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDRoILWxGX52GV5gsemBagyqTInF6xam6k",
        appId: "1:340854856075:android:66f561a609df1b99e2778e",
        messagingSenderId: "340854856075",
        projectId: "mymove-cb624",
        storageBucket: "mymove-cb624.firebasestorage.app",
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