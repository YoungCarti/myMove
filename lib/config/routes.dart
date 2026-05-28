import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/parking/search_parking_screen.dart';
import '../screens/parking/parking_details_screen.dart';
import '../screens/parking/parking_spot_screen.dart';
import '../screens/booking/book_parking_screen.dart';
import '../screens/booking/active_booking_screen.dart';
import '../screens/qr/qr_scanner_screen.dart';
import '../screens/qr/qr_display_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/update_username_screen.dart';
import '../screens/profile/enter_mobile_screen.dart';
import '../screens/profile/otp_verification_screen.dart';
import '../screens/profile/setup_2fa_screen.dart';
import '../screens/profile/payment_settings_screen.dart';


class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String searchParking = '/search-parking';
  static const String parkingDetails = '/parking-details';
  static const String parkingSpot = '/parking-spot';
  static const String bookParking = '/book-parking';
  static const String activeBooking = '/active-booking';
  static const String qrScanner = '/qr-scanner';
  static const String qrDisplay = '/qr-display';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String accountSettings = '/account-settings';
  static const String updateUsername = '/update_username';
  static const String enterMobile = '/enter_mobile';
  static const String otpVerification = '/otp_verification';
  static const String setup2FA = '/setup_2fa';
  static const String paymentSettings = '/payment-settings';


  // Route map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    searchParking: (context) => const SearchParkingScreen(),
    parkingDetails: (context) => const ParkingDetailsScreen(),
    parkingSpot: (context) => const ParkingSpotScreen(),
    bookParking: (context) => const BookParkingScreen(),
    activeBooking: (context) => const ActiveBookingScreen(),
    qrScanner: (context) => const QRScannerScreen(),
    qrDisplay: (context) => const QRDisplayScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    accountSettings: (context) => const AccountSettingsScreen(),
    updateUsername: (context) => const UpdateUsernameScreen(),
    enterMobile: (context) => const EnterMobileNumberScreen(),
    otpVerification: (context) => const OtpVerificationScreen(),
    setup2FA: (context) => const Setup2FAScreen(),
    paymentSettings: (context) => const PaymentSettingsScreen(),
  };
}