/*
  ══════════════════════════════════════════════════════════════════════
  ParamaFlood Monitor — External Sensor ESP32 (PlatformIO)
  Enhanced Edition: Temperature Compensation, Median Filtering, & EMA
  ══════════════════════════════════════════════════════════════════════
  
  Hardware:
    - ESP32 DevKit v1
    - RS485 Modbus Ambient Light Sensor (Addr 0x01, Reg 0x0002-0x0003)
    - RS485 Modbus Wind Speed Sensor   (Addr 0x02, Reg 0x0000)
    - MAX485 TTL-to-RS485 Transceiver  (DE/RE tied → GPIO 27)
    - DHT22 Temperature & Humidity     (GPIO 13)
    - Rain Gauge (tipping bucket)      (GPIO 14, interrupt on FALLING)
    - JSN-SR04T Ultrasonic Distance    (Trig GPIO 5, Echo GPIO 18)
    - ADS1115 ADC for Battery Voltage  (I2C, Channel A0, voltage divider)

  Signal Processing & Optimizations:
    1. Ultrasonic Dynamic Speed of Sound: v = 331.3 + (0.606 * T) m/s
    2. Ultrasonic 5-Sample Median Filter: Rejects water ripples & reflections
    3. JSN-SR04T Physical Blind Zone Rejection: Clamps valid range (20 - 500 cm)
    4. ADS1115 8-Sample Oversampling: Rejects ESP32 WiFi RF ripple noise
    5. Anemometer Exponential Moving Average (EMA): Smooth wind & gust handling
    6. RS485 UART Buffer Flush: Guarantees zero truncated Modbus stop bits

  ══════════════════════════════════════════════════════════════════════
*/

#include <Arduino.h>
#include <ModbusMaster.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include "DHT.h"
#include <Adafruit_ADS1X15.h>

// ═══════════════════════════════════════════════════════════════════
//  PIN DEFINITIONS
// ═══════════════════════════════════════════════════════════════════
#define RS485_RX   16    // ESP32 RX2 (GPIO 16) → MAX485 RO
#define RS485_TX   17    // ESP32 TX2 (GPIO 17) → MAX485 DI
#define RS485_RTS  27    // RS485 DE/RE direction control (GPIO 27)
#define DHTPIN     13    // DHT22 Data Pin (GPIO 13)
#define RAIN_PIN   14    // Rain Gauge Interrupt Pin (GPIO 14)
#define TRIG_PIN   5     // JSN-SR04T Trig Pin
#define ECHO_PIN   18    // JSN-SR04T Echo Pin

// ═══════════════════════════════════════════════════════════════════
//  SENSOR CONFIGURATIONS
// ═══════════════════════════════════════════════════════════════════
#define LIGHT_SENSOR_ADDR  0x01   // Ambient Light Sensor Modbus Address
#define WIND_SENSOR_ADDR   0x02   // Wind Sensor Modbus Address (configured)
#define LIGHT_REG_START    0x0002 // Light intensity register start (32-bit)
#define BAUD_RATE          9600   // Modbus baud rate for both sensors
#define DHTTYPE            DHT22  // DHT22 sensor type

// ═══════════════════════════════════════════════════════════════════
//  WIFI & FIREBASE SETTINGS
// ═══════════════════════════════════════════════════════════════════
const char* ssid       = "BIRRUL WALIDAIN";   // ← Your WiFi SSID
const char* password   = "Naunau0312";        // ← Your WiFi Password

// Firebase Realtime Database REST endpoint (no trailing slash)
const char* firebaseURL = "https://paramaflood-default-rtdb.asia-southeast1.firebasedatabase.app";

// ═══════════════════════════════════════════════════════════════════
//  TIMING INTERVALS
// ═══════════════════════════════════════════════════════════════════
const unsigned long SENSOR_READ_INTERVAL    = 3000;    // Read all sensors every 3s
const unsigned long LIVE_UPLOAD_INTERVAL    = 3000;    // Upload live data every 3s
const unsigned long HISTORY_UPLOAD_INTERVAL = 60000;   // Log to history every 60s
const unsigned long WIFI_RETRY_INTERVAL     = 30000;   // Retry WiFi every 30s if lost
const unsigned long DHT_MIN_INTERVAL        = 2000;    // DHT22 needs ≥2s between reads
const unsigned long ULTRASONIC_TIMEOUT_US   = 35000;   // 35ms = ~6m max distance

// ═══════════════════════════════════════════════════════════════════
//  SENSOR INSTANCES
// ═══════════════════════════════════════════════════════════════════
ModbusMaster     node;
DHT              dht(DHTPIN, DHTTYPE);
WiFiClientSecure wifiClient;
Adafruit_ADS1115 ads;

// ═══════════════════════════════════════════════════════════════════
//  RAIN GAUGE STATE — Interrupt-safe variables
// ═══════════════════════════════════════════════════════════════════
static const float   MM_PER_TIP       = 0.70f;   // mm of rain per bucket tip
static volatile long tipCount         = 0;
static volatile float totalRainMM     = 0.0f;
static volatile unsigned long lastTipMs = 0;
static const unsigned long TIP_DEBOUNCE_MS = 200; // Debounce for reed switch bounce

// ═══════════════════════════════════════════════════════════════════
//  TIMING STATE
// ═══════════════════════════════════════════════════════════════════
static unsigned long lastSensorReadMs    = 0;
static unsigned long lastLiveUploadMs    = 0;
static unsigned long lastHistoryUploadMs = 0;
static unsigned long lastWiFiRetryMs     = 0;
static bool          firstHistoryDone    = false;  // Skip first-boot junk data

// ═══════════════════════════════════════════════════════════════════
//  LAST-KNOWN-GOOD SENSOR VALUES (Fallback values)
// ═══════════════════════════════════════════════════════════════════
static float lastGoodTemp      = 27.0f;
static float lastGoodHum       = 70.0f;
static float lastGoodLux       = 0.0f;
static float lastGoodWind      = 0.0f;
static float lastGoodDistance  = 120.0f;
static float lastGoodBattery   = 12.6f;

// ═══════════════════════════════════════════════════════════════════
//  CURRENT SENSOR READINGS
// ═══════════════════════════════════════════════════════════════════
static float curTemp      = 27.0f;
static float curHum       = 70.0f;
static float curLux       = 0.0f;
static float curWind      = 0.0f;
static float curRainMM    = 0.0f;
static float curDistance  = 120.0f;
static float curBattery   = 12.6f;

// ═══════════════════════════════════════════════════════════════════
//  SENSOR STATUS FLAGS (for serial diagnostics)
// ═══════════════════════════════════════════════════════════════════
static bool dhtOK        = false;
static bool lightOK      = false;
static bool windOK       = false;
static bool ultrasonicOK = false;
static bool adsOK        = false;
static bool wifiOK       = false;

// ═══════════════════════════════════════════════════════════════════
//  RS485 DE/RE CONTROL CALLBACKS
// ═══════════════════════════════════════════════════════════════════
void preTransmission() {
  digitalWrite(RS485_RTS, HIGH);   // Enable transmit mode
  delayMicroseconds(80);           // Let transceiver line settle
}

void postTransmission() {
  Serial2.flush();                 // Ensure UART FIFO buffer is fully empty
  delayMicroseconds(200);          // Allow stop-bit transmission to complete
  digitalWrite(RS485_RTS, LOW);    // Back to receive mode
}

// ═══════════════════════════════════════════════════════════════════
//  RAIN GAUGE INTERRUPT SERVICE ROUTINE
// ═══════════════════════════════════════════════════════════════════
void IRAM_ATTR onRainTip() {
  unsigned long now = millis();
  // Debounce: ignore tips that happen within 200ms of each other
  if (now - lastTipMs > TIP_DEBOUNCE_MS) {
    tipCount++;
    totalRainMM += MM_PER_TIP;
    lastTipMs = now;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MODBUS ERROR STRING HELPER
// ═══════════════════════════════════════════════════════════════════
String modbusErrorStr(uint8_t err) {
  switch (err) {
    case 0x00: return "Success";
    case 0x01: return "Illegal Function (check register type)";
    case 0x02: return "Illegal Data Address (check register map)";
    case 0x03: return "Illegal Data Value";
    case 0x04: return "Slave Device Failure";
    case 0xE0: return "Invalid Slave ID";
    case 0xE1: return "Invalid Function";
    case 0xE2: return "Timeout / No Response (check wiring, address, power)";
    case 0xE3: return "Invalid CRC (address collision, bad ground, noise)";
    default:   return "Unknown 0x" + String(err, HEX);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WiFi CONNECT / RECONNECT
// ═══════════════════════════════════════════════════════════════════
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    wifiOK = true;
    return;
  }

  Serial.print("[WiFi] Connecting");
  WiFi.disconnect(true);   // Clean slate
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 25) {
    delay(400);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiOK = true;
    Serial.printf("\n[WiFi] Connected! IP: %s | RSSI: %d dBm\n", 
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
  } else {
    wifiOK = false;
    Serial.println("\n[WiFi] Connection timed out. Operating in offline logging mode.");
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SENSOR READING FUNCTIONS
// ═══════════════════════════════════════════════════════════════════

/**
 * 1. Read DHT22 Temperature & Humidity
 * Must be read before ultrasonic to supply ambient temperature compensation.
 */
void readDHT() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h)) {
    curTemp = lastGoodTemp;
    curHum  = lastGoodHum;
    dhtOK = false;
    Serial.printf("[DHT22]      Read failed — fallback to: %.1f°C, %.1f%%\n",
                  curTemp, curHum);
    return;
  }

  // Physical sanity bounds: -40 to 80°C, 0-100% RH
  if (t >= -20.0f && t <= 65.0f) {
    curTemp = (0.7f * lastGoodTemp) + (0.3f * t); // Smooth EMA
    lastGoodTemp = curTemp;
  }
  if (h >= 0.0f && h <= 100.0f) {
    curHum = (0.7f * lastGoodHum) + (0.3f * h);   // Smooth EMA
    lastGoodHum = curHum;
  }

  dhtOK = true;
  Serial.printf("[DHT22]      Temp: %.1f°C | Hum: %.1f%%\n", curTemp, curHum);
}

/**
 * 2. Read JSN-SR04T Ultrasonic Distance Sensor
 * Optimizations:
 * - Dynamic Speed of Sound Compensated by Real-time DHT22 Temperature
 * - 5-Sample Median Filter (Rejects water surface waves & acoustic noise)
 * - JSN-SR04T Physical Blind Zone Filter (20 cm - 500 cm)
 */
void readUltrasonic() {
  const int NUM_SAMPLES = 5;
  float samples[NUM_SAMPLES];
  int validCount = 0;

  // Temperature-compensated speed of sound: v = 331.3 + (0.606 * T) m/s
  // Convert to cm / microsecond:
  float ambientTemp = (dhtOK && curTemp > -10.0f && curTemp < 60.0f) ? curTemp : 25.0f;
  float speedOfSound = (331.3f + 0.606f * ambientTemp) / 10000.0f;

  for (int i = 0; i < NUM_SAMPLES; i++) {
    // Send 10us trigger pulse
    digitalWrite(TRIG_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);

    // Measure echo duration
    long duration = pulseIn(ECHO_PIN, HIGH, ULTRASONIC_TIMEOUT_US);

    if (duration > 0) {
      float dist = (duration * speedOfSound) / 2.0f;

      // JSN-SR04T physical active range: 20cm – 500cm (reject blind zone <20cm)
      if (dist >= 20.0f && dist <= 500.0f) {
        samples[validCount++] = dist;
      }
    }

    if (i < NUM_SAMPLES - 1) delay(35); // Acoustic settle time between pings
  }

  if (validCount > 0) {
    // Sort valid readings (ascending) to obtain true statistical median
    for (int i = 0; i < validCount - 1; i++) {
      for (int j = i + 1; j < validCount; j++) {
        if (samples[i] > samples[j]) {
          float temp = samples[i];
          samples[i] = samples[j];
          samples[j] = temp;
        }
      }
    }

    // Select the median value (middle element)
    float medianDist = samples[validCount / 2];

    // Apply light EMA smoothing against previous valid reading
    if (lastGoodDistance > 0) {
      curDistance = (0.65f * lastGoodDistance) + (0.35f * medianDist);
    } else {
      curDistance = medianDist;
    }

    lastGoodDistance = curDistance;
    ultrasonicOK = true;
    Serial.printf("[ULTRASONIC]  %.1f cm (Median of %d valid pings | Temp: %.1f°C | v=%.1f m/s)\n",
                  curDistance, validCount, ambientTemp, speedOfSound * 10000.0f);
  } else {
    // All pings failed or obstructed
    curDistance = (lastGoodDistance > 0) ? lastGoodDistance : -1.0f;
    ultrasonicOK = false;
    Serial.printf("[ULTRASONIC]  No echo in range (using fallback: %.1f cm)\n", curDistance);
  }
}

/**
 * 3. Read RS485 Modbus Ambient Light Sensor
 * Register 0x0002-0x0003: 32-bit unsigned lux value (÷1000)
 */
void readLightSensor() {
  node.begin(LIGHT_SENSOR_ADDR, Serial2);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  uint8_t res = node.readHoldingRegisters(LIGHT_REG_START, 2);
  if (res == node.ku8MBSuccess) {
    uint16_t high = node.getResponseBuffer(0);
    uint16_t low  = node.getResponseBuffer(1);
    uint32_t rawLux = ((uint32_t)high << 16) | low;
    float measuredLux = rawLux / 1000.0f;

    // EMA smoothing
    curLux = (0.7f * lastGoodLux) + (0.3f * measuredLux);
    lastGoodLux = curLux;
    lightOK = true;
    Serial.printf("[LIGHT]      %.1f lux\n", curLux);
  } else {
    curLux = lastGoodLux;
    lightOK = false;
    Serial.printf("[LIGHT]      ERROR: %s (using: %.1f lux)\n",
                  modbusErrorStr(res).c_str(), curLux);
  }
}

/**
 * 4. Read RS485 Modbus Wind Speed Sensor
 * Register 0x0000: wind speed in 0.1 m/s units
 * Applies Exponential Moving Average (EMA) to smooth wind turbulence & gusts
 */
void readWindSensor() {
  node.begin(WIND_SENSOR_ADDR, Serial2);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  uint8_t res = node.readHoldingRegisters(0x0000, 1);
  if (res == node.ku8MBSuccess) {
    uint16_t val = node.getResponseBuffer(0);
    float rawWind = val / 10.0f;

    // Sanity check: anemometer should not exceed 60 m/s in normal conditions
    if (rawWind <= 60.0f) {
      curWind = (0.6f * lastGoodWind) + (0.4f * rawWind); // EMA filter
      lastGoodWind = curWind;
      windOK = true;
      Serial.printf("[WIND]       %.1f m/s (Raw: %.1f m/s)\n", curWind, rawWind);
    } else {
      curWind = lastGoodWind;
      Serial.printf("[WIND]       Out of bounds: %.1f m/s (clamped)\n", rawWind);
    }
  } else {
    curWind = lastGoodWind;
    windOK = false;
    Serial.printf("[WIND]       ERROR: %s (using: %.1f m/s)\n",
                  modbusErrorStr(res).c_str(), curWind);
  }
}

/**
 * 5. Read Rain Gauge (Tipping Bucket)
 */
void readRainGauge() {
  noInterrupts();
  long tips = tipCount;
  float rain = totalRainMM;
  interrupts();

  curRainMM = rain;
  Serial.printf("[RAIN]       Tips: %ld | Total: %.2f mm\n", tips, curRainMM);
}

/**
 * 6. Read Battery Voltage via ADS1115 (16-bit ADC)
 * Oversampling 8x to eliminate ESP32 WiFi switching noise
 * Voltage divider: 100kΩ + 33kΩ → V_batt = V_A0 * (133 / 33)
 */
void readBatteryVoltage() {
  if (!adsOK) {
    curBattery = lastGoodBattery;
    return;
  }

  int32_t adcSum = 0;
  const int OVERSAMPLE_COUNT = 8;

  for (int i = 0; i < OVERSAMPLE_COUNT; i++) {
    adcSum += ads.readADC_SingleEnded(0);
    delayMicroseconds(150);
  }

  int16_t avgAdc = adcSum / OVERSAMPLE_COUNT;

  // GAIN_ONE: ±4.096V range → 0.125 mV per LSB
  float voltageA0 = avgAdc * 0.000125f;

  // Resistor Divider Ratio: (100k + 33k) / 33k ≈ 4.0303
  float rawBattery = voltageA0 * (133.0f / 33.0f);

  // Sanity check: 0V - 15V
  if (rawBattery >= 0.0f && rawBattery <= 16.0f) {
    curBattery = (0.75f * lastGoodBattery) + (0.25f * rawBattery);
    lastGoodBattery = curBattery;
    adsOK = true;
    Serial.printf("[BATTERY]    %.2fV (A0: %.3fV | ADC: %d)\n", curBattery, voltageA0, avgAdc);
  } else {
    curBattery = lastGoodBattery;
    Serial.printf("[BATTERY]    Abnormal reading: %.2fV (using fallback)\n", rawBattery);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  READ ALL SENSORS (Ordered for optimal cross-compensation)
// ═══════════════════════════════════════════════════════════════════
void readAllSensors() {
  Serial.println("\n─── [Sensor Acquisition Cycle] ──────────────────────");

  // 1. Read temperature first (used for ultrasonic speed of sound calibration)
  readDHT();

  // 2. Read ultrasonic with active temperature compensation & median filtering
  readUltrasonic();

  // 3. Read Modbus RS485 sensors with bus cooldown
  readLightSensor();
  delay(80);

  readWindSensor();
  delay(50);

  // 4. Read rain & battery
  readRainGauge();
  readBatteryVoltage();

  Serial.println("─────────────────────────────────────────────────────");
}

// ═══════════════════════════════════════════════════════════════════
//  BUILD JSON PAYLOAD
// ═══════════════════════════════════════════════════════════════════
String buildJsonPayload() {
  String json = "{";
  json += "\"temp\":"     + String(curTemp, 1)     + ",";
  json += "\"hum\":"      + String(curHum, 1)      + ",";
  json += "\"pres\":1013.25,";   // Static placeholder
  json += "\"wind\":"     + String(curWind, 1)     + ",";
  json += "\"light\":"    + String(curLux, 1)      + ",";
  json += "\"rain\":"     + String(curRainMM, 2)   + ",";
  json += "\"distance\":" + String(curDistance, 1)  + ",";
  json += "\"battery\":"  + String(curBattery, 2)  + ",";
  json += "\"isOnline\":true,";
  json += "\"timestamp\":{\".sv\":\"timestamp\"}";
  json += "}";
  return json;
}

// ═══════════════════════════════════════════════════════════════════
//  FIREBASE UPLOAD FUNCTIONS
// ═══════════════════════════════════════════════════════════════════
bool uploadLiveData(const String& json) {
  HTTPClient http;
  String url = String(firebaseURL) + "/weather_station.json";
  http.begin(wifiClient, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);

  int code = http.PUT(json);
  http.end();

  if (code >= 200 && code < 300) {
    Serial.printf("[Firebase] Live PUT OK (%d)\n", code);
    return true;
  } else {
    Serial.printf("[Firebase] Live PUT FAILED (%d): %s\n", code,
                  http.errorToString(code).c_str());
    return false;
  }
}

bool uploadHistoryData(const String& json) {
  HTTPClient http;
  String url = String(firebaseURL) + "/weather_history.json";
  http.begin(wifiClient, url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);

  int code = http.POST(json);
  http.end();

  if (code >= 200 && code < 300) {
    Serial.printf("[Firebase] History POST OK (%d)\n", code);
    return true;
  } else {
    Serial.printf("[Firebase] History POST FAILED (%d): %s\n", code,
                  http.errorToString(code).c_str());
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("==================================================");
  Serial.println("   ParamaFlood Monitor — ESP32 Sensor Gateway     ");
  Serial.println("   Optimized Signal Processing & Noise Reduction   ");
  Serial.println("==================================================");

  // ── RS485 direction control ──
  pinMode(RS485_RTS, OUTPUT);
  digitalWrite(RS485_RTS, LOW);

  // ── Rain gauge interrupt ──
  pinMode(RAIN_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(RAIN_PIN), onRainTip, FALLING);

  // ── DHT22 ──
  dht.begin();
  Serial.println("[INIT] DHT22 initialized");

  // ── Ultrasonic ──
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  digitalWrite(TRIG_PIN, LOW);
  Serial.println("[INIT] JSN-SR04T Ultrasonic initialized (Temp-Compensated)");

  // ── ADS1115 (I2C ADC) ──
  if (ads.begin()) {
    ads.setGain(GAIN_ONE);  // ±4.096V range
    adsOK = true;
    Serial.println("[INIT] ADS1115 initialized (GAIN_ONE | 8x Oversampling)");
  } else {
    adsOK = false;
    Serial.println("[INIT] ADS1115 FAILED — check I2C wiring (SDA 21, SCL 22)");
  }

  // ── RS485 Modbus ──
  Serial2.begin(BAUD_RATE, SERIAL_8N1, RS485_RX, RS485_TX);
  node.begin(LIGHT_SENSOR_ADDR, Serial2);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);
  Serial.println("[INIT] RS485 Modbus initialized (9600 baud)");

  // ── WiFi ──
  connectWiFi();

  // ── SSL ──
  wifiClient.setInsecure();

  // ── Sensor warm-up ──
  Serial.println("[INIT] Warming up sensors (2s)...");
  delay(2000);

  Serial.println("==================================================");
  Serial.println("           Entering Main Execution Loop           ");
  Serial.println("==================================================\n");
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN LOOP
// ═══════════════════════════════════════════════════════════════════
void loop() {
  unsigned long now = millis();

  // ── 1. Sensor Acquisition Cycle ──
  if (now - lastSensorReadMs >= SENSOR_READ_INTERVAL) {
    lastSensorReadMs = now;
    readAllSensors();
  }

  // ── 2. WiFi Auto-Reconnect ──
  if (WiFi.status() != WL_CONNECTED) {
    wifiOK = false;
    if (now - lastWiFiRetryMs >= WIFI_RETRY_INTERVAL) {
      lastWiFiRetryMs = now;
      Serial.println("[WiFi] Reconnecting...");
      connectWiFi();
    }
  } else {
    wifiOK = true;
  }

  // ── 3. Live Data Upload (3s) ──
  if (wifiOK && (now - lastLiveUploadMs >= LIVE_UPLOAD_INTERVAL)) {
    lastLiveUploadMs = now;
    String json = buildJsonPayload();
    uploadLiveData(json);
  }

  // ── 4. Historical Data Upload (60s) ──
  if (wifiOK && firstHistoryDone && 
      (now - lastHistoryUploadMs >= HISTORY_UPLOAD_INTERVAL)) {
    lastHistoryUploadMs = now;
    String json = buildJsonPayload();
    uploadHistoryData(json);
  }

  if (!firstHistoryDone && lastSensorReadMs > 0) {
    firstHistoryDone = true;
    lastHistoryUploadMs = now;
  }

  delay(10);
}