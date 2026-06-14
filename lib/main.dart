import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/parking_provider.dart';
import 'providers/booking_provider.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

class _ForegroundMessageHandler extends StatefulWidget {
  final Widget child;

  const _ForegroundMessageHandler({required this.child});

  @override
  State<_ForegroundMessageHandler> createState() => _ForegroundMessageHandlerState();
}

class _ForegroundMessageHandlerState extends State<_ForegroundMessageHandler> {
  StreamSubscription<RemoteMessage>? _messageSubscription;
  Timer? _hideTimer;
  RemoteMessage? _foregroundMessage;

  @override
  void initState() {
    super.initState();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted || context.read<AuthProvider>().user == null) return;

      _hideTimer?.cancel();
      setState(() => _foregroundMessage = message);
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _foregroundMessage = null);
        }
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _foregroundMessage;
    final title = message?.notification?.title ??
        message?.data['title']?.toString() ??
        'myMove notification';
    final body = message?.notification?.body ??
        message?.data['body']?.toString() ??
        'You have a new update.';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (message != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: const Color(0xFF1C1C1E),
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        body,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          _hideTimer?.cancel();
                          setState(() => _foregroundMessage = null);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Map Renderer for Android
  if (defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
      try {
        await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (e) {
        debugPrint("Map renderer initialization failed: $e");
      }
    }
  }
  
  // Initialize Firebase with the real options for our project
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Set the background messaging handler early on, as a logic basis
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const _ForegroundMessageHandler(
        child: MyMoveApp(),
      ),
    ),
  );
}
