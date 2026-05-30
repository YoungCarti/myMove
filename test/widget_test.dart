import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_move/app.dart';
import 'package:my_move/providers/auth_provider.dart' as app_auth;
import 'package:my_move/providers/parking_provider.dart';
import 'package:my_move/providers/booking_provider.dart';
import 'package:my_move/screens/auth/onboarding_screen.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = MockFirebaseFirestore();

    // Stub authStateChanges to emit a null user (unauthenticated)
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream<User?>.value(null));

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => app_auth.AuthProvider(
              auth: mockAuth,
              firestore: mockFirestore,
            ),
          ),
          ChangeNotifierProvider(create: (_) => ParkingProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
        ],
        child: const MyMoveApp(),
      ),
    );

    // The SplashScreen uses Future.delayed + AnimationController + another
    // Future.delayed. Pump many small frames over ~7s to reliably advance
    // past all timers and animation ticks.
    for (int i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Assert that the app rendered the OnboardingScreen and its content
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
  });
}
