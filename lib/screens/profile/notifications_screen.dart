import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Don't Miss a Thing",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Turn on push notifications to keep up with your active bookings and vehicle reminders.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        // TODO: request notification permissions via requestNotificationPermissions()
                      },
                      child: const Text(
                        "Enable Notifications",
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
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
      color: Colors.white.withOpacity(0.08),
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
