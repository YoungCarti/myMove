#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// 1. WiFi Credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// 2. Firebase Credentials
#define API_KEY "GCP_API_KEY"
#define DATABASE_URL "https://mymove-cb624-default-rtdb.asia-southeast1.firebasedatabase.app"

// 3. HC-SR04 Pins
#define TRIG_PIN 14
#define ECHO_PIN 27

// 4. Firebase Objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Variables for sensor and timing
long duration;
float distance_cm;
String currentStatus = "";
unsigned long sendDataPrevMillis = 0;

void setup() {
  Serial.begin(115200);

  // Initialize Sensor Pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

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

  // Sign up as anonymous user (Required for modern Firebase rules)
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
  // Read Sensor every 2 seconds
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 2000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    // 1. Trigger the sensor
    digitalWrite(TRIG_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);

    // 2. Read the echo
    // Timeout set to 30000 microseconds to prevent blocking if no object is nearby
    duration = pulseIn(ECHO_PIN, HIGH, 30000);
    
    if (duration == 0) {
      Serial.println("Out of range or no echo received.");
      distance_cm = 999.0; // Large number representing no object
    } else {
      // 3. Calculate distance in cm
      distance_cm = duration * 0.034 / 2;
    }
    
    Serial.print("Distance: ");
    Serial.print(distance_cm);
    Serial.println(" cm");

    // 4. Determine Status (If less than 10cm, a car is there!)
    // Adjust 10.0cm based on your toy car / box size
    String newStatus = "available";
    if (distance_cm > 0 && distance_cm < 10.0) { 
      newStatus = "occupied";
    }

    // 5. Send to Firebase ONLY if status changed
    // This prevents spamming Firebase and wasting your free quota
    if (newStatus != currentStatus) {
      Serial.printf("Status changed to: %s. Updating Firebase...\n", newStatus.c_str());
      
      // Update the database path
      if (Firebase.RTDB.setString(&fbdo, "/parking_status/building_A/slot_1", newStatus)) {
        Serial.println("Firebase Update SUCCESS");
        currentStatus = newStatus;
      } else {
        Serial.println("Firebase Update FAILED");
        Serial.println(fbdo.errorReason());
      }
    }
  }
}
