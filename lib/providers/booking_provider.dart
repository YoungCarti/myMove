import 'package:flutter/foundation.dart';

class BookingProvider with ChangeNotifier {
  final bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Booking methods will be implemented in Sprint 5
}