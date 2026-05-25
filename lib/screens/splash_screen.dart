import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onTimeout;

  const SplashScreen({
    super.key,
    required this.onTimeout,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawController;
  late CurvedAnimation _progressAnim;

  @override
  void initState() {
    super.initState();

    // Drawing animation duration (similar to a Disney-style logo draw)
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnim = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutSine,
    );

    // Start drawing after a short initial delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _drawController.forward();
    });

    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait 2 seconds after drawing finishes, then navigate to onboarding
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onTimeout();
        });
      }
    });
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF071635), // Top
              Color(0xFF0E2A69), // Bottom
            ],
            stops: [0.0, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _drawController,
            builder: (context, child) {
              final progress = _progressAnim.value;

              return ClipRect(
                clipper: _RevealClipper(progress),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    'myMove',
                    style: TextStyle(
                      fontFamily: 'Cattalague',
                      fontSize: 40,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.white30,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  final double progress;

  _RevealClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // We allow a generous vertical overflow (top: -100, height: size.height + 200)
    // so cursive ascenders and descenders (like the bottom of 'y') are NEVER chopped off.
    // We only clip horizontally to create the left-to-right reveal.
    return Rect.fromLTWH(0, -100, size.width * progress, size.height + 200);
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
