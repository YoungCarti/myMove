# myMove Project Progress

## 1. What We Have Done (Completed)

*   **Foundation & Core Authentication (Phases 1 & 2):** Flutter/Firebase setup, user registration, login, and profile management are complete.
*   **Hardware Integration & Real-Time Sync (Phase 3):** The ESP32 firmware (`esp32_smart_parking.ino`) and ultrasonic sensor logic are built. We successfully merged real-time hardware data with Firestore booking data to resolve occupancy conflicts.
*   **Parking Search & Spot Selection (Phases 4 & 5):** Google Maps integration, real-time geolocation, custom markers, building details, and the interactive spot selection UI are finished.
*   **Booking System (Phase 6):** Full reservation flow (date/time, duration, fees) and active booking management (countdown timer, extend time) are working.
*   **Payment Integration (Phase 7):** Payment flows and states are currently simulated (mocked) to allow UI completion and testing without a live gateway.
*   **QR Code System (Phase 8):** Unique QR generation for vehicles and mobile scanner integration are fully operational.
*   **Communication Features (Phase 9):** Secure driver-to-driver in-app messaging and "Blocked-Car" alerts are implemented.
*   **Push Notifications Integration (Phase 10):** Fully integrated Firebase Cloud Messaging for foreground/background alerts on bookings and chat messages.
*   **Device Permissions Handling (Phase 11):** Fully implemented dynamic location, camera, and notification permission requests with interactive settings screens.

---

## 2. What We Doing Currently (Doing Gradually)

*   **VoIP Calling:** Implement VoIP for voice calling between drivers (since native phone calls rely on cellular towers), while keeping direct native phone calls as an optional fallback.
*   **Admin/Parking Management Module:** Build a simple admin panel or stick to manual Firebase entry for the FYP2 presentation.
    *   *Note on Emergency SOS:* Only admins/management should have the ability to resolve or change the status of an active emergency. This will be implemented later via the web fallback/dashboard.

**IN PROGRESS:**
*   **Emergency Mode:** Add quick-access features to send urgent alerts in emergencies.

## 3. What We Haven't Done (Pending & Future Features)
*   **Payment Integration:** Attempt to add actual Stripe or Touch 'n Go payments. If business registration causes delays, we will continue to use a simulated/mockup payment system.
*   **Identity Verification (IC and Face):** Implement e-KYC using on-device technology (e.g., Google ML Kit) to scan Identity Cards (IC) and detect faces for liveness without complex backend processing.
*   **Emergency Mode:** Add quick-access features to send urgent alerts in emergencies.
*   **User Feedback:** Create a dedicated space/form to allow users to leave feedback on their experience.
*   **App-less Web QR Scanning:** Update vehicle QR codes to use standard HTTPS URLs pointing to a Firebase-hosted webpage. This allows anyone (even without the app) to scan the code with their default camera and trigger a "Move Car" push notification to the owner.

### 🔮 Final Phases (To be tackled after feature completion)
*   **End-to-End Prototype Testing (Phase 12):** Final physical tests moving "toy cars" on the tabletop model while watching the Flutter UI react in real-time.
*   **Thesis & Deployment (Phases 13 & 14):** Writing the thesis documentation, creating the presentation materials, and preparing the final build.

### ❌ Out of Scope (Will not be built for FYP2)
*   *Hardware Automation:* Automatic barrier gate control or AI-based camera prediction.
*   *Legal Enforcement:* Summon generation or integrations with government operator APIs.