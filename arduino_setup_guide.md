# Arduino & ESP32 Setup Guide

This guide details the steps and requirements to configure your system to compile and upload the `.ino` files found under the `ESP Codes/` directory to your ESP32 microcontrollers.

---

## 💾 Estimated Space Requirements

| Component | Download Size | Installed Disk Space |
| :--- | :--- | :--- |
| **Arduino IDE 2.x** | ~150 MB | ~500 MB |
| **ESP32 Core Package** (by Espressif) | ~150 MB | ~1.2 GB |
| **Required Libraries** (Firebase, DHT, BMP, GFX, etc.) | ~20 MB | ~100 MB |
| **USB Serial Drivers** | <10 MB | ~15 MB |
| **Total Recommended Free Space** | **~330 MB** | **~2.0 GB** |

---

## 🛠️ Step-by-Step Installation

### Step 1: Install Arduino IDE
1. Download and install **Arduino IDE 2.x** for Windows from [arduino.cc/en/software](https://www.arduino.cc/en/software).

### Step 2: Install ESP32 Board Support
1. Launch the **Arduino IDE**.
2. Open **File ➔ Preferences** (or press `Ctrl + ,`).
3. Locate the **Additional Boards Manager URLs** input box and paste the following URL:
   ```text
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Click **OK**.
5. Click on the **Boards Manager** icon on the left sidebar (or go to **Tools ➔ Board ➔ Boards Manager...**).
6. Search for `esp32` (make sure it's published by **Espressif Systems**).
7. Click **Install** (this may take a few minutes as it downloads the compiler toolchain).

### Step 3: Install Required Libraries
Open the **Library Manager** from the left sidebar (or go to **Tools ➔ Manage Libraries...**) and install the following libraries one by one:

1. **`Firebase ESP32 Client`** (by *Mobizt*)
2. **`DHT sensor library`** (by *Adafruit*)
3. **`Adafruit BMP280 Library`** (by *Adafruit*)
4. **`Adafruit Unified Sensor`** (by *Adafruit*)
5. **`Adafruit GFX Library`** (by *Adafruit*)
6. **`Adafruit ILI9341`** (by *Adafruit*)

---

## 🔌 Connecting Your Hardware

### Step 4: Install USB Drivers (If Needed)
If you connect your ESP32 board to your PC and it doesn't show up under **Tools ➔ Port**, you need to install a USB-to-UART bridge driver:
- **CH340 Driver:** Common on budget/cloned ESP32 boards.
- **CP210x Driver:** Common on official/standard NodeMCU and ESP32 DevKit boards.
*(Download these drivers from the official Silicon Labs or WCH manufacturer websites respectively).*

### Step 5: Select Your Board and Port
1. Connect your ESP32 board to your computer using a **data-capable USB cable** (some cables are charge-only!).
2. In Arduino IDE, go to **Tools ➔ Board ➔ esp32** and select your board type (typically **ESP32 Dev Module** or **Adafruit ESP32 Feather** depending on your board).
3. Go to **Tools ➔ Port** and select the active COM port associated with your board (e.g., `COM3`, `COM4`).

---

## 📁 Project Sketches Overview

This project includes the following Arduino sketches inside the [ESP Codes](file:///c:/Users/LENOVO/Music/weather-station-main/ESP%20Codes) directory:

1. **[External_esp_v4_firebase.ino](file:///c:/Users/LENOVO/Music/weather-station-main/ESP%20Codes/External_esp_v4_firebase/External_esp_v4_firebase.ino)**:
   - Configures the outdoor/external sensor station.
   - Reads data from DHT11 (temp/humidity), BMP280 (pressure), and wind speed sensor.
   - Broadcasts data locally via **ESP-NOW** and pushes it to **Firebase**.
2. **[TFT_ESP_screen.ino](file:///c:/Users/LENOVO/Music/weather-station-main/ESP%20Codes/TFT_ESP_screen/TFT_ESP_screen.ino)**:
   - Configures the indoor display station (CYD TFT screen).
   - Listens for local sensor packets over **ESP-NOW** and displays them on the screen.
3. **[Mac_address_code.ino](file:///c:/Users/LENOVO/Music/weather-station-main/ESP%20Codes/Mac_address_code/Mac_address_code.ino)**:
   - Run this utility sketch first on your display ESP32 to print its MAC address to the Serial Monitor.
   - You will need to copy that MAC address and paste it into the `broadcastAddress` variable in your sensor node code.
