import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  bool _isLocationEnabled = false;
  bool _isCameraEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    if (mounted) {
      setState(() {
        _isLocationEnabled = locationStatus.isGranted || locationStatus.isLimited;
        _isCameraEnabled = cameraStatus.isGranted || cameraStatus.isLimited;
      });
    }
  }

  Future<void> _handlePermissionRequest(Permission permission, bool isSwitchEnabled) async {
    final status = await permission.status;
    
    if (status.isPermanentlyDenied || (!isSwitchEnabled && status.isGranted)) {
      // If permanently denied, or user wants to revoke, they must go to settings
      await openAppSettings();
    } else if (isSwitchEnabled && !status.isGranted) {
      final newStatus = await permission.request();
      if (newStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
    await _checkPermissions();
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
          'Permissions',
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
              // ─── Location Access ──────────────────────────────────────────
              _buildPermissionBlock(
                title: 'Location Access',
                description:
                    'View parking spots near you and get better location suggestions when creating bookings.',
                hasSwitch: true,
                switchValue: _isLocationEnabled,
                onSwitchChanged: (value) async {
                  await _handlePermissionRequest(Permission.locationWhenInUse, value);
                },
              ),
              
              const SizedBox(height: 24),

              // ─── Camera Access ────────────────────────────────────────────
              _buildPermissionBlock(
                title: 'Allow Camera Access',
                description:
                    'Scan QR codes for parking access or take photos for your profile picture.',
                leadingIcon: Icons.camera_alt_outlined,
                hasSwitch: true,
                switchValue: _isCameraEnabled,
                onSwitchChanged: (value) async {
                  await _handlePermissionRequest(Permission.camera, value);
                },
                onTap: () async {
                  await _handlePermissionRequest(Permission.camera, !_isCameraEnabled);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBlock({
    required String title,
    required String description,
    IconData? leadingIcon,
    bool hasSwitch = false,
    bool? switchValue,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasSwitch)
                  SizedBox(
                    height: 24,
                    child: CupertinoSwitch(
                      value: switchValue ?? false,
                      onChanged: onSwitchChanged,
                      activeTrackColor: const Color(0xFF32D74B),
                      inactiveTrackColor: const Color(0xFF3A3A3C),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
