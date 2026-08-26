# 📋 Non-Functional Requirements Specification (Pages 30 & 31)

This section defines the non-functional requirements (NFRs) of the **myMove Smart Parking & Communication System**, specifying the quality attributes, constraints, performance metrics, and security guardrails of the implemented application.

---

## 1. Summary of Implemented Non-Functional Requirements

*   **Security & Data Privacy**: 
    *   Secure password hashing and token-based session management using **Firebase Authentication**.
    *   Strict database access controls using **Cloud Firestore Security Rules** to verify that users can only read/write their own profiles, vehicles, and bookings.
    *   Absolute user privacy in the communication flow: vehicle owner details (phone number, name, email) are kept completely hidden, and contact is established anonymously using only the vehicle's public QR identifier.
*   **Performance & Real-time Latency**:
    *   Physical-to-digital state synchronization: spot status updates from the physical **ESP32 sensor** to the cloud database (**Firebase RTDB**) and onto the driver's Flutter UI must reflect in under **1.5 seconds**.
    *   Chat responsiveness: End-to-end chat message delivery between the **web scanner guest** and **in-app driver** must take less than **1.0 second** under standard network conditions.
    *   Lightweight web footprint: The Web Guest scanner portal (`scanner-web`) must load and render in under **2.0 seconds** on mobile browsers without requiring registration or app installation.
*   **Reliability & Hardware Fault Tolerance**:
    *   Firmware self-healing: The **ESP32 microcontroller** firmware must feature an automated Wi-Fi and Firebase reconnection loop to recover gracefully from network drops without hardware resets.
    *   Sensor debounce algorithm: Proximity readings from the **HC-SR04 ultrasonic sensors** must be filtered using a multi-sample averaging algorithm on the ESP32 to eliminate false occupancy updates caused by transient obstructions (e.g., passing pedestrians).
    *   Concurrency conflict prevention: Parking reservation payments and status changes must execute as **Firestore Transactions** to prevent double-booking of a single slot by simultaneous users.
*   **Scalability & Database Efficiency**:
    *   Hierarchical data structure: The database schema in **Cloud Firestore** and **Firebase RTDB** must partition slots by `location_id` and `zone_id`, allowing the system to scale horizontally to support thousands of spots without query degradation.
    *   Optimized search indexes: Core read queries (e.g., scanning for nearby available parking spots) must be indexed to ensure low database read workloads and rapid response times.
*   **Usability & Accessibility**:
    *   Adaptability: Web pages (`scanner-web` and `admin-web`) must utilize responsive design layouts, adapting dynamically to mobile, tablet, and desktop viewports.
    *   Three-step guest flow: The blocked driver contact process must be completed within three simple taps (Scan QR -> Upload Photo/GPS -> Start Anonymous Chat) to minimize friction in high-stress parking situations.
*   **Compatibility & Platform Support**:
    *   Mobile operating systems: The Flutter application must run natively on **Android (API Level 21 / Android 5.0 and above)**.
    *   Web browsers: Both web interfaces must achieve full compatibility with modern browsers, including Google Chrome, Mozilla Firefox, and Microsoft Edge.
