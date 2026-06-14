### ✅ What We Have Done

*1. Core User & Profile Systems*
*   *User Authentication:* Fully implemented with Firebase (registration, login, and auth state management).
*   *User Profile & Settings:* Profile management screens are done, including notification settings, permissions screen UI, and payment settings.
*   *Vehicle Registration:* Built seamlessly into the edit_profile_screen.dart, allowing users to add, manage, and set primary vehicles.

*2. QR Code & Secure Communication System*
*   *QR Generation & Scanning:* Completed. Users can generate a QR code for their vehicle and scan others' codes.
*   *Driver-to-Driver Chat:* Implemented in-app chat (chat_screen.dart and chat_list_screen.dart) and Blocked-Car Alerts so blocked drivers can communicate securely without exposing phone numbers.

*3. Parking Discovery & Maps*
*   *Google Maps Integration:* Completed the hybrid-mode map with real-time geolocation.
*   *Landmarks & Details:* Implemented a smooth native modal bottom sheet for interacting with parking landmarks and viewing spot details.

*4. Booking & Payment Management*
*   *Reservation Flow:* Fully implemented booking screens, checkout, booking success, and active parking timer screens.
*   *Booking Management:* Users can view active bookings, extend parking time, and view their payment history.

*5. Hardware Prototype & Real-Time Sync*
*   *ESP32 Firmware:* Completed esp32_smart_parking.ino for the tabletop prototype using ultrasonic sensors.
*   *Occupancy Conflict Logic:* Successfully hardened the logic! The app now correctly displays slot availability by prioritizing active Firestore bookings over raw real-time sensor data from the ESP32.

---

### ⏳ What We Have Left To Do (In-Scope)

Based on project TODO comments and the PRD, these are the final missing pieces for the prototype:

*   *Device Permissions Handling:* You have active TODO`s in `permissions_screen.dart and notifications_screen.dart to actually execute location, camera, and notification permission requests using the permission_handler package.
*   *Push Notifications Integration:* Hook up Firebase Cloud Messaging (FCM) so that "Blocked-Car Alerts" or "Booking Reminders" actively push to the user's phone even when the app is minimized.
*   *Admin/Parking Management Module:* The PRD mentions a simple admin interface to add/edit parking slots. Currently, you may be managing this manually via the Firebase Console. You have to decide whether to build a simple admin panel or stick to manual Firebase entry for the FYP2 presentation.
*   *End-to-End Prototype Testing:* Final physical tests moving the "toy cars" on the tabletop model while watching the Flutter UI react in real-time.

---

### ❌ What We Haven't Done (Out of Scope / Future Work)

As outlined in section 7.2 of your PRD, these features are intentionally left out of the current build and can be proposed as future enhancements:

*   *Real Payment Gateways:* Integration with real banks or e-wallets (currently using simulated/mock payment states).
*   *VoIP Calling (WebRTC):* Voice calling between drivers; the current system relies on secure text chat/alerts.
*   *Advanced Identity Verification:* e-KYC using IC or facial recognition.
*   *Hardware Automation:* Automatic barrier gate control or AI-based camera prediction.
*   *Legal Enforcement:* Summon generation or integrations with government operator APIs.

*

*Would you like to tackle the permission_handler TODOs next, or would you prefer to start integrating Firebase Cloud Messaging for Push Notifications?*
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

Based on the project documents (`development_roadmap.md`, `PRD.md`, and `agile_prototype_methodology.md`), here is the comprehensive breakdown of our progress across the 14-phase roadmap:

### ✅ What We Have Done (Completed Phases)
*   **Phases 1 & 2: Foundation & Core Authentication:** Flutter/Firebase setup, user registration, login, and profile management are complete.
*   **Phase 3: Hardware Integration:** The ESP32 firmware (`esp32_smart_parking.ino`) and ultrasonic sensor logic are built. We successfully merged real-time hardware data with Firestore booking data.
*   **Phases 4 & 5: Parking Search & Spot Selection:** Google Maps integration, real-time geolocation, custom markers, building details, and the interactive spot selection UI are finished.
*   **Phase 6: Booking System:** Full reservation flow (date/time, duration, fees) and active booking management (countdown timer, extend time) are working.
*   **Phase 7: Payment Integration:** Payment flows and states are implemented (simulated for FYP2 constraints as per the PRD).
*   **Phase 8: QR Code System:** Unique QR generation for vehicles and the mobile scanner integration are fully operational.
*   **Phase 9: Communication Features:** Secure driver-to-driver in-app messaging and "Blocked-Car" alerts are implemented.

### ⏳ What We Have Left To Do (In-Scope / Pending Phases)
*   **Phase 10: Push Notifications:** We need to configure Firebase Cloud Messaging (FCM) to handle push notifications for booking expiry warnings, blocked-car alerts, and chat messages when the app is in the background.
*   **Phase 11: Device Permissions:** We must finalize the `permission_handler` logic in the app to properly request Camera, Location, and Notification access from the user.
*   **Phase 12: End-to-End Testing & Optimization:** We need to run comprehensive tests using the physical cardboard prototype and the toy cars to ensure the UI updates seamlessly without lag or crashes. We also need to conduct User Acceptance Testing (UAT).
*   **Phase 13 & 14: Thesis & Deployment:** Writing the thesis documentation, creating the presentation slides/video, and preparing the final build for the FYP2 presentation.

### ❌ What We Haven't Done (Out of Scope for FYP2)
As outlined in your PRD (Section 7.2) and the Future Enhancements roadmap, these are excluded from the current prototype build:
*   Real Payment Gateways (live bank/e-wallet integration).
*   VoIP Calling using WebRTC (we are sticking to secure text chat).
*   Advanced Identity Verification (e-KYC / Facial Recognition).
*   Hardware Automation (Automatic barrier gates, license plate recognition cameras).
*   Official government or parking operator integrations.

Would you like to start on **Phase 10 (Push Notifications)** or tackle the **Device Permissions** next?