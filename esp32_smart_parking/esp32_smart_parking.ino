#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// Include secure credentials
#include "secrets.h"

// Struct for Parking Sensors
struct ParkingSlot {
  const char* slotId;
  int trigPin;
  int echoPin;
  String currentStatus;
};

// 3 Sensors configuration:
// Sensor 1: TRIG=D12, ECHO=D13 -> slot_1
// Sensor 2: TRIG=D4,  ECHO=D16 -> slot_2
// Sensor 3: TRIG=D14, ECHO=D27 -> slot_3 (Updated to D14/D27)
ParkingSlot slots[3] = {
  {"slot_1", 5, 18, ""},
  {"slot_2", 4, 16, ""},
  {"slot_3", 25, 26, ""}
};

// Firebase Objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

float readDistanceCM(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000); // 30ms timeout
  if (duration == 0) {
    return 999.0; // Out of range / no echo
  }
  return duration * 0.034 / 2.0;
}

void setup() {
  Serial.begin(115200);

  // Initialize 3 Sensor Pins
  for (int i = 0; i < 3; i++) {
    pinMode(slots[i].trigPin, OUTPUT);
    pinMode(slots[i].echoPin, INPUT);
  }

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected to Wi-Fi!");

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up as anonymous user
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase Auth Successful");
  } else {
    Serial.printf("Firebase Auth Error: %s\n", config.signer.signupError.message.c_str());
  }

  // Assign callbacks
  config.token_status_callback = tokenStatusCallback; 

  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // Read 3 sensors every 2 seconds
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 2000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    for (int i = 0; i < 3; i++) {
      float distance_cm = readDistanceCM(slots[i].trigPin, slots[i].echoPin);
      
      Serial.printf("[%s] Distance: %.2f cm\n", slots[i].slotId, distance_cm);

      // Determine Status (If less than 10cm, car detected)
      String newStatus = "available";
      if (distance_cm > 0 && distance_cm < 10.0) { 
        newStatus = "occupied";
      }

      // Update Firebase only when status changes
      if (newStatus != slots[i].currentStatus) {
        String path = String("/parking_status/building_A/") + slots[i].slotId;
        Serial.printf("[%s] Status changed: %s ➔ Updating Firebase (%s)...\n", slots[i].slotId, newStatus.c_str(), path.c_str());
        
        if (Firebase.RTDB.setString(&fbdo, path.c_str(), newStatus)) {
          Serial.printf("[%s] Firebase Update SUCCESS!\n", slots[i].slotId);
          slots[i].currentStatus = newStatus;
        } else {
          Serial.printf("[%s] Firebase Update FAILED: %s\n", slots[i].slotId, fbdo.errorReason().c_str());
        }
      }
      delay(50); // Small pause between sensor reads
    }
    Serial.println("----------------------------------------");
  }
}     
