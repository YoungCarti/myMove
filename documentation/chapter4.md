Here is a complete, itemized checklist of everything you should include in **Chapter 4: System Development** for your `myMove` thesis report:

---

# 📘 **Chapter 4: System Development Outline**

### **4.1 System Architecture Overview**
* **Overall System Architecture Diagram**: Show how all components connect together:
  $$\text{ESP32 IoT Sensors} \longleftrightarrow \text{Firebase Realtime DB} \longleftrightarrow \text{Flutter Mobile App} \longleftrightarrow \text{Web Admin Dashboard}$$
* **Component Description**: Brief explanation of the role of Flutter (Mobile App), ESP32 (Hardware), Firebase (Cloud Backend/Database), and Web Admin.

---

### **4.2 Database Design & Data Models**
* **Cloud Firestore Structure** (Main database for persistent data):
  * `users` collection (user profile, contact info, vehicle details).
  * `parking_locations` collection (location name, address, pricing, operating hours).
  * `parkingSpots` collection (spot name e.g., A1, A2, and hardware sensor mapping `hardwareSensorId`).
  * `bookings` collection (booking ID, reserved spot, start/end time, total price, payment status).
* **Firebase Realtime Database (RTDB) Structure** (Live hardware syncing):
  * Node path: `/parking_status/{location_id}/{slot_id}`
  * Data payload: `"available"` or `"occupied"`

---

### **4.3 IoT Hardware & Sensor Subsystem Development**
* **Hardware Components List**:
  * ESP32 Microcontroller unit.
  * HC-SR04 Ultrasonic Distance Sensors (3 units).
  * Breadboard and Male-to-Female jumper wires.
* **Circuit Wiring & GPIO Pin Mapping Table**:
  * **Slot 1**: TRIG = GPIO 12, ECHO = GPIO 13
  * **Slot 2**: TRIG = GPIO 4, ECHO = GPIO 16
  * **Slot 3**: TRIG = GPIO 14, ECHO = GPIO 27
* **Firmware Implementation (`esp32_smart_parking.ino`)**:
  * **Distance Measurement Algorithm**: Calculating distance via ultrasonic pulse return duration (`readDistanceCM`).
  * **Occupancy Decision Logic**: Threshold set at `< 10.0 cm` = `occupied`, else `available`.
  * **Event-Driven Firebase Sync**: Logic that only pushes HTTP/RTDB updates when a status change is detected (conserving bandwidth & quota).

---

### **4.4 Mobile Application Development (Flutter)**
* **User Authentication Module**: Firebase Email/Password login and sign-up flow.
* **Parking Search & Location Details**: Browsing available parking locations, viewing rates, address, and operating hours.
* **Real-time Interactive Parking Grid (`ParkingSpotScreen`)**:
  * Dynamic visual grid layout (Left Column, Central Driving Lane, Right Column).
  * **Real-time Stream Listener**: Listening to RTDB changes at `/parking_status/building_A` to update UI spot states instantly.
  * **Visual State Mapping**:
    * 🟦 **Blue**: Currently Selected Spot.
    * ⬛ **Dark Grey**: Available for selection.
    * ⬜ **Light Grey**: Occupied by real-time sensor or existing booking.
* **Booking & Summary Flow**: Date/time selector, vehicle selection, pricing breakdown, and booking confirmation.
* **Payment Subsystem**: Stripe Payment Gateway integration via backend webhooks for secure payment processing.
* **Communication & Convenience Features**:
  * In-App messaging between users for blocked-vehicle situations.
  * **Web-based QR Code Contact Flow**: Scanning a QR code on a blocked car opens a web link directly so guest users don't need to download the full app just to send a message.
  * **SOS / Emergency Trigger**: One-tap emergency notification.
* **Profile Management & Personalization (`EditProfileScreen`)**:
  * Profile customization including full name, bio description, and profile image uploading via local gallery image picking (`ImagePicker`).
  * Dynamic multi-vehicle configuration allowing users to add, edit, or remove vehicles, specify make/model and license plate numbers, and toggle primary vehicles.
* **Account Settings & Security Module (`AccountSettingsScreen` & `Setup2FAScreen`)**:
  * Secure credential management, username editing, and mobile phone linking.
  * Two-Factor Authentication (2FA) setup flow (generating cryptographically secure TOTP secrets, encoding them into standard `otpauth://` URIs, displaying QR setup codes, and verifying 6-digit authenticator codes to prevent session hijacking).
  * Safe, permanent account deletion capability with user re-authentication triggers.
* **Payment & Transaction Suite (`PaymentSettingsScreen` & `PaymentHistoryScreen`)**:
  * Stripe Payment Gateway integration using the Stripe SDK Payment Sheet modal for secure credit/debit card details entry without exposing cardholder data.
  * Displaying, caching, and removing saved cards securely via Firebase HTTPS Cloud Functions.
  * Comprehensive transaction history ledger fetching completed, active, and refunded bookings/payments directly from Cloud Firestore, with searching and sorting parameters.
* **Access Control & Permissions Panel (`PermissionsScreen` & `NotificationsScreen`)**:
  * Fine-grained control over system permissions: Location Access (for fetching nearby parking structures) and Camera Access (for scanning QR codes and taking profile photos).
  * Push notifications and notification channel settings, allowing the user to configure reminders for parking expiry, active bookings, security alerts, and payment receipts.

---

### **4.5 Web Admin Dashboard Development**
* **Administrative Interface Overview**: Web dashboard designed for parking facility managers.
* **Parking Location & Spot Management (CRUD)**: Interface allowing admins to add/edit parking locations and map sensor IDs without touching the raw database.
* **Live Occupancy & Booking Monitor**: Real-time view of active bookings and current parking slot statuses.
* **Emergency / SOS Alert Monitor**: Center for monitoring triggered emergency alerts from users in real time.

---

### **4.6 Summary**
The implementation phase successfully transformed the system requirements and architectural designs of the **myMove Smart Parking & Communication System** into a fully functional, secure, and integrated IoT-enabled ecosystem. By leveraging **Flutter** for the cross-platform mobile application, **ESP32 microcontrollers** with HC-SR04 ultrasonic sensors for real-time spot monitoring, and a unified **Firebase backend (Cloud Firestore & Realtime Database)**, myMove delivers a modern solution with live state-tracking and offline resilience. The integration of the **Stripe SDK** guarantees secure payment authorization, while features such as **Two-Factor Authentication (2FA)** and QR-based contact verification (**Scanner-Web**) ensure high operational security and guest convenience. Coordinated by modular **Firebase Cloud Functions** for serverless business logic and managed through a responsive **React/Vite Web Admin Dashboard**, this robust, decoupled architecture is built for ease of maintenance and scalability. Ultimately, the completed application fully satisfies the project objectives and provides a significant improvement over traditional parking management and vehicle blocking resolution methods.

---

### 💡 **Pro-Tip for Writing Chapter 4:**
Include **screenshots** of your Flutter screens, Web Admin Dashboard, ESP32 Serial Monitor logs, circuit pin diagrams, and Firestore database trees to make Chapter 4 look rich, professional, and thorough!