# Project Design Report (PDR)

## Project Title

**myMove: Smart Parking Communication App**

## Student Name

**Saabiresh Letchumanan**

## Programme

**Bachelor of Computer Science**

## Project Type

**Final Year Project 2 (FYP2) Implementation**

## Proposed Platform

**Mobile Application with IoT-Based Tabletop Prototype**

## Development Approach

**Waterfall Model**

---

# 1. Executive Summary

myMove is a smart parking communication mobile application designed to improve parking management and driver-to-driver communication, especially in double-parking situations. The project focuses on solving common parking issues in Malaysia, including difficulty finding available parking, lack of clear parking details, limited communication between drivers, and inconvenience caused by blocked vehicles.

The proposed system provides a mobile application that allows users to register their vehicles, search for parking locations, view parking availability, reserve parking, manage bookings, and use a QR code-based communication system. The QR code feature enables a blocked driver to contact the vehicle owner through the application without exposing personal phone numbers. This improves privacy, safety, and convenience compared to traditional methods such as leaving a phone number on the windshield.

For FYP2, the project moves from the research and design phase into implementation. The application will be developed using Flutter for the frontend and Firebase for backend services such as authentication, database storage, notifications, and real-time updates. In addition, a small tabletop smart parking prototype using ESP32 and ultrasonic sensors will be developed to demonstrate parking occupancy detection.

The final system will consist of a mobile application, Firebase backend, QR communication module, parking search and booking module, and a physical prototype that represents parking lot availability using sensors and LED indicators.

---

# 2. Introduction

Parking problems are common in urban areas, shopping malls, universities, office buildings, and residential areas. Drivers often face difficulties finding available parking spaces, identifying exact parking locations, and contacting vehicle owners when their cars are blocked due to double parking. In many situations, drivers leave phone numbers on their car windshields, which creates privacy and safety concerns.

myMove aims to provide a smart and privacy-focused solution to these problems. The system combines parking management features with a communication feature that allows drivers to contact each other through a QR code system. Instead of exposing personal phone numbers, the QR code allows communication through the app using alerts, messages, and possibly VoIP calling in future versions.

The project also introduces a simple IoT-based smart parking prototype using ESP32 and ultrasonic sensors. The purpose of the hardware prototype is to demonstrate how parking occupancy can be detected and sent to the system, allowing the mobile application to display real-time parking availability.

---

# 3. Background of the Project

In many parking areas, drivers experience several issues. These include not knowing whether parking spaces are available, wasting time searching for parking, unclear information about parking floor or lot number, and being blocked by double-parked vehicles. Double parking is especially frustrating because the blocked driver may not have a reliable or safe way to contact the vehicle owner.

Traditional solutions such as leaving a phone number on the dashboard are simple but not secure. Phone numbers can be misused, photographed, or contacted by unknown individuals. Existing parking applications usually focus on parking payment, location search, or enforcement, but many do not fully solve the communication gap between blocked drivers and vehicle owners.

myMove addresses this gap by combining parking availability, reservation, digital parking details, and QR-based communication into one system. The project supports both software-based parking management and a small IoT demonstration for smart parking detection.

---

# 4. Problem Statement

Drivers in Malaysia often face difficulty finding available parking spaces due to limited real-time parking information. Many parking areas do not provide detailed information such as building name, floor level, lot number, fee, or parking duration. This causes drivers to waste time, increase traffic congestion around parking areas, and experience frustration.

Another major issue is double parking. When a vehicle blocks another car, the blocked driver may not be able to contact the vehicle owner easily. Some drivers leave their phone numbers on the windshield, but this exposes personal information and may create privacy or security risks. In some cases, there is no contact information at all, causing delays and inconvenience.

Existing systems may provide parking payment, enforcement, or basic parking information, but they do not fully address secure driver-to-driver communication for double-parking situations. Therefore, a smart parking communication system is needed to allow drivers to search for parking, view parking details, reserve spaces, and contact vehicle owners safely through a QR code-based platform.

---

# 5. Project Aim

The aim of this project is to design and implement a smart parking communication mobile application that helps drivers find parking, manage bookings, and communicate securely during double-parking situations using QR codes, while also demonstrating parking occupancy detection through an ESP32-based tabletop prototype.

---

# 6. Project Objectives

The objectives of this project are:

1. To develop a mobile application that allows users to register, log in, manage profiles, and register their vehicles.

2. To implement a QR code-based vehicle communication system that allows blocked drivers to contact vehicle owners without exposing personal phone numbers.

3. To provide parking search, parking details, availability display, and reservation features for users.

4. To integrate Firebase as the backend platform for authentication, database management, real-time updates, and notifications.

5. To build a tabletop smart parking prototype using ESP32 and ultrasonic sensors to demonstrate parking space occupancy detection.

6. To test and evaluate the system based on functionality, usability, reliability, and system performance.

---

# 7. Project Scope

## 7.1 In Scope

The project will include the following components:

- Mobile application developed using Flutter.
- Firebase Authentication for user login and registration.
- Firestore or Realtime Database for storing users, vehicles, parking areas, parking slots, bookings, messages, and QR data.
- Vehicle registration module.
- QR code generation for registered vehicles.
- QR code scanning to identify vehicle owner contact flow.
- In-app alert or message system for blocked vehicle communication.
- Parking search and parking details module.
- Parking reservation and booking management module.
- Basic digital payment status simulation.
- Parking history and booking history.
- Notifications for booking reminders or blocked-car alerts.
- ESP32-based tabletop prototype with parking slots.
- Ultrasonic sensor-based vehicle detection.
- LED indicators for parking slot availability.
- Firebase integration between ESP32 and mobile app for parking availability updates.
- Testing and documentation.

## 7.2 Out of Scope

The project will not fully implement the following advanced features unless time permits:

- Real payment gateway integration with banks or e-wallets.
- Full-scale deployment in real parking buildings.
- Official government or parking operator integration.
- Advanced identity verification using IC or facial recognition.
- Full VoIP calling system using WebRTC.
- Large-scale sensor deployment.
- AI-based parking prediction.
- Automatic barrier gate control.
- Legal enforcement or summon generation.

These features may be proposed as future enhancements.

---

# 8. Target Users

The target users of myMove include:

- Drivers who frequently use public, private, mall, university, or office parking areas.
- Drivers who experience double-parking issues.
- Parking lot operators who want to improve parking management.
- Building management teams.
- University or campus parking users.
- Shopping mall visitors.
- Residential parking users.

---

# 9. Stakeholders

The main stakeholders are:

- System users / drivers.
- Vehicle owners.
- Parking lot operators.
- Building management.
- Project supervisor.
- University evaluators.
- Future developers or system maintainers.

---

# 10. Proposed Solution

The proposed solution is a mobile application called myMove. The system allows users to create an account, register their vehicle, and generate a unique QR code for the vehicle. This QR code can be placed on the car windshield. If another driver is blocked by the vehicle, they can scan the QR code using the application. The system will then notify the vehicle owner or allow the blocked driver to send a message through the app.

The application also provides parking-related features such as searching for parking areas, viewing available parking slots, checking parking details, reserving a parking space, and viewing booking history. Firebase will be used as the backend to store user data, vehicle data, bookings, messages, parking slot information, and notifications.

For demonstration, an ESP32-based physical prototype will be built using a shoebox/tabletop parking model. Ultrasonic sensors will detect whether a parking slot is occupied. LED indicators will show whether a slot is available or occupied. The ESP32 will send parking slot status to Firebase, and the mobile app will display the updated availability.

---

# 11. System Overview

The myMove system consists of four main parts:

1. **Mobile Application**

   The mobile application is used by drivers to access all system functions, including authentication, vehicle registration, QR code generation, parking search, booking, and communication.

2. **Firebase Backend**

   Firebase stores and manages user accounts, vehicle records, parking data, bookings, messages, notifications, and real-time parking availability.

3. **QR Code Communication System**

   Each registered vehicle has a unique QR code. When scanned, the system identifies the vehicle owner and allows secure communication without revealing the owner's phone number.

4. **ESP32 Smart Parking Prototype**

   The physical prototype uses sensors to detect parking occupancy and updates the parking slot status in Firebase.

---

# 12. System Modules

## 12.1 User Authentication Module

This module allows users to register and log in to the application. Firebase Authentication will be used to manage user accounts securely.

### Functions

- User registration.
- User login.
- Password reset.
- Logout.
- Authentication state checking.

### Data Stored

- User ID.
- Full name.
- Email address.
- Phone number.
- Profile image URL.
- Account creation date.

---

## 12.2 User Profile Module

This module allows users to manage their personal profile.

### Functions

- View profile.
- Edit profile.
- Update phone number.
- Update profile photo.
- Manage account settings.

---

## 12.3 Vehicle Registration Module

This module allows users to add and manage their vehicles.

### Functions

- Add vehicle.
- Edit vehicle details.
- Delete vehicle.
- View registered vehicles.
- Link vehicle to QR code.

### Vehicle Data

- Vehicle ID.
- Owner user ID.
- Plate number.
- Vehicle brand.
- Vehicle model.
- Vehicle colour.
- Vehicle type.
- QR code ID.
- Created date.

---

## 12.4 QR Code Generation Module

This module generates a unique QR code for each registered vehicle.

### Functions

- Generate QR code.
- Display QR code in the app.
- Download or save QR code.
- Regenerate QR code if needed.
- Link QR code to vehicle record.

### Purpose

The QR code is placed on the vehicle. When another user scans the code, the system identifies the vehicle and enables secure communication with the owner.

---

## 12.5 QR Code Scanning Module

This module allows blocked drivers to scan a QR code attached to another vehicle.

### Functions

- Scan vehicle QR code.
- Retrieve vehicle owner information securely.
- Display limited vehicle details.
- Send blocked-car alert.
- Start in-app chat.
- Prevent phone number exposure.

---

## 12.6 Blocked-Car Alert Module

This module allows a driver to notify a vehicle owner that their car is blocking another vehicle.

### Functions

- Send alert to vehicle owner.
- Display alert notification.
- Allow owner to respond.
- Store alert history.
- Mark alert as resolved.

### Example Alert Message

“Your vehicle is blocking another car. Please move your vehicle as soon as possible.”

---

## 12.7 In-App Chat Module

This module enables communication between the blocked driver and the vehicle owner.

### Functions

- Start chat after QR scan.
- Send and receive text messages.
- Show message timestamp.
- Store chat history.
- Close chat after issue is resolved.

### Privacy Feature

Phone numbers are not shown to either user. Communication happens inside the app.

---

## 12.8 Parking Search Module

This module allows users to search for parking locations.

### Functions

- Search parking by location name.
- View nearby parking areas.
- Filter parking by availability.
- View parking fees.
- View operating hours.
- Select parking area.

---

## 12.9 Parking Details Module

This module shows detailed information about a selected parking area.

### Information Displayed

- Parking area name.
- Building name.
- Address.
- Floor level.
- Total parking slots.
- Available slots.
- Occupied slots.
- Parking fee.
- Operating hours.
- Navigation option.

---

## 12.10 Parking Slot Availability Module

This module displays real-time or simulated parking slot availability.

### Functions

- Show available slots.
- Show occupied slots.
- Update parking status from Firebase.
- Update parking status from ESP32 prototype.
- Display red/green availability indicators.

---

## 12.11 Parking Reservation Module

This module allows users to reserve a parking slot.

### Functions

- Select parking area.
- Select date and time.
- Reserve available parking slot.
- Confirm booking.
- Cancel booking.
- View active booking.

---

## 12.12 Booking Management Module

This module allows users to manage their parking bookings.

### Functions

- View current bookings.
- View past bookings.
- Cancel booking.
- Extend parking time.
- View booking status.

### Booking Status Examples

- Pending.
- Confirmed.
- Active.
- Completed.
- Cancelled.

---

## 12.13 Payment Status Module

This module will simulate or record payment status for bookings.

### Functions

- View parking fee.
- Confirm payment status.
- Store payment record.
- Display paid or unpaid booking status.

### Note

For FYP2, real payment gateway integration may be simulated due to time, cost, and verification limitations.

---

## 12.14 Notification Module

This module sends important updates to users.

### Notification Types

- Blocked-car alert.
- New chat message.
- Booking confirmation.
- Booking reminder.
- Parking time reminder.
- Parking reservation cancellation.

### Firebase Service

Firebase Cloud Messaging may be used for push notifications.

---

## 12.15 Admin or Parking Management Module

This module can be used to manage parking areas and slot data.

### Functions

- Add parking area.
- Edit parking details.
- Add parking slots.
- Update parking slot status.
- View booking list.
- Manage parking availability.

### Implementation Option

This can be implemented as a simple admin section inside the mobile app or through manual Firebase data entry for the prototype.

---

## 12.16 ESP32 Smart Parking Prototype Module

This module demonstrates how physical parking slots can be detected using sensors.

### Components

- ESP32 development board.
- HC-SR04 ultrasonic sensors.
- Breadboard.
- Jumper wires.
- Red LEDs.
- Green LEDs.
- Resistors.
- Shoebox/tabletop model.
- Toy cars.

### Functions

- Detect whether a parking slot is occupied.
- Show occupied status using red LED.
- Show available status using green LED.
- Send slot status to Firebase.
- Display updated slot status in Flutter app.

---

# 13. Functional Requirements

## FR1: User Registration

The system shall allow new users to create an account using email, password, and basic profile details.

## FR2: User Login

The system shall allow registered users to log in using valid credentials.

## FR3: Vehicle Registration

The system shall allow users to register one or more vehicles under their account.

## FR4: QR Code Generation

The system shall generate a unique QR code for each registered vehicle.

## FR5: QR Code Scanning

The system shall allow users to scan a vehicle QR code to contact the vehicle owner.

## FR6: Blocked-Car Alert

The system shall allow a blocked driver to send an alert to the vehicle owner.

## FR7: In-App Messaging

The system shall allow users to communicate through in-app messaging after a QR code scan.

## FR8: Parking Search

The system shall allow users to search and view parking locations.

## FR9: Parking Details

The system shall display parking information such as location, floor, lot availability, fee, and operating hours.

## FR10: Parking Reservation

The system shall allow users to reserve an available parking slot.

## FR11: Booking Management

The system shall allow users to view, cancel, and manage their bookings.

## FR12: Parking Availability

The system shall display available and occupied parking slots.

## FR13: ESP32 Sensor Update

The ESP32 prototype shall update parking slot status based on sensor readings.

## FR14: Notifications

The system shall notify users about alerts, messages, and booking updates.

## FR15: Logout

The system shall allow users to log out securely.

---

# 14. Non-Functional Requirements

## 14.1 Usability

The application should be simple and easy to use. Users should be able to complete major tasks such as scanning a QR code, sending an alert, and reserving parking with minimal steps.

## 14.2 Security

The system should protect user data and avoid exposing sensitive information such as phone numbers. Firebase Authentication and Firestore security rules should be used to restrict unauthorized access.

## 14.3 Privacy

The QR communication feature should allow users to contact vehicle owners without showing personal phone numbers to strangers.

## 14.4 Reliability

The system should store data correctly and maintain accurate records for users, vehicles, bookings, and messages.

## 14.5 Performance

The application should respond quickly when loading parking data, scanning QR codes, sending messages, and updating parking availability.

## 14.6 Maintainability

The code should be organized into clear folders and modules so that future improvements can be made easily.

## 14.7 Scalability

The Firebase database structure should support future expansion, such as more parking locations, more users, and additional smart parking sensors.

## 14.8 Compatibility

The mobile application should be compatible with Android devices. iOS support can be considered as future work.

---

# 15. System Architecture

The system architecture consists of the following layers:

## 15.1 Presentation Layer

This layer is the Flutter mobile application interface. It includes screens such as login, register, home, vehicle registration, QR generation, QR scanner, chat, parking search, parking details, booking, and profile.

## 15.2 Application Logic Layer

This layer contains the business logic of the app, including authentication handling, vehicle management, QR processing, booking validation, chat handling, and notification triggers.

## 15.3 Backend Layer

Firebase acts as the backend layer. It handles authentication, database storage, real-time updates, notifications, and possibly file storage.

## 15.4 IoT Layer

The ESP32 and sensors form the IoT layer. This layer detects parking slot status and sends updates to Firebase.

## 15.5 Data Layer

The data layer stores structured information such as users, vehicles, parking areas, parking slots, bookings, chats, messages, and notifications.

---

# 16. Technology Stack

## 16.1 Frontend

- Flutter.
- Dart.
- Material Design widgets.
- QR scanner package.
- QR generator package.
- Firebase Flutter packages.

## 16.2 Backend

- Firebase Authentication.
- Cloud Firestore.
- Firebase Realtime Database, if needed for IoT real-time updates.
- Firebase Cloud Messaging.
- Firebase Storage, if profile images are included.
- Firebase Cloud Functions, if needed for backend automation.

## 16.3 Hardware

- ESP32 development board.
- HC-SR04 ultrasonic sensors.
- LEDs.
- Resistors.
- Breadboard.
- Jumper wires.
- Shoebox/tabletop parking model.

## 16.4 Development Tools

- Android Studio or Visual Studio Code.
- Flutter SDK.
- Firebase Console.
- Arduino IDE.
- Git and GitHub.
- Figma for UI reference.

---

# 17. Proposed Database Design

## 17.1 users Collection

```text
users/{userId}
```

### Fields

```text
userId: string
fullName: string
email: string
phoneNumber: string
profileImageUrl: string
createdAt: timestamp
updatedAt: timestamp
```

---

## 17.2 vehicles Collection

```text
vehicles/{vehicleId}
```

### Fields

```text
vehicleId: string
ownerId: string
plateNumber: string
brand: string
model: string
colour: string
vehicleType: string
qrCodeId: string
isActive: boolean
createdAt: timestamp
updatedAt: timestamp
```

---

## 17.3 qrCodes Collection

```text
qrCodes/{qrCodeId}
```

### Fields

```text
qrCodeId: string
vehicleId: string
ownerId: string
qrValue: string
status: string
createdAt: timestamp
updatedAt: timestamp
```

---

## 17.4 parkingAreas Collection

```text
parkingAreas/{parkingAreaId}
```

### Fields

```text
parkingAreaId: string
name: string
buildingName: string
address: string
latitude: number
longitude: number
totalSlots: number
availableSlots: number
occupiedSlots: number
feePerHour: number
operatingHours: string
createdAt: timestamp
updatedAt: timestamp
```

---

## 17.5 parkingSlots Collection

```text
parkingSlots/{slotId}
```

### Fields

```text
slotId: string
parkingAreaId: string
floor: string
slotNumber: string
status: string
sensorId: string
lastUpdated: timestamp
```

### Slot Status

```text
available
occupied
reserved
maintenance
```

---

## 17.6 bookings Collection

```text
bookings/{bookingId}
```

### Fields

```text
bookingId: string
userId: string
vehicleId: string
parkingAreaId: string
slotId: string
bookingDate: timestamp
startTime: timestamp
endTime: timestamp
status: string
paymentStatus: string
totalAmount: number
createdAt: timestamp
updatedAt: timestamp
```

### Booking Status

```text
pending
confirmed
active
completed
cancelled
```

---

## 17.7 alerts Collection

```text
alerts/{alertId}
```

### Fields

```text
alertId: string
senderId: string
receiverId: string
vehicleId: string
message: string
status: string
createdAt: timestamp
resolvedAt: timestamp
```

### Alert Status

```text
sent
seen
responded
resolved
```

---

## 17.8 chats Collection

```text
chats/{chatId}
```

### Fields

```text
chatId: string
vehicleId: string
blockedDriverId: string
vehicleOwnerId: string
lastMessage: string
lastMessageAt: timestamp
status: string
createdAt: timestamp
```

---

## 17.9 messages Subcollection

```text
chats/{chatId}/messages/{messageId}
```

### Fields

```text
messageId: string
senderId: string
receiverId: string
messageText: string
createdAt: timestamp
isRead: boolean
```

---

## 17.10 notifications Collection

```text
notifications/{notificationId}
```

### Fields

```text
notificationId: string
userId: string
title: string
body: string
type: string
referenceId: string
isRead: boolean
createdAt: timestamp
```

---

# 18. User Interface Design

The mobile application will include the following main screens:

## 18.1 Splash Screen

Displays the myMove logo and loads authentication status.

## 18.2 Onboarding Screen

Introduces the main purpose of the app, including parking search and QR-based communication.

## 18.3 Login Screen

Allows existing users to log in.

## 18.4 Register Screen

Allows new users to create an account.

## 18.5 Home Dashboard

Displays quick access to parking search, QR scanner, vehicle list, bookings, and alerts.

## 18.6 Vehicle List Screen

Displays all vehicles registered by the user.

## 18.7 Add Vehicle Screen

Allows the user to register vehicle information.

## 18.8 Vehicle QR Code Screen

Displays the QR code linked to the selected vehicle.

## 18.9 QR Scanner Screen

Allows a user to scan another vehicle’s QR code.

## 18.10 Blocked Vehicle Contact Screen

Allows the user to send an alert or start a chat with the vehicle owner.

## 18.11 Chat Screen

Allows communication between two users without exposing phone numbers.

## 18.12 Parking Search Screen

Allows users to search for parking areas.

## 18.13 Parking Details Screen

Displays parking information and available slots.

## 18.14 Reservation Screen

Allows users to reserve a parking slot.

## 18.15 Booking History Screen

Displays current and past bookings.

## 18.16 Notification Screen

Displays blocked-car alerts, booking reminders, and message notifications.

## 18.17 Profile Screen

Allows users to view and edit their account information.

---

# 19. Use Case Description

## 19.1 Use Case: Register Account

### Actor

User / Driver

### Description

The user creates a new account to access the myMove system.

### Main Flow

1. User opens the app.
2. User selects register.
3. User enters name, email, phone number, and password.
4. System validates the input.
5. System creates account using Firebase Authentication.
6. System stores profile information in Firestore.
7. User is redirected to the home dashboard.

---

## 19.2 Use Case: Register Vehicle

### Actor

User / Driver

### Description

The user registers a vehicle under their account.

### Main Flow

1. User opens vehicle section.
2. User selects add vehicle.
3. User enters plate number, brand, model, colour, and vehicle type.
4. System stores vehicle data in Firestore.
5. System creates or links a QR code to the vehicle.
6. Vehicle appears in the user’s vehicle list.

---

## 19.3 Use Case: Generate QR Code

### Actor

Vehicle Owner

### Description

The user generates a unique QR code for a registered vehicle.

### Main Flow

1. User selects a registered vehicle.
2. User taps generate QR code.
3. System creates a unique QR code value.
4. System stores QR code data in Firestore.
5. App displays the QR code.
6. User can print or place the QR code on the vehicle.

---

## 19.4 Use Case: Scan QR Code for Double Parking

### Actor

Blocked Driver

### Description

A blocked driver scans the QR code on a vehicle to contact the owner.

### Main Flow

1. Blocked driver opens QR scanner.
2. Driver scans the QR code on the blocking vehicle.
3. System retrieves vehicle and owner information.
4. System displays safe contact options.
5. Driver sends blocked-car alert or starts chat.
6. Vehicle owner receives notification.

---

## 19.5 Use Case: Send Blocked-Car Alert

### Actor

Blocked Driver

### Description

The blocked driver sends an alert to notify the vehicle owner.

### Main Flow

1. Driver scans QR code.
2. Driver taps “Send Alert”.
3. System creates alert record.
4. System sends notification to vehicle owner.
5. Vehicle owner views alert.
6. Alert is marked as seen or resolved.

---

## 19.6 Use Case: Search Parking

### Actor

User / Driver

### Description

The user searches for available parking areas.

### Main Flow

1. User opens parking search screen.
2. User enters location or selects nearby parking.
3. System retrieves matching parking areas.
4. User selects a parking area.
5. System displays parking details and availability.

---

## 19.7 Use Case: Reserve Parking

### Actor

User / Driver

### Description

The user reserves an available parking space.

### Main Flow

1. User selects parking area.
2. User views available slots.
3. User selects slot, date, and time.
4. System validates availability.
5. User confirms reservation.
6. System creates booking record.
7. Slot status changes to reserved.

---

# 20. Hardware Prototype Design

## 20.1 Prototype Concept

The physical prototype will represent a small parking area using a shoebox or tabletop model. The model will contain four parking spaces and a road layout printed on paper and glued to the shoebox. Toy cars will be used to represent vehicles.

Each parking space can be connected to an ultrasonic sensor that detects whether a toy car is present. If the space is occupied, the system will show a red LED and update the slot status as occupied. If the space is empty, the system will show a green LED and update the slot status as available.

## 20.2 Parking Layout

The prototype layout will include:

- Road entrance.
- Road exit.
- Four parking spaces.
- Parking slot labels.
- Sensor placement area.
- LED indicators.
- ESP32 mounting position.
- Power supply position.

## 20.3 Hardware Components

| Component | Purpose |
|---|---|
| ESP32 | Main microcontroller for sensor reading and WiFi connection |
| HC-SR04 Ultrasonic Sensor | Detects whether a parking space is occupied |
| Red LED | Indicates occupied parking slot |
| Green LED | Indicates available parking slot |
| Resistors | Protect LEDs and create voltage divider for HC-SR04 echo pin |
| Breadboard | For circuit connections |
| Jumper Wires | For connecting components |
| Shoebox | Physical base for prototype |
| Toy Cars | Used to demonstrate occupancy |

## 20.4 Safety and Wiring Notes

The ESP32 GPIO pins support 3.3V logic. The HC-SR04 echo pin outputs 5V, so the echo pin should not be connected directly to the ESP32 GPIO. A voltage divider or level shifter should be used to reduce the echo signal to a safe 3.3V level.

LEDs should be connected with resistors to prevent excessive current draw. The prototype should be tested step by step, starting with ESP32 blink test, then sensor trigger test, then full distance reading, then Firebase integration.

## 20.5 Suggested ESP32 Pin Mapping

| Function | ESP32 GPIO |
|---|---|
| Sensor 1 TRIG | GPIO 5 |
| Sensor 1 ECHO | GPIO 18 through voltage divider |
| Sensor 2 TRIG | GPIO 19 |
| Sensor 2 ECHO | GPIO 21 through voltage divider |
| Sensor 3 TRIG | GPIO 22 |
| Sensor 3 ECHO | GPIO 23 through voltage divider |
| Sensor 4 TRIG | GPIO 25 |
| Sensor 4 ECHO | GPIO 26 through voltage divider |
| Green LED Slot 1 | GPIO 13 |
| Red LED Slot 1 | GPIO 12 |
| Green LED Slot 2 | GPIO 14 |
| Red LED Slot 2 | GPIO 27 |

The final pin selection may be adjusted based on the available ESP32 board and wiring convenience.

---

# 21. IoT Data Flow

The IoT data flow is as follows:

1. Ultrasonic sensor measures distance.
2. ESP32 checks whether the distance is below the occupancy threshold.
3. If a vehicle is detected, the slot status becomes occupied.
4. If no vehicle is detected, the slot status becomes available.
5. ESP32 updates the parking slot status in Firebase.
6. Flutter app reads updated slot status from Firebase.
7. User sees real-time parking availability in the app.

---

# 22. Firebase Integration Design

Firebase will be used to connect all system components.

## 22.1 Firebase Authentication

Used for:

- User registration.
- User login.
- Authentication state management.
- Secure access to user-specific data.

## 22.2 Cloud Firestore

Used for storing:

- User profiles.
- Vehicle information.
- QR code records.
- Parking areas.
- Parking slots.
- Bookings.
- Alerts.
- Chats.
- Notifications.

## 22.3 Realtime Database

May be used for:

- ESP32 parking slot status updates.
- Real-time sensor data.

## 22.4 Firebase Cloud Messaging

Used for:

- Blocked-car alerts.
- Chat message notifications.
- Booking reminders.

## 22.5 Firebase Storage

May be used for:

- Profile images.
- Vehicle images.
- QR code image storage, if needed.

---

# 23. Security Design

## 23.1 Authentication Security

Only authenticated users can access the main system features.

## 23.2 Data Access Control

Firestore security rules should ensure:

- Users can only edit their own profile.
- Users can only manage their own vehicles.
- Users can only view chats they are part of.
- Users cannot edit other users’ bookings.
- Parking slot updates from ESP32 should be restricted using secure credentials or controlled database rules.

## 23.3 QR Code Security

The QR code should not store direct personal information. It should only store a unique QR code ID or vehicle reference ID. The app will use that ID to retrieve safe and limited information.

## 23.4 Privacy Protection

The system should hide phone numbers by default. Communication should happen through in-app messages and alerts.

---

# 24. Proposed Folder Structure for Flutter

```text
lib/
  main.dart
  app.dart
  config/
    firebase_options.dart
    app_routes.dart
    app_theme.dart
  models/
    user_model.dart
    vehicle_model.dart
    parking_area_model.dart
    parking_slot_model.dart
    booking_model.dart
    alert_model.dart
    chat_model.dart
    message_model.dart
  services/
    auth_service.dart
    user_service.dart
    vehicle_service.dart
    qr_service.dart
    parking_service.dart
    booking_service.dart
    chat_service.dart
    notification_service.dart
  screens/
    splash/
    onboarding/
    auth/
    home/
    vehicles/
    qr/
    parking/
    bookings/
    chat/
    notifications/
    profile/
  widgets/
    custom_button.dart
    custom_text_field.dart
    parking_card.dart
    vehicle_card.dart
    booking_card.dart
  utils/
    validators.dart
    constants.dart
```

---

# 25. Implementation Plan

## Phase 1: Project Setup

- Set up Flutter project.
- Connect project to Firebase.
- Configure Android app.
- Install required packages.
- Create folder structure.
- Set up GitHub repository.

## Phase 2: Authentication

- Build splash screen.
- Build login screen.
- Build registration screen.
- Connect Firebase Authentication.
- Store user profile in Firestore.

## Phase 3: Vehicle and QR Module

- Build vehicle list screen.
- Build add vehicle screen.
- Store vehicle data in Firestore.
- Generate QR code for vehicle.
- Build QR display screen.
- Build QR scanner screen.

## Phase 4: Double-Parking Communication

- Build blocked-car contact screen.
- Implement alert sending.
- Implement alert receiving.
- Build chat screen.
- Store messages in Firestore.
- Add notification support.

## Phase 5: Parking Management

- Create parking area data.
- Build parking search screen.
- Build parking details screen.
- Display parking availability.
- Build reservation screen.
- Build booking history screen.

## Phase 6: ESP32 Prototype

- Design shoebox parking layout.
- Connect ESP32 with sensors and LEDs.
- Test sensor distance reading.
- Detect occupied and available status.
- Send status to Firebase.
- Display sensor status in Flutter app.

## Phase 7: Testing and Evaluation

- Conduct unit testing.
- Conduct integration testing.
- Conduct usability testing.
- Test Firebase read/write operations.
- Test QR scanning flow.
- Test sensor detection.
- Fix bugs.

## Phase 8: Documentation and Demo Preparation

- Prepare final report.
- Prepare screenshots.
- Prepare system architecture diagram.
- Prepare database diagram.
- Prepare demo video or live demonstration.
- Prepare final presentation slides.

---

# 26. Project Timeline

| Week | Task |
|---|---|
| Week 1 | Confirm requirements, finalize FYP2 scope, set up Flutter and Firebase |
| Week 2 | Implement authentication and user profile |
| Week 3 | Build vehicle registration and QR code generation |
| Week 4 | Build QR scanning and blocked-car alert flow |
| Week 5 | Implement in-app chat and notifications |
| Week 6 | Build parking search and parking details screens |
| Week 7 | Implement parking reservation and booking history |
| Week 8 | Prepare parking data and Firebase database rules |
| Week 9 | Build ESP32 prototype layout and basic sensor test |
| Week 10 | Connect ESP32 sensor status to Firebase |
| Week 11 | Integrate Flutter app with IoT parking availability |
| Week 12 | System testing and bug fixing |
| Week 13 | Usability testing and evaluation |
| Week 14 | Final report writing and demo preparation |

---

# 27. Testing Plan

## 27.1 Unit Testing

Unit testing will be used to test individual functions such as form validation, authentication logic, QR code generation, booking validation, and data model conversion.

## 27.2 Integration Testing

Integration testing will be used to test communication between Flutter and Firebase, QR scanning and Firestore retrieval, chat messaging, booking creation, and ESP32 Firebase updates.

## 27.3 System Testing

System testing will verify that the full application works as expected from user registration to vehicle QR scanning, parking search, reservation, and parking availability updates.

## 27.4 Usability Testing

Usability testing will be conducted with selected users to evaluate whether the app is easy to use and whether the QR communication feature is understandable.

## 27.5 Hardware Testing

Hardware testing will verify ultrasonic sensor readings, LED indicators, ESP32 WiFi connection, Firebase update success, and parking occupancy status accuracy.

---

# 28. Test Cases

| Test Case ID | Test Scenario | Expected Result |
|---|---|---|
| TC01 | Register new account | User account is created successfully |
| TC02 | Login with valid credentials | User is redirected to home dashboard |
| TC03 | Login with invalid credentials | Error message is displayed |
| TC04 | Add vehicle | Vehicle data is stored in Firestore |
| TC05 | Generate QR code | QR code is generated and linked to vehicle |
| TC06 | Scan valid QR code | Vehicle contact screen is displayed |
| TC07 | Scan invalid QR code | Error message is displayed |
| TC08 | Send blocked-car alert | Vehicle owner receives alert |
| TC09 | Send chat message | Message appears in chat screen |
| TC10 | Search parking area | Matching parking areas are displayed |
| TC11 | View parking details | Parking details and slot availability are displayed |
| TC12 | Reserve parking slot | Booking is created and slot status updates |
| TC13 | Cancel booking | Booking status changes to cancelled |
| TC14 | Sensor detects toy car | Parking slot status changes to occupied |
| TC15 | Toy car removed | Parking slot status changes to available |

---

# 29. Risk Analysis

| Risk | Impact | Mitigation |
|---|---|---|
| Firebase integration issues | App may not store or retrieve data properly | Test each Firebase feature step by step |
| Flutter build errors | Development delay | Use stable Flutter SDK and clear project setup |
| QR scanner package issue | QR feature may fail | Test different QR packages if needed |
| ESP32 connection issue | Hardware demo may not update Firebase | Test WiFi and Firebase separately before full integration |
| Sensor inaccurate reading | Wrong parking status | Calibrate distance threshold and test multiple times |
| Lack of components | Hardware progress delay | Prepare required resistors, wires, sensors, and backup parts early |
| Time limitation | Some features may be incomplete | Prioritize core MVP features first |
| Notification setup complexity | Push alerts may not work fully | Use in-app notification records as fallback |
| Payment gateway limitation | Real payment may not be possible | Use simulated payment status for FYP2 |

---

# 30. Expected Outcome

The expected outcome of this project is a functional smart parking communication mobile application with the following capabilities:

- Users can register and log in.
- Users can manage their profile.
- Users can register vehicles.
- Each vehicle can have a unique QR code.
- Blocked drivers can scan QR codes to send alerts or messages.
- Vehicle owners can receive blocked-car notifications.
- Users can search for parking areas.
- Users can view parking availability and details.
- Users can reserve parking slots.
- Users can view booking history.
- ESP32 prototype can detect parking slot occupancy.
- Firebase can store and update parking slot status.
- Flutter app can display updated parking availability.

The final prototype will demonstrate how myMove can improve driver communication, reduce inconvenience during double parking, and support smarter parking management.

---

# 31. Future Enhancements

The following features can be added in future development:

- Real payment gateway integration.
- Full VoIP calling system.
- Identity verification using IC or facial recognition.
- AI-based parking prediction.
- Integration with city councils or parking operators.
- Automatic barrier gate control.
- License plate recognition.
- Admin web dashboard.
- Advanced analytics for parking operators.
- Multi-language support.
- iOS version.
- Larger real-world sensor deployment.

---

# 32. Conclusion

myMove is designed to solve real parking problems by combining parking management, QR-based driver communication, and smart parking availability detection. The project improves the traditional method of contacting vehicle owners by replacing exposed phone numbers with a safer in-app communication system. It also supports parking search, reservation, booking management, and IoT-based occupancy detection.

For FYP2, the focus is on implementing the system using Flutter, Firebase, and ESP32. The software application will demonstrate the main user flow, while the tabletop hardware prototype will show how parking availability can be detected and updated. The project is practical, relevant, and expandable for future real-world smart parking applications.
