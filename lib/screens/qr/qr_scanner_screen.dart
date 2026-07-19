import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../qr/qr_display_screen.dart';
import '../chat/chat_screen.dart';
import '../../config/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      
      // Stop scanner and process
      _scannerController.stop();
      
      if (code.startsWith('mymove://user/') || code.startsWith('https://mymove-cb624.web.app/scan?id=')) {
        String targetUserId = '';
        if (code.startsWith('mymove://user/')) {
          targetUserId = code.substring('mymove://user/'.length).trim();
        } else {
          targetUserId = code.substring('https://mymove-cb624.web.app/scan?id='.length).trim();
        }
        
        if (targetUserId.isEmpty || targetUserId.contains('/')) {
          _showError('Invalid QR code format.');
          if (mounted) {
            setState(() => _isProcessing = false);
            _scannerController.start();
          }
          return;
        }

        try {
          final vehicleDoc = await FirebaseFirestore.instance.collection('publicVehicles').doc(targetUserId).get();
          final vehicleData = vehicleDoc.data();
          if (!vehicleDoc.exists || vehicleData?['isActive'] != true) {
            _showError('Vehicle not found or inactive.');
            if (mounted) {
              setState(() => _isProcessing = false);
              _scannerController.start();
            }
            return;
          }

          if (mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(targetUserId: targetUserId),
              ),
            );
          }
        } catch (e) {
          _showError('Error validating QR code.');
          if (mounted) {
            setState(() => _isProcessing = false);
            _scannerController.start();
          }
        }
        return;
      }
      
      // For now, just show a dialog with the scanned value
      // Future integration: Check if it's a valid vehicle QR code
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('QR Code Scanned', style: TextStyle(color: Colors.white)),
          content: Text(
            code,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ─── Camera Preview ─────────────────────────────────────────
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // ─── Custom Dark Overlay with Cutout ─────────────────────────
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: _ScannerOverlayPainter(),
          ),

          // ─── Top Header Elements ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // App Bar Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const Text(
                          'Scan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Title above scanner
                    const Center(
                      child: Text(
                        'Scan Barcode or QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Actions below scanner ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + (MediaQuery.of(context).size.width * 0.65) / 2 - 40 + 32, // 32px below cutout
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Flashlight Button
                GestureDetector(
                  onTap: () {
                    _scannerController.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                      color: _isTorchOn ? Colors.yellow : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Bottom Action Elements ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ─── Segmented Control (Scan vs My QR) ────────────────────
                    Center(
                      child: Container(
                        height: 48,
                        width: MediaQuery.of(context).size.width * 0.85,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Scan',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  // Navigate to My QR Display Screen
                                  _scannerController.stop();
                                  await Navigator.pushNamed(context, AppRoutes.qrDisplay);
                                  if (mounted) _scannerController.start();
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: const Center(
                                    child: Text(
                                      'My QR',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Bottom Info Text ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan a vehicle\'s QR code',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Anonymously contact the owner if you are blocked.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw the semi-transparent overlay with a clear cutout
/// and the blue scanning corners.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Determine the cutout size and position
    final double cutoutWidth = size.width * 0.65;
    final double cutoutHeight = cutoutWidth;
    final double cutoutX = (size.width - cutoutWidth) / 2;
    // Align cutout slightly above center
    final double cutoutY = (size.height - cutoutHeight) / 2 - 40;
    
    final RRect cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutX, cutoutY, cutoutWidth, cutoutHeight),
      const Radius.circular(12),
    );

    // Draw the dark background overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    // Create path for the whole screen
    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create path for the cutout
    final Path cutoutPath = Path()..addRRect(cutoutRect);
    
    // Fill background using even-odd fill type to create the hole
    final Path overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw the blue corners
    final Paint cornerPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(Offset(cutoutX, cutoutY + cornerLength), Offset(cutoutX, cutoutY), cornerPaint);
    canvas.drawLine(Offset(cutoutX, cutoutY), Offset(cutoutX + cornerLength, cutoutY), cornerPaint);
    
    // Top Right
    canvas.drawLine(Offset(cutoutX + cutoutWidth - cornerLength, cutoutY), Offset(cutoutX + cutoutWidth, cutoutY), cornerPaint);
    canvas.drawLine(Offset(cutoutX + cutoutWidth, cutoutY), Offset(cutoutX + cutoutWidth, cutoutY + cornerLength), cornerPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(cutoutX, cutoutY + cutoutHeight - cornerLength), Offset(cutoutX, cutoutY + cutoutHeight), cornerPaint);
    canvas.drawLine(Offset(cutoutX, cutoutY + cutoutHeight), Offset(cutoutX + cornerLength, cutoutY + cutoutHeight), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(cutoutX + cutoutWidth - cornerLength, cutoutY + cutoutHeight), Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight), cornerPaint);
    canvas.drawLine(Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight), Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
