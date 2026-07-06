import 'package:flutter/material.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String channelName;
  final String callerName;
  final String? callerAvatarUrl;
  final String? token;

  const IncomingCallScreen({
    Key? key,
    required this.channelName,
    required this.callerName,
    this.callerAvatarUrl,
    this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark mode background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              'Incoming Call',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C2C2E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipOval(
                  child: callerAvatarUrl != null && callerAvatarUrl!.isNotEmpty
                      ? Image.network(
                          callerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 60, color: Colors.white54),
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "myMove VoIP Audio...",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0, left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Decline the call
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Decline",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      )
                    ],
                  ),
                  
                  // Accept Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Accept the call and navigate to CallScreen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => CallScreen(
                                channelName: channelName,
                                callerName: callerName,
                                callerAvatarUrl: callerAvatarUrl,
                                token: token,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Accept",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
