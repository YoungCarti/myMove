import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/parking_location.dart';
import 'booking_detail_screen.dart';

class LandmarkCard extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String?) onBook;
  final ParkingLocation location;

  const LandmarkCard({
    super.key,
    required this.onCancel,
    required this.onBook,
    required this.location,
  });

  static void show(BuildContext context, ParkingLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LandmarkCard(
        location: location,
        onCancel: () => Navigator.of(context).pop(),
        onBook: (String? calculatedDistance) {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(
                location: location,
                initialCalculatedDistance: calculatedDistance,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  State<LandmarkCard> createState() => _LandmarkCardState();
}

class _LandmarkCardState extends State<LandmarkCard> {
  bool _isLoading = false;

  Future<void> _handleBook() async {
    setState(() {
      _isLoading = true;
    });

    String? calculatedDistance;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          double distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.location.latitude,
            widget.location.longitude,
          );
          if (distanceInMeters < 1000) {
            calculatedDistance = '${distanceInMeters.toStringAsFixed(0)} m away';
          } else {
            calculatedDistance = '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
          }
        }
      }
    } catch (e) {
      // Ignore errors, fallback to null
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      widget.onBook(calculatedDistance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final location = widget.location;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 16 : 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Center(
              child: Text(
                'Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: location.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      location.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.business, color: Colors.white54, size: 48),
                      ),
                    )
                  : Image.network(
                      location.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.business, color: Colors.white54, size: 48),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border_rounded, color: Colors.blueAccent),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleBook,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Book Parking',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
