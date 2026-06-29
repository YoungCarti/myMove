import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyCallScreen extends StatefulWidget {
  const EmergencyCallScreen({super.key});

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isConnected = false;
  String _channelName = 'Emergency Channel';
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Simulate connecting after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _pulseController.stop();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _channelName = args['channelName'] ?? 'Emergency Channel';
      _isVideo = args['isVideo'] ?? false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _call911() async {
    final Uri url = Uri(scheme: 'tel', path: '911');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              _isConnected ? '00:01' : 'Calling...',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Security & Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _channelName,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isConnected ? 1.0 : 1.0 + (_pulseController.value * 0.2),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          border: Border.all(
                            color: _isConnected ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isVideo ? Icons.videocam : Icons.person,
                          size: 80,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Text(
              'If the call is not answering,\nplease contact emergency services directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.phone_forwarded,
                  color: Colors.orange,
                  label: 'Call 911',
                  onTap: _call911,
                ),
                _buildActionButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  label: 'End Call',
                  size: 70,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildActionButton(
                  icon: _isVideo ? Icons.videocam_off : Icons.mic_off,
                  color: Colors.white24,
                  label: 'Mute',
                  onTap: () {
                    // Toggle mute
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
