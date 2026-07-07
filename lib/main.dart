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
import 'services/notification_service.dart';
import 'screens/calling/call_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
  await NotificationService().initialize();
  await NotificationService().showNotification(message);
}

class _ForegroundMessageHandler extends StatefulWidget {
  final Widget child;

  const _ForegroundMessageHandler({required this.child});

  @override
  State<_ForegroundMessageHandler> createState() => _ForegroundMessageHandlerState();
}

class _ForegroundMessageHandlerState extends State<_ForegroundMessageHandler> {
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      if (!mounted || context.read<AuthProvider>().user == null) return;
      
      await NotificationService().showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted || context.read<AuthProvider>().user == null) return;
      if (message.data['type'] == 'incoming_call') {
        final channelName = message.data['channelName'] ?? '';
        final callerName = message.data['callerName'] ?? 'Caller';
        final token = message.data['token'];
        if (channelName.isNotEmpty && navigatorKey.currentContext != null) {
          Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelName: channelName,
                callerName: callerName,
                token: token,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_51QZYHFKiRHuR0U9EvLKIsidLrTBRtl4ZkVT7V4PUb8ow0GJLvLhtjKtSnXuMGeeFFJk9a3rTNDpfCA6h8YonsiWk00XPsyq7do';
  await Stripe.instance.applySettings();

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
    await NotificationService().initialize();
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
