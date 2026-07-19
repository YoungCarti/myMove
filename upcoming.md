# myMove Project Progress

## 1. What We Have Done (Completed)

*   **Foundation & Core Authentication (Phases 1 & 2):** Flutter/Firebase setup, user registration, login, and profile management are complete.
*   **Hardware Integration & Real-Time Sync (Phase 3):** The ESP32 firmware (`esp32_smart_parking.ino`) and ultrasonic sensor logic are built. We successfully merged real-time hardware data with Firestore booking data to resolve occupancy conflicts.
*   **Parking Search & Spot Selection (Phases 4 & 5):** Google Maps integration, real-time geolocation, custom markers, building details, and the interactive spot selection UI are finished.
*   **Booking System (Phase 6):** Full reservation flow (date/time, duration, fees) and active booking management (countdown timer, extend time) are working.
*   **Payment Integration (Phase 7):** Fully implemented backend-verified payment infrastructure using Stripe Payment Intents and Webhooks. This ensures secure server-side updates to Firestore booking statuses based on Stripe events.
*   **QR Code System (Phase 8):** Unique QR generation for vehicles and mobile scanner integration are fully operational.
*   **Communication Features (Phase 9):** Secure driver-to-driver in-app messaging and "Blocked-Car" alerts are implemented.
*   **Push Notifications Integration (Phase 10):** Fully integrated Firebase Cloud Messaging for foreground/background alerts on bookings and chat messages.
*   **Device Permissions Handling (Phase 11):** Fully implemented dynamic location, camera, and notification permission requests with interactive settings screens.
*   **Emergency Mode (Phase 12):** Built quick-access features for users to send urgent SOS alerts, alongside real-time admin notification and resolution controls in the web dashboard.
*   **Admin/Parking Management Dashboard (Phase 13):** Built a full React web dashboard for admins to manage parking spots, track real-time revenue analytics, resolve emergency alerts, and send global broadcast push notifications.
*   **VoIP Calling (Phase 14):** Implemented full bidirectional VoIP voice calling between drivers using the Agora RTC Engine, complete with server-generated dynamic connection tokens via Cloud Functions and push-notification based incoming call routing.

---

## 2. What We Doing Currently (Doing Gradually)

*   (Reviewing pending features to transition into the next phase)

## 3. What We Haven't Done (Pending & Future Features)
*   **App-less Web QR Scanning:** Update vehicle QR codes to use standard HTTPS URLs pointing to a Firebase-hosted webpage. This allows anyone (even without the app) to scan the code with their default camera and trigger a "Move Car" push notification to the owner.

### 🔮 Final Phases (To be tackled after feature completion)
*   **End-to-End Prototype Testing (Phase 12):** Final physical tests moving "toy cars" on the tabletop model while watching the Flutter UI react in real-time.
*   **Thesis & Deployment (Phases 13 & 14):** Writing the thesis documentation, creating the presentation materials, and preparing the final build.

### ❌ Out of Scope (Will not be built for FYP2)
*   *Hardware Automation:* Automatic barrier gate control or AI-based camera prediction.
*   *Legal Enforcement:* Summon generation or integrations with government operator APIs.