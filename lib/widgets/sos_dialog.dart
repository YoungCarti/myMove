import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'dart:async';

class SOSDialog extends StatefulWidget {
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  const SOSDialog({
    Key? key,
    required this.onCancel,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<SOSDialog> createState() => _SOSDialogState();
}

class _SOSDialogState extends State<SOSDialog> {
  int _counter = 5;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _vibrate();
    _startTimer();
  }

  void _vibrate() async {
    bool canVibrate = await Vibrate.canVibrate;
    if (canVibrate) {
      Vibrate.vibrate();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 1) {
        setState(() {
          _counter--;
        });
        _vibrate();
      } else {
        _timer?.cancel();
        _handleConfirm();
      }
    });
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey.shade200,
              height: 1.0,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'SOS',
            style: TextStyle(
              color: Color(0xFF2E1B4D), // Dark purple
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: SafeArea(
          child: _buildCountdownScreen(),
        ),
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Slide to cancel',
            style: TextStyle(
              color: Color(0xFF2E1B4D),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'After 5 seconds, your SOS and location\nwill be sent to your Circle and emergency contacts.',
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          _isProcessing
              ? const Column(
                  children: [
                    SizedBox(height: 30),
                    CircularProgressIndicator(color: Color(0xFFFF6B6B)),
                    SizedBox(height: 20),
                    Text(
                      'Acquiring location...',
                      style: TextStyle(color: Color(0xFF2E1B4D), fontSize: 18),
                    ),
                  ],
                )
              : Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6B6B),
                  ),
                  child: Center(
                    child: Text(
                      '$_counter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          const Spacer(),
          if (!_isProcessing)
            _SlideToCancel(
              onCancel: () {
                _timer?.cancel();
                Navigator.of(context).pop();
                widget.onCancel();
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SlideToCancel extends StatefulWidget {
  final VoidCallback onCancel;

  const _SlideToCancel({Key? key, required this.onCancel}) : super(key: key);

  @override
  State<_SlideToCancel> createState() => _SlideToCancelState();
}

class _SlideToCancelState extends State<_SlideToCancel> {
  double _dragPosition = 0.0;
  final double _thumbWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _thumbWidth;

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                left: 0,
                right: _thumbWidth,
                child: const Center(
                  child: Text(
                    'Slide to cancel SOS',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition -= details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) {
                        _dragPosition = maxDrag;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition >= maxDrag * 0.8) {
                      widget.onCancel();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _thumbWidth,
                    height: _thumbWidth,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF6B6B),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
