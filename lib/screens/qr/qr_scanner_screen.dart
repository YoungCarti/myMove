import 'package:flutter/material.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: const Center(
        child: Text('QR Scanner Screen - To be implemented'),
      ),
    );
  }
}