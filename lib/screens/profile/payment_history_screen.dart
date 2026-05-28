import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPayments = _allPayments;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPayments = _allPayments;
      } else {
        _filteredPayments = _allPayments.where((payment) {
          final desc = payment['description']?.toString().toLowerCase() ?? '';
          final amount = payment['amount']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return desc.contains(searchLower) || amount.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: _filteredPayments.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              itemCount: _filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = _filteredPayments[index];
                return ListTile(
                  title: Text(payment['description'] ?? 'Payment', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(payment['date'] ?? '', style: const TextStyle(color: Colors.white54)),
                  trailing: Text(payment['amount'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              },
            ),
      ),
    );
  }
}
