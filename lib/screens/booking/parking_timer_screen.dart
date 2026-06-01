import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'extend_parking_screen.dart';

class ParkingTimerScreen extends StatefulWidget {
  final String bookingId;
  final String locationName;
  final String locationAddress;
  final String vehicleMake;
  final String vehiclePlate;
  final String spotId;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const ParkingTimerScreen({
    super.key,
    required this.bookingId,
    required this.locationName,
    required this.locationAddress,
    required this.vehicleMake,
    required this.vehiclePlate,
    required this.spotId,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  State<ParkingTimerScreen> createState() => _ParkingTimerScreenState();
}

class _ParkingTimerScreenState extends State<ParkingTimerScreen> {
  late Timer _timer;
  late Duration _remainingTime;
  late DateTime _endDateTime;

  @override
  void initState() {
    super.initState();
    _endDateTime = widget.endDateTime;
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    if (now.isAfter(_endDateTime)) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer.cancel();
    } else {
      setState(() {
        _remainingTime = _endDateTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = _endDateTime.difference(widget.startDateTime);
    final progress = _remainingTime.inSeconds > 0 
        ? 1.0 - (_remainingTime.inSeconds / totalDuration.inSeconds)
        : 1.0;

    final durationHours = totalDuration.inMinutes / 60.0;
    String durationText = durationHours == durationHours.roundToDouble()
        ? '${durationHours.toInt()} hours'
        : '${durationHours.toStringAsFixed(1)} hours';

    final vehicleInfo = widget.vehicleMake.isNotEmpty && widget.vehiclePlate.isNotEmpty
        ? '${widget.vehicleMake} (${widget.vehiclePlate})'
        : (widget.vehiclePlate.isNotEmpty ? widget.vehiclePlate : 'N/A');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Circular Timer
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 20,
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                          color: Colors.blueAccent,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            _formatDuration(_remainingTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Parking Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Parking Area', widget.locationName),
                      const SizedBox(height: 16),
                      _buildDetailRow('Address', widget.locationAddress.isNotEmpty ? widget.locationAddress : 'N/A'),
                      const SizedBox(height: 16),
                      _buildDetailRow('Vehicle', vehicleInfo),
                      const SizedBox(height: 16),
                      _buildDetailRow('Parking Spot', widget.spotId),
                      const SizedBox(height: 16),
                      _buildDetailRow('Date', DateFormat('d MMMM yyyy').format(widget.startDateTime)),
                      const SizedBox(height: 16),
                      _buildDetailRow('Duration', durationText),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Hours', 
                        '${DateFormat('h:mm a').format(widget.startDateTime).toLowerCase()} - ${DateFormat('h:mm a').format(_endDateTime).toLowerCase()}'
                      ),
                      const Divider(color: Colors.white10, height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExtendParkingScreen(
                                  bookingId: widget.bookingId,
                                  currentEndDateTime: _endDateTime,
                                ),
                              ),
                            );
                            
                            if (result != null && result is DateTime) {
                              setState(() {
                                _endDateTime = result;
                              });
                              _calculateRemainingTime();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Extend Parking Time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
               color: Colors.white,
               fontSize: 15,
               fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
