import 'package:flutter/material.dart';

class ActiveBookingScreen extends StatelessWidget {
  const ActiveBookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Booking')),
      body: const Center(
        child: Text('Active Booking Screen - To be implemented'),
      ),
    );
  }
}