import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../landmark/landmark_card.dart';
import '../../models/parking_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(3.0186971028116116, 101.43081077040469); // Kuala Lumpur default
  int _selectedIndex = 0;
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;

  Set<Marker> _markers = {};
  List<ParkingLocation> _allLocations = [];
  List<ParkingLocation> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadParkingMarker();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allLocations.where((location) {
        return location.name.toLowerCase().contains(lowercaseQuery) || 
               location.address.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  Future<BitmapDescriptor> _createParkingMarkerIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 100.0;
    const double height = 140.0;

    // Background color (Original Google Maps Red)
    final Paint paint = Paint()..color = const Color(0xFFEA4335);

    // Draw the pin shape (Circle + Triangle for the pointy bottom)
    final Path circlePath = Path();
    circlePath.addOval(const Rect.fromLTWH(0, 0, width, width));
    
    final Path pointerPath = Path();
    pointerPath.moveTo(width * 0.15, width * 0.75);
    pointerPath.lineTo(width / 2, height); // Bottom point
    pointerPath.lineTo(width * 0.85, width * 0.75);
    pointerPath.close();

    canvas.drawPath(circlePath, paint);
    canvas.drawPath(pointerPath, paint);

    // 'P' text
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'P',
      style: TextStyle(
        fontSize: 55.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    
    // Position text in the center of the top circular part
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (width / 2) - (textPainter.height / 2)),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadParkingMarker() async {
    final BitmapDescriptor customIcon = await _createParkingMarkerIcon();
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('parking_locations').get();
      
      if (mounted) {
        setState(() {
          _markers.clear();
          _allLocations.clear();
          for (var doc in snapshot.docs) {
            final location = ParkingLocation.fromFirestore(doc);
            _allLocations.add(location);
            _markers.add(
              Marker(
                markerId: MarkerId(location.id),
                position: LatLng(location.latitude, location.longitude),
                icon: customIcon,
                onTap: () {
                  LandmarkCard.show(context, location);
                },
              ),
            );
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading markers: $e");
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Automatically go to current location when the map is ready
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.displayName ?? 'myMove User';
    final bool isSearching = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ─── Full Screen Map ─────────────────────────────────────────────
          if (defaultTargetPlatform == TargetPlatform.android)
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: (LatLng position) {
                FocusScope.of(context).unfocus();
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              mapType: MapType.hybrid,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
            )
          else
            const Center(
              child: Text(
                'Map is only supported on Android.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          
          // ─── Header Overlay ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ─── Profile Picture or Back Button ───
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: isSearching
                          ? GestureDetector(
                              key: const ValueKey('back_btn'),
                              onTap: () {
                                _searchFocusNode.unfocus();
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('profile_btn'),
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                  image: user?.photoURL != null && user!.photoURL!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(user.photoURL!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                                    ? null
                                    : Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // ─── Search Bar ───
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search parking spot...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // ─── Settings Gear ───
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: isSearching
                          ? const SizedBox(key: ValueKey('hidden_settings'))
                          : GestureDetector(
                              key: const ValueKey('visible_settings'),
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.local_parking_rounded, color: Colors.blueAccent),
                          title: Text(location.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            location.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                          onTap: () {
                            _searchFocusNode.unfocus();
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                            });
                            mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(location.latitude, location.longitude),
                                16.0,
                              ),
                            );
                            LandmarkCard.show(context, location);
                          },
                        );
                      },
                    ),
                  ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
          
          // ─── Landmark Card ───────────────────────────────────────────────
          // LandmarkCard is now shown via showModalBottomSheet
        ],
      ),
      
      // ─── Bottom Navigation Bar ───────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white.withValues(alpha: 0.4),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    
                    if (index == 1) {
                      // TODO: Update route for Booking if needed
                      Navigator.pushNamed(context, AppRoutes.searchParking).then((_) {
                        if (mounted) setState(() => _selectedIndex = 0);
                      });
                    } else if (index == 2) {
                      // TODO: Update route for QR Code if needed
                      Navigator.pushNamed(context, AppRoutes.editProfile).then((_) {
                        if (mounted) setState(() => _selectedIndex = 0);
                      });
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Icon(Icons.map_rounded),
                      ),
                      label: 'Map',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Icon(Icons.calendar_month_rounded),
                      ),
                      label: 'Booking',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Icon(Icons.qr_code_2_rounded),
                      ),
                      label: 'QR Code',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: defaultTargetPlatform == TargetPlatform.android
          ? FloatingActionButton(
              onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
              backgroundColor: const Color(0xFF1C1C1E),
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }
}