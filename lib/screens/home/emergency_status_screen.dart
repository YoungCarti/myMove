import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class EmergencyStatusScreen extends StatefulWidget {
  const EmergencyStatusScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyStatusScreen> createState() => _EmergencyStatusScreenState();
}

class _EmergencyStatusScreenState extends State<EmergencyStatusScreen> {
  StreamSubscription<QuerySnapshot>? _emergencySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToEmergencyStatus();
    });
  }

  void _listenToEmergencyStatus() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    
    _emergencySubscription = FirebaseFirestore.instance
        .collection('emergencies')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          // If the emergency is resolved, return to home
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _emergencySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 32),
              // Text
              const Text(
                'SOS Alert Sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Security and Management have been notified. Help is on the way.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionCard(
                    context: context,
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(
                            targetUserId: 'security_management',
                            isEmergency: true,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.phone_in_talk_rounded,
                    label: 'Call',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/call');
                    },
                  ),
                ],
              ),
              const Spacer(),
              // Back to home
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Return to Home',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
