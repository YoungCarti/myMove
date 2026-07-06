import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import '../app.dart';
import '../screens/calling/call_screen.dart';
import '../screens/calling/incoming_call_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('notificationTapBackground: ${notificationResponse.actionId}');
  if (notificationResponse.actionId == 'answer_call') {
    // If the app was not running, flutter_local_notifications brings it to foreground
    // because we will set showsUserInterface: true on the Answer action.
  } else if (notificationResponse.actionId == 'decline_call') {
    debugPrint('Call declined from background');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}, actionId: ${response.actionId}');
        if (response.payload != null) {
          try {
            if (response.actionId == 'answer_call') {
              if (response.payload != null) {
                _navigateToCallScreen(response.payload!, forceAnswer: true);
              }
              return;
            }
            if (response.actionId == 'decline_call') {
              debugPrint('Call declined in foreground');
              // Optionally stop any ringing here
              return;
            }
            // Using a simple check string because payload can just be a stringified map
            if (response.payload!.contains('incoming_call')) {
              _navigateToCallScreen(response.payload!);
            }
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create a high-importance channel for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } else if (message.data.isNotEmpty) {
      // Handle data-only messages to show local notification
      final title = message.data['title'] ?? 'myMove update';
      final body = message.data['body'] ?? 'You have a new message.';
      final isCall = message.data['type'] == 'incoming_call';
      
      final actions = isCall 
        ? <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'answer_call',
              'Answer',
              titleColor: Colors.green,
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'decline_call',
              'Decline',
              titleColor: Colors.red,
            ),
          ]
        : null;

      await _localNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            actions: actions,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
    
    // Automatically navigate if foreground call
    if (message.data['type'] == 'incoming_call') {
      _navigateToCallScreen(jsonEncode(message.data), messageData: message.data);
    }
  }

  void _navigateToCallScreen(String payload, {Map<String, dynamic>? messageData, int retryCount = 0, bool forceAnswer = false}) {
    if (navigatorKey.currentContext == null) {
      if (retryCount < 5) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToCallScreen(payload, messageData: messageData, retryCount: retryCount + 1, forceAnswer: forceAnswer);
        });
      }
      return;
    }
    
    String channelName = '';
    String callerName = '';
    String? token;
    
    if (messageData != null) {
      channelName = messageData['channelName'] ?? '';
      callerName = messageData['callerName'] ?? 'Caller';
      token = messageData['token'];
    } else {
      try {
        final decoded = jsonDecode(payload);
        channelName = decoded['channelName'] ?? '';
        callerName = decoded['callerName'] ?? 'Caller';
        token = decoded['token'];
      } catch (e) {
        // Fallback for old string payloads if any
        RegExp channelReg = RegExp(r'channelName: ([^,}]+)');
        RegExp callerReg = RegExp(r'callerName: ([^,}]+)');
        RegExp tokenReg = RegExp(r'token: ([^,}]+)');
        
        final channelMatch = channelReg.firstMatch(payload);
        final callerMatch = callerReg.firstMatch(payload);
        final tokenMatch = tokenReg.firstMatch(payload);
        
        if (channelMatch != null) channelName = channelMatch.group(1)?.trim() ?? '';
        if (callerMatch != null) callerName = callerMatch.group(1)?.trim() ?? 'Caller';
        if (tokenMatch != null) token = tokenMatch.group(1)?.trim();
      }
    }

    if (channelName.isNotEmpty) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => forceAnswer 
            ? CallScreen(
                channelName: channelName,
                callerName: callerName,
                token: token,
              )
            : IncomingCallScreen(
                channelName: channelName,
                callerName: callerName,
                token: token,
              ),
        ),
      );
    }
  }

  Future<void> showEmergencyNotification() async {
    if (!_isInitialized) await initialize();
    const int emergencyNotificationId = 911;
    
    await _localNotificationsPlugin.show(
      emergencyNotificationId,
      'Emergency SOS Active',
      'Security has been notified. Help is on the way.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Notifications',
          channelDescription: 'Ongoing emergency alerts.',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }

  Future<void> cancelEmergencyNotification() async {
    const int emergencyNotificationId = 911;
    await _localNotificationsPlugin.cancel(emergencyNotificationId);
  }
}
