import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/parking_location.dart';
import 'booking_checkout_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final ParkingLocation location;
  final String? initialCalculatedDistance;

  const BookingDetailScreen({
    super.key,
    required this.location,
    this.initialCalculatedDistance,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _calculatedDistance;

  @override
  void initState() {
    super.initState();
    _calculatedDistance = widget.initialCalculatedDistance;
    if (_calculatedDistance == null) {
      _calculateDistance();
    }
  }

  Future<void> _calculateDistance() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.location.latitude,
        widget.location.longitude,
      );
      
      if (mounted) {
        setState(() {
          if (distanceInMeters < 1000) {
            _calculatedDistance = '${distanceInMeters.toStringAsFixed(0)} m away';
          } else {
            _calculatedDistance = '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
          }
        });
      }
    } catch (e) {
      // Fallback to static value if error occurs
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildErrorImage() {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child: Icon(Icons.business, color: Colors.white54, size: 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = 350.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ─── Fixed Parallax Image ───
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              double offset = 0;
              if (_scrollController.hasClients) {
                offset = _scrollController.offset;
              }
              // Prevent image from moving down when bouncing at top
              if (offset < 0) offset = 0;
              
              return Positioned(
                top: -offset * 0.5,
                left: 0,
                right: 0,
                height: headerHeight,
                child: child!,
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.location.imageUrl.startsWith('assets/')
                    ? Image.asset(
                        widget.location.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      )
                    : Image.network(
                        widget.location.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      ),
                // Gradient overlay to make back button visible initially
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        const Color(0xFF121212).withValues(alpha: 0.8), // Blend into background
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ─── Scrollable Content ───
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Transparent spacer to reveal the image
              SliverToBoxAdapter(
                child: SizedBox(height: headerHeight - 40), // 40px overlap for rounded corners
              ),
              // Details Content
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedBuilder(
                                  animation: _scrollController,
                                  builder: (context, child) {
                                    double offset = 0;
                                    if (_scrollController.hasClients) {
                                      offset = _scrollController.offset;
                                    }
                                    double fadeStart = headerHeight - 120;
                                    double fadeEnd = headerHeight - 60;
                                    double opacity = 1.0 - ((offset - fadeStart) / (fadeEnd - fadeStart));
                                    
                                    return Opacity(
                                      opacity: opacity.clamp(0.0, 1.0),
                                      child: child,
                                    );
                                  },
                                  child: Text(
                                    widget.location.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.location.address,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border_rounded, color: Colors.blueAccent),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _calculatedDistance ?? '${widget.location.distanceKm} km away',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              widget.location.operatingHours,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                            const SizedBox(width: 12),
                            const Icon(Icons.local_parking_rounded, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              widget.location.parkingType,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RM${widget.location.pricePerHour.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(
                              'per hour',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.location.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      
                      // Extra space at bottom so we can scroll past the fixed buttons
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // ─── Custom App Bar ───
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              double offset = 0;
              if (_scrollController.hasClients) {
                offset = _scrollController.offset;
              }
              // Calculate opacity for the solid background and title
              double fadeStart = headerHeight - 120;
              double fadeEnd = headerHeight - 60;
              double opacity = (offset - fadeStart) / (fadeEnd - fadeStart);
              opacity = opacity.clamp(0.0, 1.0);
              
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: opacity),
                    boxShadow: opacity > 0.5 
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2 * opacity), blurRadius: 10)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: opacity > 0.8 ? 1.0 : 0.0,
                            child: Text(
                              widget.location.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance for back button
                    ],
                  ),
                ),
              );
            },
          ),
          
          // ─── Fixed Bottom Action Buttons ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom > 0 
                  ? MediaQuery.of(context).padding.bottom + 8 
                  : 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingCheckoutScreen(
                              location: widget.location,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Continue',
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
          ),
        ],
      ),
    );
  }
}
