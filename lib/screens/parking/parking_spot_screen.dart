import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../booking/booking_summary_screen.dart';

class ParkingSpotScreen extends StatefulWidget {
  final String bookingId;
  final String locationName;
  final String locationAddress;
  final String vehicleMake;
  final String vehiclePlate;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;
  final List<String> occupiedSpots;

  const ParkingSpotScreen({
    super.key,
    required this.bookingId,
    required this.locationName,
    required this.locationAddress,
    required this.vehicleMake,
    required this.vehiclePlate,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
    required this.occupiedSpots,
  });

  @override
  State<ParkingSpotScreen> createState() => _ParkingSpotScreenState();
}

class _ParkingSpotScreenState extends State<ParkingSpotScreen> {
  String? _selectedSpot;
  final bool _isSaving = false;
  
  // Real-time occupied spots tracker
  late Set<String> _bookedSpots;
  late Set<String> _sensorOccupiedSpots;
  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;

  // Parking spots layout (Now dynamic)
  List<String> _leftColumn = [];
  List<String> _rightColumn = [];
  Map<String, String> _slotMapping = {};
  String _rtdbPath = '/parking_status/building_A';
  bool _isLoadingLayout = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Initialize with spots occupied from Firestore/Booking data
    _bookedSpots = Set.from(widget.occupiedSpots);
    _sensorOccupiedSpots = {};
    _fetchLayout();
    _listenToConnection();
  }

  void _listenToConnection() {
    final connectedRef = FirebaseDatabase.instance.ref(".info/connected");
    _connectionSubscription = connectedRef.onValue.listen((event) {
      if (!mounted) return;
      final connected = event.snapshot.value as bool? ?? false;
      setState(() {
        _isConnected = connected;
      });
    });
  }

  Future<void> _fetchLayout() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parking_locations')
          .where('name', isEqualTo: widget.locationName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final locationDoc = snapshot.docs.first;
        final data = locationDoc.data();
        final locationId = locationDoc.id;
        
        _rtdbPath = data.containsKey('layout') 
            ? (data['layout']['rtdbPath'] ?? '/parking_status/building_A')
            : '/parking_status/building_A';

        // 1. Fetch spots from 'parkingSpots' collection
        final spotsSnapshot = await FirebaseFirestore.instance
            .collection('parkingSpots')
            .where('locationId', isEqualTo: locationId)
            .get();

        if (spotsSnapshot.docs.isNotEmpty) {
          String extractSpotName(String raw, String docId) {
            String combined = '$raw $docId'.toUpperCase();
            final match = RegExp(r'[A-Z]\d+').firstMatch(combined);
            if (match != null) {
              return match.group(0)!;
            }
            if (raw.isNotEmpty && raw.length <= 4) return raw.toUpperCase();
            return docId.substring(0, 2).toUpperCase();
          }

          List<String> allSpots = spotsSnapshot.docs.map((doc) {
            return extractSpotName(doc.data()['name']?.toString() ?? '', doc.id);
          }).toList();
          
          allSpots = allSpots.toSet().toList(); // Remove duplicates
          allSpots.sort();

          Map<String, String> newSlotMapping = {};
          List<String> aSpots = [];
          List<String> bSpots = [];

          for (var spotDoc in spotsSnapshot.docs) {
            final spotData = spotDoc.data();
            String spotId = extractSpotName(spotData['name']?.toString() ?? '', spotDoc.id);
            
            final sensorId = spotData['hardwareSensorId'];
            
            if (sensorId != null && sensorId.toString().trim().isNotEmpty) {
              newSlotMapping[sensorId.toString()] = spotId;
            }

            // Assign columns dynamically based on ID convention
            if (spotId.startsWith('A')) {
              if (!aSpots.contains(spotId)) aSpots.add(spotId);
            } else if (spotId.startsWith('B')) {
              if (!bSpots.contains(spotId)) bSpots.add(spotId);
            }
          }

          aSpots.sort();
          bSpots.sort();

          List<String> left = [];
          List<String> right = [];
          if (aSpots.isNotEmpty || bSpots.isNotEmpty) {
            left = aSpots;
            right = bSpots;
          } else {
            // Split evenly if not following A/B convention
            int half = (allSpots.length / 2).ceil();
            left = allSpots.sublist(0, half);
            right = allSpots.sublist(half);
          }

          if (!mounted) return;
          setState(() {
            _leftColumn = left;
            _rightColumn = right;
            _slotMapping = newSlotMapping;
            _isLoadingLayout = false;
          });
          _listenToRealtimeSensors();
          return;
        }

        // 2. Legacy fallback to 'layout' array (for locations built before parkingSpots)
        if (data.containsKey('layout')) {
          final layout = data['layout'];
          if (!mounted) return;
          setState(() {
            _leftColumn = List<String>.from(layout['leftColumn'] ?? []);
            _rightColumn = List<String>.from(layout['rightColumn'] ?? []);
            _slotMapping = Map<String, String>.from(layout['slotMapping'] ?? {});
            _isLoadingLayout = false;
          });
          _listenToRealtimeSensors();
          return;
        }
      }
      
      // 3. Absolute fallback
      _leftColumn = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'];
      _rightColumn = ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7'];
      _slotMapping = {
        'slot_1': 'A1',
        'slot_2': 'A2',
        'slot_3': 'A3',
        'slot_4': 'A4',
      };
      
      if (!mounted) return;
      setState(() {
        _isLoadingLayout = false;
      });
      _listenToRealtimeSensors();
      
    } catch (e) {
      debugPrint("Error fetching layout: $e");
      if (!mounted) return;
      setState(() {
        _leftColumn = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'];
        _rightColumn = ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7'];
        _slotMapping = {
          'slot_1': 'A1',
          'slot_2': 'A2',
          'slot_3': 'A3',
          'slot_4': 'A4',
        };
        _isLoadingLayout = false;
      });
      _listenToRealtimeSensors();
    }
  }

  void _listenToRealtimeSensors() {
    final dbRef = FirebaseDatabase.instance.ref(_rtdbPath);
    
    _rtdbSubscription = dbRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;
      
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          // Check each sensor and update the occupied status
          data.forEach((key, value) {
            final uiSlot = _slotMapping[key.toString()];
            if (uiSlot != null) {
              if (value.toString() == 'occupied') {
                _sensorOccupiedSpots.add(uiSlot);
                // If the user had selected this spot, deselect it
                if (_selectedSpot == uiSlot) {
                  _selectedSpot = null;
                }
              } else if (value.toString() == 'available') {
                _sensorOccupiedSpots.remove(uiSlot);
              }
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _confirmSpot() async {
    if (_selectedSpot == null) return;

    // Navigate to the final summary screen before confirming with backend
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryScreen(
          bookingId: widget.bookingId,
          locationName: widget.locationName,
          locationAddress: widget.locationAddress,
          spotId: _selectedSpot!,
          vehicleMake: widget.vehicleMake,
          vehiclePlate: widget.vehiclePlate,
          startDateTime: widget.startDateTime,
          endDateTime: widget.endDateTime,
          price: widget.price,
        ),
      ),
    );
  }

  Widget _buildSpot(String spotId) {
    bool isOccupied = _bookedSpots.contains(spotId) || _sensorOccupiedSpots.contains(spotId);
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
              ? Colors.white.withValues(alpha: 0.05)
              : isSelected
                  ? Colors.blueAccent
                  : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.1),
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
                    ? Colors.white.withValues(alpha: 0.15)
                    : isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    spotId,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: isOccupied
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
                  _buildLegendItem(Colors.white.withValues(alpha: 0.05), 'Occupied'),
                ],
              ),
            ),
            if (!_isConnected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Live connection lost. Data may be stale.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: _isLoadingLayout
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      )
                    : Row(
                        children: [
                          // Left Column
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _leftColumn.length,
                              itemBuilder: (context, index) {
                                return _buildSpot(_leftColumn[index]);
                              },
                            ),
                          ),
                          // Center Road
                          Container(
                            width: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                                right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                12,
                                (index) => Container(
                                  width: 2,
                                  height: 16,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                          // Right Column
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _rightColumn.length,
                              itemBuilder: (context, index) {
                                return _buildSpot(_rightColumn[index]);
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
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}