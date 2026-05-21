import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_move/app.dart';
import 'package:my_move/providers/auth_provider.dart';
import 'package:my_move/providers/parking_provider.dart';
import 'package:my_move/providers/booking_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ParkingProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
        ],
        child: const MyMoveApp(),
      ),
    );
  });
}
