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
// Sensor 1: TRIG=D5,  ECHO=D18 -> slot_1
// Sensor 2: TRIG=D4,  ECHO=D16 -> slot_2
// Sensor 3: TRIG=D25, ECHO=D26 -> slot_3
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
  delay(1000);

  Serial.println("\n=================================");
  Serial.println("  ESP32 Smart Parking Starting   ");
  Serial.println("=================================");

  // Initialize 3 Sensor Pins
  for (int i = 0; i < 3; i++) {
    pinMode(slots[i].trigPin, OUTPUT);
    pinMode(slots[i].echoPin, INPUT);
  }

  // Connect to WiFi
  Serial.printf("Connecting to Wi-Fi: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(400);
  }
  Serial.println("\n[OK] Connected to Wi-Fi!");
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  config.timeout.serverResponse = 10000;
  config.timeout.socketConnection = 10000;

  fbdo.setResponseSize(2048);

  // Initialize Firebase (no signUp or token callback needed with legacy token!)
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("[OK] Firebase Initialized with Database Secret!");
}

void loop() {
  // Read 3 sensors every 2 seconds
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 2000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    for (int i = 0; i < 3; i++) {
      float distance_cm = readDistanceCM(slots[i].trigPin, slots[i].echoPin);
      
      Serial.print("[");
      Serial.print(slots[i].slotId);
      Serial.print("] Distance: ");
      Serial.print(distance_cm);
      Serial.println(" cm");

      // Determine Status (If less than 10cm, car detected)
      String newStatus = "available";
      if (distance_cm > 0 && distance_cm < 10.0) { 
        newStatus = "occupied";
      }

      // Update Firebase only when status changes
      if (newStatus != slots[i].currentStatus) {
        String path = String("/parking_status/building_A/") + slots[i].slotId;
        Serial.print("[");
        Serial.print(slots[i].slotId);
        Serial.print("] Status changed: ");
        Serial.print(newStatus);
        Serial.print(" -> Updating Firebase (");
        Serial.print(path);
        Serial.println(")...");
        
        if (Firebase.RTDB.setString(&fbdo, path.c_str(), newStatus)) {
          Serial.print("[");
          Serial.print(slots[i].slotId);
          Serial.println("] Firebase Update SUCCESS!");
          slots[i].currentStatus = newStatus;
        } else {
          Serial.print("[");
          Serial.print(slots[i].slotId);
          Serial.print("] Firebase Update FAILED: ");
          Serial.println(fbdo.errorReason());
        }
      }
      delay(50); // Small pause between sensor reads
    }
    Serial.println("----------------------------------------");
  }
}
     
