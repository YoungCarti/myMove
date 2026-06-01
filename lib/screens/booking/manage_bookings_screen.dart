import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'booking_info_screen.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every 30 seconds to update time-dependent booking statuses
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Manage Bookings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Canceled'),
              Tab(icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(status: 'Upcoming'),
            _buildList(status: 'Ongoing'),
            _buildList(status: 'Completed'),
            _buildList(status: 'Canceled'),
            _buildList(status: 'History'),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required String status}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view bookings', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading bookings', style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final now = DateTime.now();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docStatus = data['status'] as String? ?? 'pending';
          final startStr = data['startDateTime'] as String?;
          final endStr = data['endDateTime'] as String?;
          
          if (startStr == null || endStr == null) return false;
          
          final start = DateTime.parse(startStr).toLocal();
          final end = DateTime.parse(endStr).toLocal();

          if (status == 'Upcoming') {
            return docStatus == 'active' && start.isAfter(now);
          } else if (status == 'Ongoing') {
            return docStatus == 'active' && !start.isAfter(now) && !end.isBefore(now);
          } else if (status == 'Completed') {
            return docStatus == 'completed' || (docStatus == 'active' && end.isBefore(now));
          } else if (status == 'Canceled') {
            return docStatus == 'canceled';
          } else if (status == 'History') {
            return docStatus == 'completed' || docStatus == 'canceled' || (docStatus == 'active' && end.isBefore(now));
          }
          return false;
        }).toList();

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aStart = DateTime.parse(aData['startDateTime'] as String? ?? '').toLocal();
          final bStart = DateTime.parse(bData['startDateTime'] as String? ?? '').toLocal();
          return bStart.compareTo(aStart);
        });

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildBookingCard(context, docs[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docStatus = data['status'] as String? ?? 'pending';
    final locationName = data['locationName'] as String? ?? 'Unknown Location';
    final locationAddress = data['locationAddress'] as String?;
    final startStr = data['startDateTime'] as String?;
    final endStr = data['endDateTime'] as String?;
    
    // For legacy bookings that only stored the pre-tax totalPrice, 
    // we need to re-apply the 2% tax that was actually charged at checkout.
    final bool isLegacyPrice = !data.containsKey('totalPaid');
    final double basePrice = (data['totalPrice'] ?? 0).toDouble();
    final double priceAmount = isLegacyPrice 
        ? basePrice * 1.02 
        : (data['totalPaid'] ?? 0).toDouble();
        
    final price = 'RM${priceAmount.toStringAsFixed(2)} ';
    final bookingId = doc.id;
    
    final start = startStr != null ? DateTime.parse(startStr).toLocal() : DateTime.now();
    final end = endStr != null ? DateTime.parse(endStr).toLocal() : DateTime.now();
    final now = DateTime.now();

    String effectiveStatus = 'Pending';
    Color statusColor = Colors.grey;
    bool isSolidStatus = false;
    bool hasCTAs = false;

    if (docStatus == 'canceled') {
      effectiveStatus = 'Canceled';
      statusColor = Colors.red;
    } else if (docStatus == 'completed' || (docStatus == 'active' && end.isBefore(now))) {
      effectiveStatus = 'Completed';
      statusColor = Colors.green;
    } else if (docStatus == 'active') {
      if (start.isAfter(now)) {
        effectiveStatus = 'Upcoming';
        statusColor = Colors.blueAccent;
        isSolidStatus = true;
        hasCTAs = true;
      } else {
        effectiveStatus = 'Ongoing';
        statusColor = Colors.blueAccent;
        isSolidStatus = true;
        hasCTAs = true;
      }
    }

    String priceUnit = 'total';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (locationAddress != null && locationAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              locationAddress,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (effectiveStatus != 'Completed' && effectiveStatus != 'Canceled') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(start),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: priceUnit,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSolidStatus 
                      ? statusColor 
                      : Colors.transparent,
                  border: isSolidStatus 
                      ? null 
                      : Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  effectiveStatus,
                  style: TextStyle(
                    color: isSolidStatus ? Colors.white : statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasCTAs) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: effectiveStatus == 'Ongoing' 
                        ? null 
                        : () => _showCancelDialog(context, bookingId),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: effectiveStatus == 'Ongoing' 
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: effectiveStatus == 'Ongoing' 
                            ? Colors.grey.withValues(alpha: 0.5) 
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingInfoScreen(
                            bookingId: bookingId,
                            locationName: locationName,
                            spotId: data['spotId'] ?? 'N/A',
                            startDateTime: start,
                            endDateTime: end,
                            price: priceAmount,
                            effectiveStatus: effectiveStatus,
                            locationAddress: locationAddress ?? '',
                            vehicleMake: data['vehicleMake'] ?? '',
                            vehiclePlate: data['vehiclePlate'] ?? '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'More Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cancel Parking',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to cancel your Parking Reservation?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The payment will be refunded to your bank account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Perform cancel logic
                        try {
                          final callable = FirebaseFunctions.instance.httpsCallable('cancelBooking');
                          await callable.call({'bookingId': bookingId});
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking canceled successfully.')),
                            );
                          }
                        } on FirebaseFunctionsException catch (e) {
                          debugPrint('Firebase Functions Error: ${e.code} - ${e.message} - ${e.details}');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to cancel: ${e.message ?? e.code}')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Cancel Error: $e');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to cancel: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Yes, Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        );
      },
    );
  }
}
