import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_keys.dart';

class EmailService {
  // Method A: Production-Grade Secure Firestore Triggered Email
  // To use this, enable the "Trigger Email from Firestore" extension in your Firebase Console.
  static Future<bool> sendOtpViaFirestore(String email, String fullName, String otp) async {
    try {
      await FirebaseFirestore.instance.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'myMove - Verify Your Email',
          'html': '''
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; border: 1px solid #e1e1e1; border-radius: 16px; background-color: #ffffff;">
              <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #000000; font-size: 28px; font-weight: 900; letter-spacing: -1px; margin: 0;">myMove</h1>
                <p style="color: #8e8e93; font-size: 14px; margin-top: 5px;">Smart Car Parking System</p>
              </div>
              <h2 style="color: #000000; font-size: 20px; font-weight: 700; margin-bottom: 15px;">Verify your email address</h2>
              <p style="color: #3a3a3c; font-size: 15px; line-height: 1.6; margin-bottom: 25px;">
                Hello $fullName,<br><br>
                Thank you for choosing myMove. Please use the verification code below to complete your registration.
              </p>
              <div style="background-color: #f2f2f7; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 25px;">
                <span style="font-size: 32px; font-weight: 900; letter-spacing: 6px; color: #007aff; font-family: monospace;">$otp</span>
              </div>
              <p style="color: #8e8e93; font-size: 13px; line-height: 1.5;">
                This code is valid for 10 minutes. If you did not request this code, please ignore this email.
              </p>
              <hr style="border: 0; border-top: 1px solid #e5e5ea; margin: 30px 0;">
              <p style="color: #c7c7cc; font-size: 11px; text-align: center; margin: 0;">
                &copy; ${DateTime.now().year} myMove App. All rights reserved.
              </p>
            </div>
          ''',
        }
      });
      return true;
    } catch (e) {
      debugPrint('Firestore mail error: $e');
      return false;
    }
  }

  // Method B: Client-Side Direct REST API via EmailJS (Free & extremely popular)
  // Register for free at https://www.emailjs.com/ to get your keys!
  static Future<bool> sendOtpViaEmailJS({
    required String email,
    required String fullName,
    required String otp,
    String? serviceId,
    String? templateId,
    String? publicKey,
  }) async {
    final activeServiceId = serviceId ?? EmailKeys.serviceId;
    final activeTemplateId = templateId ?? EmailKeys.templateId;
    final activePublicKey = publicKey ?? EmailKeys.publicKey;

    // If the developer hasn't set custom keys yet, we simulate or print to console
    if (activeServiceId == 'YOUR_EMAILJS_SERVICE_ID' || 
        activeTemplateId == 'YOUR_EMAILJS_TEMPLATE_ID' || 
        activePublicKey == 'YOUR_EMAILJS_PUBLIC_KEY') {
      debugPrint('EmailJS integration: Please configure your API keys in lib/services/email_keys.dart');
      return false;
    }

    try {
      // Calculate a beautiful expiry time (current time + 15 mins)
      final expiryTime = DateTime.now().add(const Duration(minutes: 15));
      final hour = expiryTime.hour > 12 ? expiryTime.hour - 12 : (expiryTime.hour == 0 ? 12 : expiryTime.hour);
      final minute = expiryTime.minute.toString().padLeft(2, '0');
      final period = expiryTime.hour >= 12 ? 'PM' : 'AM';
      final timeString = '$hour:$minute $period';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': activeServiceId,
          'template_id': activeTemplateId,
          'user_id': activePublicKey,
          'template_params': {
            'email': email,
            'passcode': otp,
            'time': timeString,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('EmailJS send error: $e');
      return false;
    }
  }
}

