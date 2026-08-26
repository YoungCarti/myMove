# 📋 Functional Requirements Specification (Pages 30 & 31)

This section outlines the functional requirements of the **myMove Smart Parking & Communication System**, derived from user needs gathered during the requirement analysis phase. The requirements are structured by core functional modules and link directly to the underlying technologies used in the implementation.

---

## 1. Summary of Implemented Functional Requirements

*   **User Authentication and Session Management**: Secure user registration, login, profile management, and persistent user sessions in the Flutter mobile application using **Firebase Authentication**.
*   **Vehicle & QR Code Management**: CRUD management of registered vehicles (license plate, model, color) and automatic generation of unique, high-resolution contact QR codes stored and retrieved via **Firebase Storage**.
*   **Real-time Parking Spot Grid**: Dynamic, visual grid layout representing available and occupied spots. The grid updates immediately in response to live sensor states utilizing stream listeners connected to the **Firebase Realtime Database (RTDB)**.
*   **Parking Spot Reservation & Booking**: Spot selection, time duration setup, price breakdown calculation, and confirmation of booking status persisted in **Cloud Firestore**.
*   **Payment Gateway Integration**: Secure processing of credit card transactions for reservations using **Stripe API and SDK** integrations.
*   **Ultrasonic Occupancy Detection**: Proximity monitoring of physical parking spots using **HC-SR04 ultrasonic sensors** controlled by an **ESP32 microcontroller** to identify vehicle presence.
*   **Local Status Feedback**: Hardware status indicators using dual LEDs connected to the **ESP32** (Red for occupied slots, Green for vacant slots) to provide immediate feedback to drivers in the physical parking lot.
*   **Live Database Synchronization**: Automatic transmission of physical slot changes to the cloud from the **ESP32** utilizing HTTP requests/REST APIs connected to the **Firebase RTDB**.
*   **SOS & Emergency Broadcast**: One-tap emergency/panic trigger in the mobile app, instantly transmitting user profile details and current GPS coordinates to the Admin Dashboard for operator action.
*   **Web Guest Contact Flow**: Web-based portal (`scanner-web`) allowing non-app users (guests) to scan a vehicle's QR code, verify the vehicle's public details, and request a vehicle move.
*   **Blocked-Vehicle Alerts & Move Requests**: Ability to upload proof photos and share GPS coordinates via the web guest browser to report blocking vehicles.
*   **Real-Time Anonymous Chat**: Seamless, real-time messaging between a blocked driver (using the web guest portal) and the blocking car owner (using the Flutter in-app chat) to coordinate relocation without exposing personal contact details.
*   **Web Admin CRUD Portal**: Administrative management allowing operators to create, read, update, and delete parking locations, zones, and individual spot-to-sensor mappings via the Web Admin Dashboard (`admin-web`).
*   **Emergency Alert & Live Operations Hub**: Real-time console for admins to monitor triggered SOS emergency alerts, review active bookings, and broadcast system-wide announcements to all mobile app users.
*   **User Feedback and Bug Logging**: Submission and management of user experiences, rating logs, and issue reports within the system database.

---

## 2. Requirement Traceability Matrix

The table below maps the functional requirements directly to the Use Case elements shown in the Chapter 4 diagram:

| Use Case Name (From Diagram) | Implemented Functional Block | Associated System Module |
| :--- | :--- | :--- |
| **Manage Vehicles** | Vehicle & QR Code Management | Flutter Mobile App |
| **View/Save Vehicle QR** | Vehicle & QR Code Management | Flutter Mobile App |
| **Search Parking Locations** | Real-time Parking Spot Grid | Flutter Mobile App |
| **Select & Reserve Parking Spot** | Parking Spot Reservation & Booking / Stripe Payment | Flutter Mobile App |
| **View Active/Past Bookings** | Parking Spot Reservation & Booking | Flutter Mobile App |
| **Scan Vehicle QR (In-App)** | Web Guest Contact Flow | Flutter Mobile App |
| **Secure In-App Chat** | Real-Time Anonymous Chat | Flutter Mobile App |
| **Send SOS / Emergency Alert** | SOS & Emergency Broadcast | Flutter Mobile App |
| **View Public Vehicle Info** | Web Guest Contact Flow | Web Scanner (`scanner-web`) |
| **Request Move (Upload Photo & GPS)** | Blocked-Vehicle Alerts & Move Requests | Web Scanner (`scanner-web`) |
| **Secure Web-App Chat** | Real-Time Anonymous Chat | Web Scanner (`scanner-web`) |
| **Manage Locations (CRUD)** | Web Admin CRUD Portal | Web Admin (`admin-web`) |
| **Manage Parking Spots (CRUD)** | Web Admin CRUD Portal | Web Admin (`admin-web`) |
| **Monitor Live Occupancy** | Emergency Alert & Live Operations Hub | Web Admin (`admin-web`) |
| **Handle SOS/Emergency Alerts** | Emergency Alert & Live Operations Hub | Web Admin (`admin-web`) |
| **Broadcast Notifications** | Emergency Alert & Live Operations Hub | Web Admin (`admin-web`) |
| **View User Feedback** | User Feedback and Bug Logging | Web Admin (`admin-web`) |
| **Detect Vehicle Occupancy** | Ultrasonic Occupancy Detection | ESP32 IoT Subsystem |
| **Update Local LED Indicators** | Local Status Feedback | ESP32 IoT Subsystem |
| **Sync Occupancy to Firebase** | Live Database Synchronization | ESP32 IoT Subsystem |
