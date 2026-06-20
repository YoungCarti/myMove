import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isGranted = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Banner Card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isGranted ? const Color(0xFF1B3B22) : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _isGranted ? Icons.notifications_active : Icons.notifications_off,
                        color: _isGranted ? const Color(0xFF32D74B) : Colors.white54,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isGranted ? "You're All Set!" : "Don't Miss a Thing",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGranted 
                          ? "Push notifications are enabled. You'll receive updates for your bookings."
                          : "Turn on push notifications to keep up with your active bookings and vehicle reminders.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        if (_isGranted) {
                          openAppSettings();
                          return;
                        }
                        
                        final status = await Permission.notification.request();
                        if (status.isGranted) {
                          await _checkPermission();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifications enabled!')),
                            );
                          }
                        } else if (status.isPermanentlyDenied) {
                          openAppSettings();
                        }
                      },
                      child: Text(
                        _isGranted ? "Manage Settings" : "Enable Notifications",
                        style: TextStyle(
                          color: _isGranted ? Colors.white70 : const Color(0xFF0A84FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Booking & Parking ───────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'Booking & Parking',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      title: 'Active Bookings',
                      subtitle: 'Email, Push',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNotificationTile(
                      title: 'Parking Expiry Reminders',
                      subtitle: 'Email, Push, SMS',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNotificationTile(
                      title: 'Booking Confirmations',
                      subtitle: 'Email',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Vehicles & Account ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'Vehicles & Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      title: 'Registration Expiry',
                      subtitle: 'Email, Push',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNotificationTile(
                      title: 'Security Alerts',
                      subtitle: 'Email, Push',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNotificationTile(
                      title: 'Payment Receipts',
                      subtitle: 'Email',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Promotions & Updates ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'Promotions & Updates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      title: 'New Parking Spots',
                      subtitle: 'Push',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNotificationTile(
                      title: 'App Updates & News',
                      subtitle: 'Email',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.08),
      height: 1,
      indent: 16,
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 24,
          ),
        ],
      ),
    );
  }
}
