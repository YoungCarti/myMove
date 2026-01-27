import 'package:flutter/material.dart';

class QRDisplayScreen extends StatelessWidget {
  const QRDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: const Center(
        child: Text('QR Display Screen - To be implemented'),
      ),
    );
  }
}