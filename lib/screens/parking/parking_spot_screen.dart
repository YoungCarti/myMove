import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../booking/booking_success_screen.dart';

class ParkingSpotScreen extends StatefulWidget {
  final String bookingId;
  final String locationName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;

  const ParkingSpotScreen({
    super.key,
    required this.bookingId,
    required this.locationName,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
  });

  @override
  State<ParkingSpotScreen> createState() => _ParkingSpotScreenState();
}

class _ParkingSpotScreenState extends State<ParkingSpotScreen> {
  String? _selectedSpot;
  bool _isSaving = false;

  // Mock parking spots layout
  final List<String> leftColumn = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'];
  final List<String> rightColumn = ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7'];
  final List<String> occupiedSpots = ['A2', 'B1', 'B4', 'A5']; // Mock occupied

  Future<void> _confirmSpot() async {
    if (_selectedSpot == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'spotId': _selectedSpot});

      if (mounted) {
        // Use pushReplacement so user can't go back to spot selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              bookingId: widget.bookingId,
              locationName: widget.locationName,
              startDateTime: widget.startDateTime,
              endDateTime: widget.endDateTime,
              price: widget.price,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving spot: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSpot(String spotId) {
    bool isOccupied = occupiedSpots.contains(spotId);
    bool isSelected = _selectedSpot == spotId;

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () {
              setState(() {
                _selectedSpot = spotId;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isOccupied
              ? Colors.white.withOpacity(0.05)
              : isSelected
                  ? Colors.blueAccent
                  : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car,
                color: isOccupied
                    ? Colors.white.withOpacity(0.15)
                    : isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                spotId,
                style: TextStyle(
                  color: isOccupied
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Choose Parking Spot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(Colors.blueAccent, 'Selected'),
                  _buildLegendItem(const Color(0xFF2C2C2E), 'Available'),
                  _buildLegendItem(Colors.white.withOpacity(0.05), 'Occupied'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    // Left Column
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: leftColumn.length,
                        itemBuilder: (context, index) {
                          return _buildSpot(leftColumn[index]);
                        },
                      ),
                    ),
                    // Center Road
                    Container(
                      width: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.white.withOpacity(0.1), width: 2),
                          right: BorderSide(color: Colors.white.withOpacity(0.1), width: 2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          12,
                          (index) => Container(
                            width: 2,
                            height: 16,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    // Right Column
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: rightColumn.length,
                        itemBuilder: (context, index) {
                          return _buildSpot(rightColumn[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedSpot == null || _isSaving) ? null : _confirmSpot,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.white.withOpacity(0.1),
                    disabledForegroundColor: Colors.white.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Spot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}