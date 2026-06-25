# myMove FYP1 vs. FYP2 Development Analysis

This document compares the proposed features from your FYP1 report (`resources/myMove_Report_1.pdf`) against the current state of the FYP2 codebase to identify what aligns and what is missing or partially implemented.

## ✅ Fully Aligned / Implemented Features

1. **Real-Time Parking Availability & Details**
   - **PDF:** Show available/occupied spaces, building name, floor, fee rate, and duration. Update based on hardware.
   - **Status:** Implemented! Your app uses Firebase Realtime Database for hardware updates (ESP32), and Firestore for parking layouts. The UI shows color-coded parking slots.
2. **Parking Reservation**
   - **PDF:** Reverse specific parking spaces in advance.
   - **Status:** Implemented! `booking_service.dart` and booking screens exist.
3. **Navigation Assistance**
   - **PDF:** Guided directions to selected parking areas using Google Maps.
   - **Status:** Implemented! Google Maps is integrated via `google_maps_flutter` and you have location tracking.
4. **QR Code-Based Solution for Double Parking**
   - **PDF:** Blocked drivers can scan a QR code to contact car owners.
   - **Status:** Implemented! `qr_flutter` and `mobile_scanner` are integrated along with `qr_display_screen.dart`.
5. **In-App Messaging**
   - **PDF:** Secure chat communication between drivers.
   - **Status:** Implemented! `chat_screen.dart` and Firebase backend handle this.

---

## 🚧 Partially Implemented Features

1. **Payment Integration**
   - **PDF:** Payments handled using Stripe, Touch 'n Go eWallet via Firebase Functions.
   - **Status:** Partial. While `flutter_stripe` is in your `pubspec.yaml`, the `payment_service.dart` is currently just mocking saved cards locally using `SharedPreferences`. Real Firebase Functions/Stripe processing isn't fully wired up yet.
2. **Voice Calling**
   - **PDF:** VoIP Calling via Agora or ZegoCloud.
   - **Status:** Partial/Missing. Neither Agora nor ZegoCloud SDKs are installed in your `pubspec.yaml`. However, you have `url_launcher` installed, which allows you to launch native phone calls instead of doing true in-app VoIP. *You may want to edit the PDF to say "native phone calls" instead of "VoIP" to save development time.*

---

## ❌ Missing Features

1. **Emergency Mode**
   - **PDF:** Quick-access features to send urgent alerts in emergency situations.
   - **Status:** Missing. There are no emergency screens, services, or UI buttons in the app currently.
2. **Space for User Feedback**
   - **PDF:** Receive feedback from users/drivers about their experience.
   - **Status:** Missing. There is no feedback form or rating system implemented in the profile or booking screens.

## Next Steps

**If you want to edit the PDF (FYP1 Report) to match the app:**
- Remove **Agora/ZegoCloud VoIP** and replace it with "Direct Phone Calls".
- Remove or modify the **Emergency Mode** and **User Feedback** features if you don't plan to build them.
- Adjust the **Payment** section if you plan to stick with mocked payments for your FYP2 demo.

**If you want to build the missing features in FYP2:**
- We can start implementing **Stripe Payments**, the **Emergency Button**, or the **Feedback Form** right now!