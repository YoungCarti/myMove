import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Dark gray box
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.moon_stars_fill, // Moon with stars icon
                color: Colors.white54,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Payments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No payments match your search.'
                : 'You have not made any payments.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 80), // To perfectly center it visually considering the appBar
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search payments...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
            )
          : const Text(
              'Payment History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 24),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _onSearchChanged('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please log in to view payments', style: TextStyle(color: Colors.white)))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading payments', style: TextStyle(color: Colors.red)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Extract all valid payment records
                  final allPayments = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final docStatus = data['status'] as String? ?? 'pending';
                    
                    return docStatus == 'completed' || docStatus == 'active' || docStatus == 'canceled';
                  }).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final isLegacyPrice = !data.containsKey('totalPaid');
                    final double basePrice = (data['totalPrice'] ?? 0).toDouble();
                    final double priceAmount = isLegacyPrice 
                        ? basePrice * 1.02 
                        : (data['totalPaid'] ?? 0).toDouble();
                    
                    final startStr = data['startDateTime'] as String?;
                    final date = startStr != null 
                        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(startStr).toLocal())
                        : 'Unknown Date';
                        
                    final locationName = data['locationName'] as String? ?? 'Unknown Location';
                    final docStatus = data['status'] as String? ?? 'pending';
                    
                    String title = locationName;
                    if (docStatus == 'canceled') {
                       title = '$locationName (Refunded)';
                    }
                    
                    return {
                      'description': title,
                      'amount': 'RM${priceAmount.toStringAsFixed(2)}',
                      'date': date,
                      'timestamp': startStr != null ? DateTime.parse(startStr).toLocal() : DateTime.fromMillisecondsSinceEpoch(0),
                      'isRefunded': docStatus == 'canceled',
                    };
                  }).toList();

                  // Sort by date descending
                  allPayments.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

                  // Apply search filter
                  List<Map<String, dynamic>> filteredPayments = allPayments;
                  if (_searchQuery.isNotEmpty) {
                    filteredPayments = allPayments.where((payment) {
                      final desc = payment['description']?.toString().toLowerCase() ?? '';
                      final amount = payment['amount']?.toString().toLowerCase() ?? '';
                      final searchLower = _searchQuery.toLowerCase();
                      return desc.contains(searchLower) || amount.contains(searchLower);
                    }).toList();
                  }

                  if (filteredPayments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = filteredPayments[index];
                      final isRefunded = payment['isRefunded'] as bool;
                      
                      return ListTile(
                        title: Text(
                          payment['description'] ?? 'Payment', 
                          style: TextStyle(
                            color: isRefunded ? Colors.white54 : Colors.white,
                            decoration: isRefunded ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(payment['date'] ?? '', style: const TextStyle(color: Colors.white54)),
                        trailing: Text(
                          payment['amount'] ?? '', 
                          style: TextStyle(
                            color: isRefunded ? Colors.white54 : Colors.white, 
                            fontWeight: FontWeight.bold,
                            decoration: isRefunded ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
