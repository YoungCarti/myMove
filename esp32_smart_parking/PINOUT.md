# ESP32 Smart Parking - Pinout & Wire Mapping Reference

This document serves as the quick reference guide for reconnecting all jumper wires from the HC-SR04 ultrasonic sensors and breadboard to the ESP32 development board.

---

## 📌 Complete Pin Mapping Table

| Wire Color | ESP32 Pin Label | ESP32 GPIO | Function / Slot | Notes |
| :--- | :--- | :--- | :--- | :--- |
| 🟤 **Brown** | **VIN** | Power (5V) | **5V Power Rail (VCC)** | Main 5V input to power sensors |
| 🔴 **Red (Power / Red 2)** | **GND** | Ground | **GND Rail (Ground)** | Common Ground |
| 🟡 **Yellow** | **D5** | GPIO 5 | **Slot 1 - TRIG** | Sensor 1 Trigger |
| 🔴 **Red (Signal / Red 1)** | **D18** | GPIO 18 | **Slot 1 - ECHO** | Sensor 1 Echo |
| 🟢 **Green** | **D4** | GPIO 4 | **Slot 2 - TRIG** | Sensor 2 Trigger |
| 🔵 **Blue** | **RX2** | GPIO 16 | **Slot 2 - ECHO** | Sensor 2 Echo |
| ⚪ **White** | **D25** | GPIO 25 | **Slot 3 - TRIG** | Sensor 3 Trigger |
| 🟠 **Orange** | **D26** | GPIO 26 | **Slot 3 - ECHO** | Sensor 3 Echo |

---

## 🚗 Slot Breakdown (Matching `esp32_smart_parking.ino`)

### 🔹 Slot 1 (Left Bay)
* **Trigger (TRIG):** 🟡 **Yellow wire** ➔ `D5` (GPIO 5)
* **Echo (ECHO):** 🔴 **Red (Signal) wire** ➔ `D18` (GPIO 18)

### 🔹 Slot 2 (Center Bay)
* **Trigger (TRIG):** 🟢 **Green wire** ➔ `D4` (GPIO 4)
* **Echo (ECHO):** 🔵 **Blue wire** ➔ `RX2` (GPIO 16)

### 🔹 Slot 3 (Right Bay)
* **Trigger (TRIG):** ⚪ **White wire** ➔ `D25` (GPIO 25)
* **Echo (ECHO):** 🟠 **Orange wire** ➔ `D26` (GPIO 26)

---

## ⚡ Power Connections
* **VCC (+5V):** 🟤 **Brown wire** ➔ `VIN` on ESP32 ➔ Connected to `+` Power rail on breadboard
* **GND (0V):** 🔴 **Red 2 wire** ➔ `GND` on ESP32 ➔ Connected to `-` Ground rail on breadboard

---

*Generated for MyMove IoT Smart Parking Prototype.*
