import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/parking_location.dart';

class BookingCheckoutSheet extends StatefulWidget {
  final ParkingLocation location;

  const BookingCheckoutSheet({
    super.key,
    required this.location,
  });

  @override
  State<BookingCheckoutSheet> createState() => _BookingCheckoutSheetState();
}

class _BookingCheckoutSheetState extends State<BookingCheckoutSheet> {
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;

  // Date selection (allow multiple dates)
  final Set<DateTime> _selectedDates = {};
  late DateTime _currentMonth;

  // Time selection
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDates.add(DateTime(now.year, now.month, now.day));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vehicles.isEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _vehicles = authProvider.vehicles;
      
      if (_vehicles.isNotEmpty) {
        // Try to find primary vehicle, or fallback to first
        _selectedVehicle = _vehicles.firstWhere(
          (v) => v['isPrimary'] == true, 
          orElse: () => _vehicles.first
        );
      }
    }
  }

  int get _calculatedHours {
    if (_selectedDates.isEmpty) return 0;
    
    final sortedDates = _selectedDates.toList()..sort();
    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, _endTime.hour, _endTime.minute);

    int diffMinutes = endDateTime.difference(startDateTime).inMinutes;
    if (diffMinutes <= 0) return 0;
    
    return (diffMinutes / 60).ceil();
  }

  double get _totalPrice {
    return _calculatedHours * widget.location.pricePerHour;
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (_selectedDates.isEmpty || _selectedDates.length > 1) {
        _selectedDates.clear();
        _selectedDates.add(normalizedDate);
      } else {
        // One date currently selected, act as range end
        final firstDate = _selectedDates.first;
        if (normalizedDate.isBefore(firstDate)) {
          _selectedDates.clear();
          _selectedDates.add(normalizedDate);
        } else if (!normalizedDate.isAtSameMomentAs(firstDate)) {
          DateTime curr = firstDate;
          while (curr.isBefore(normalizedDate) || curr.isAtSameMomentAs(normalizedDate)) {
            _selectedDates.add(curr);
            curr = curr.add(const Duration(days: 1));
          }
        }
      }
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildVehicleDropdown() {
    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.blueAccent),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'No vehicle registered',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<Map<String, dynamic>>(
      initialValue: _selectedVehicle,
      onSelected: (Map<String, dynamic> vehicle) {
        setState(() {
          _selectedVehicle = vehicle;
        });
      },
      offset: const Offset(0, 60),
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (BuildContext context) {
        return _vehicles.map((Map<String, dynamic> vehicle) {
          return PopupMenuItem<Map<String, dynamic>>(
            value: vehicle,
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vehicle['make'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      vehicle['plate'] ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedVehicle?['make'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedVehicle?['plate'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningMessage() {
    if (_selectedDates.isEmpty) return const SizedBox.shrink();
    
    final sortedDates = _selectedDates.toList()..sort();
    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, _endTime.hour, _endTime.minute);

    int diffMinutes = endDateTime.difference(startDateTime).inMinutes;

    if (diffMinutes <= 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Invalid time. End time must be after start time.',
                style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    
    int uiTimeDiffMinutes = (_endTime.hour * 60 + _endTime.minute) - (_startTime.hour * 60 + _startTime.minute);
    
    if (_selectedDates.length > 1 && uiTimeDiffMinutes > 0 && uiTimeDiffMinutes <= 120) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You chose multiple dates! This is a continuous booking for $_calculatedHours hours (NOT daily).',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedDates.length > 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Continuous multi-day booking: $_calculatedHours hours total.',
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCalendar() {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    List<Widget> dayWidgets = [];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Add weekday headers
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    // Add empty slots for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    DateTime? startDate;
    DateTime? endDate;
    if (_selectedDates.isNotEmpty) {
      final sortedDates = _selectedDates.toList()..sort();
      startDate = sortedDates.first;
      endDate = sortedDates.last;
    }

    // Add actual days
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDate = DateTime(_currentMonth.year, _currentMonth.month, i);
      
      bool isStart = startDate != null && currentDate.year == startDate.year && currentDate.month == startDate.month && currentDate.day == startDate.day;
      bool isEnd = endDate != null && currentDate.year == endDate.year && currentDate.month == endDate.month && currentDate.day == endDate.day;
      bool isSelected = _selectedDates.any((d) => d.year == currentDate.year && d.month == currentDate.month && d.day == currentDate.day);
      bool isBetween = isSelected && !isStart && !isEnd;
      
      // Basic check for past dates
      bool isPast = currentDate.isBefore(DateTime.now()) && 
                    !(currentDate.year == DateTime.now().year && currentDate.month == DateTime.now().month && currentDate.day == DateTime.now().day);
      
      Color bgColor = Colors.transparent;
      if (isStart || isEnd) {
        bgColor = Colors.blueAccent;
      } else if (isBetween) {
        bgColor = Colors.blueAccent.withOpacity(0.2); // Faded blue for in-between dates
      }

      Color textColor;
      if (isPast) {
        textColor = Colors.white.withOpacity(0.2);
      } else if (isStart || isEnd) {
        textColor = Colors.white;
      } else {
        textColor = Colors.white.withOpacity(0.9);
      }
      
      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _toggleDate(currentDate),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                i.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM yyyy').format(_currentMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: dayWidgets,
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, bool isStart) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectTime(context, isStart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 1. Choose Vehicle
              const Text(
                'Choose Vehicle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildVehicleDropdown(),
              
              const SizedBox(height: 24),
              
              // 2. Select Date
              const Text(
                'Select Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildCalendar(),
              
              const SizedBox(height: 16),
              
              // 3. Start Hour and End Hour
              Row(
                children: [
                  _buildTimeSelector('Start Hour', _startTime, true),
                  const Padding(
                    padding: EdgeInsets.only(top: 24, left: 12, right: 12),
                    child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ),
                  _buildTimeSelector('End Hour', _endTime, false),
                ],
              ),
              
              const SizedBox(height: 32),
              
              _buildWarningMessage(),
              
              // 4. Total Price
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM${_totalPrice.toStringAsFixed(0)}',
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
                      'for $_calculatedHours hour(s)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 5. Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculatedHours <= 0 || _selectedVehicle == null || _isLoading || widget.location.availableSpots <= 0
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        try {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final userId = authProvider.user?.uid;
                          
                          if (userId == null) throw Exception('User not logged in');

                          final sortedDates = _selectedDates.toList()..sort();
                          final startDate = sortedDates.first;
                          final endDate = sortedDates.last;
                          
                          final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, _startTime.hour, _startTime.minute);
                          final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, _endTime.hour, _endTime.minute);

                          final locationRef = FirebaseFirestore.instance.collection('parking_locations').doc(widget.location.id);
                          final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            // 1. Read the current parking location document
                            final locationDoc = await transaction.get(locationRef);
                            
                            if (!locationDoc.exists) {
                              throw Exception('Parking location does not exist.');
                            }
                            
                            final int currentSpots = locationDoc.data()?['availableSpots'] ?? 0;
                            
                            // 2. Verify availability
                            if (currentSpots <= 0) {
                              throw Exception('Sorry, this parking location just sold out.');
                            }

                            // 3. Decrement available spots
                            transaction.update(locationRef, {
                              'availableSpots': currentSpots - 1,
                            });

                            // 4. Create the booking
                            transaction.set(bookingRef, {
                              'userId': userId,
                              'locationId': widget.location.id,
                              'locationName': widget.location.name,
                              'vehicleMake': _selectedVehicle?['make'],
                              'vehiclePlate': _selectedVehicle?['plate'],
                              'startDateTime': startDateTime.toIso8601String(),
                              'endDateTime': endDateTime.toIso8601String(),
                              'totalPrice': _totalPrice,
                              'calculatedHours': _calculatedHours,
                              'status': 'active', // or 'pending' if payment is next
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
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
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.location.availableSpots <= 0 ? 'Sold Out' : 'Continue',
                        style: const TextStyle(
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
    );
  }
}
