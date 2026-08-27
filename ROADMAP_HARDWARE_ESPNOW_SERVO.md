# ParamaFlood Monitor — Panduan Pengembangan Lanjutan
## Arsitektur Dual ESP32 (ESP-NOW) & 4-Side Mechanical Servo Shutter

Dokumen ini disusun sebagai cetak biru (*blueprint*) teknis untuk implementasi perangkat keras tahap berikutnya menjelang presentasi lomba/sidang (2 bulan ke depan).

---

## 1. Konsep Arsitektur: Wireless Sensor & Actuator Network (WSAN)

Sistem memisahkan tugas pembacaan sensor (*sensing*) dan penggerak mekanik (*actuation*) ke dalam dua mikrokontroler independen yang terhubung melalui protokol nirkabel berlatensi rendah (**ESP-NOW < 2 ms**).

```
┌─────────────────────────────────────────────────────────────┐
│             ESP32 #1: SENSOR & CLOUD GATEWAY                │
│  • RS485 Modbus (Anemometer & Light Sensor)                 │
│  • DHT22, JSN-SR04T (Ultrasonik), Rain Gauge, ADS1115       │
│  • Uplink: WiFi ke Firebase Realtime Database & Flutter App │
│  • Downlink: ESP-NOW Broadcast (Peer-to-Peer 2.4 GHz)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ ⚡ ESP-NOW Packet (< 2 ms)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            ESP32 #2: DEDICATED ACTUATOR NODE                │
│  • Mengontrol 4–8 Motor Servo (MG996R / SG90)               │
│  • Menggerakkan Shutter 4 Sisi Box Transparan → Merah Total │
│  • Lampu Strobo / Beacon Darurat 12V                        │
│  • Terisolasi dari lonjakan arus (*voltage dip*) sensor     │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Rincian Desain Mekanik 4-Side Shutter

* **Konsep:** Box transparan berubah warna menjadi merah menyala saat banjir level kritis terdeteksi ($<20\text{ cm}$ ke ujung sensor JSN-SR04T).
* **Material:**
  - **Akrilik Bening 3 mm** untuk dinding luar kotak stasiun.
  - **Stiker Reflektif 3M / Scotlite Neon Fluorescent Red-Orange** (tipe rambu lalu lintas / ambulans).
  - **Motor Servo:** TowerPro MG996R (Metal Gear, Torsi 10 kg·cm) atau SG90 Micro Servo.
* **Mekanisme Louver (Sirip Putar Krey):**
  - Posisi Normal ($0^\circ$): Bilah sirip sejajar pandangan $\rightarrow$ Kotak tembus pandang (transparan).
  - Posisi Bahaya ($90^\circ$): Servo memutar bilah sirip $90^\circ$ $\rightarrow$ Seluruh 4 sisi tertutup warna merah neon menyala.

---

## 3. Skema Kelistrikan & Distribusi Daya

```
[Baterai Aki / LiFePO4 12V]
      │
      ├──→ [Step-Down Buck XL4015 / LM2596 #1: 5.0V / 3A] ──→ ESP32 #1 & Semua Sensor
      │
      └──→ [Step-Down Buck XL4015 / LM2596 #2: 6.0V / 5A] ──→ ESP32 #2 & Daya Semua Servo
                                                               (GND Terhubung Bersama / Common GND)
```

> [!IMPORTANT]
> Pisahkan regulator step-down untuk motor servo dan ESP32 sensor. Hubungkan seluruh jalur Ground (GND) bersama (*Common Ground*). Hal ini menjamin sensor ultrasonik dan ADC tidak terganggu tarikan arus motor servo.

---

## 4. Struktur Kode Boilerplate ESP-NOW

### A. Struktur Data Paket Bersama (`struct_message.h`)
```cpp
typedef struct struct_message {
  uint8_t alertLevel;    // 0 = Normal, 1 = Waspada, 2 = Kritis / Bahaya
  float   waterLevelCm;  // Level air kanal (cm)
  float   distanceCm;    // Jarak ke ujung sensor JSN-SR04T (cm)
  bool    triggerSiren;  // true jika air <= 20cm dari sensor
} struct_message;
```

---

### B. ESP32 #1 (Master / Sender Snippet)
```cpp
#include <esp_now.h>
#include <WiFi.h>

// MAC Address ESP32 #2 (Receiver)
uint8_t slaveAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}; // Ganti dengan MAC ESP32 #2

struct_message outgoingData;

void initESPNow() {
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_peer_info_t peerInfo = {};
  memcpy(peerInfo.peer_addr, slaveAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;
  esp_now_add_peer(&peerInfo);
}

void sendAlertToActuator(float waterLevel, float distance, uint8_t level) {
  outgoingData.waterLevelCm = waterLevel;
  outgoingData.distanceCm  = distance;
  outgoingData.alertLevel  = level;
  outgoingData.triggerSiren = (distance > 0 && distance <= 20.0);

  esp_now_send(slaveAddress, (uint8_t *) &outgoingData, sizeof(outgoingData));
}
```

---

### C. ESP32 #2 (Slave / Receiver & Servo Controller)
```cpp
#include <esp_now.h>
#include <WiFi.h>
#include <ESP32Servo.h>

Servo servoSide1, servoSide2, servoSide3, servoSide4;

#define SERVO_PIN_1 13
#define SERVO_PIN_2 12
#define SERVO_PIN_3 14
#define SERVO_PIN_4 27

struct_message incomingData;

void setAllShutters(int angle) {
  servoSide1.attach(SERVO_PIN_1);
  servoSide2.attach(SERVO_PIN_2);
  servoSide3.attach(SERVO_PIN_3);
  servoSide4.attach(SERVO_PIN_4);

  servoSide1.write(angle);
  servoSide2.write(angle);
  servoSide3.write(angle);
  servoSide4.write(angle);

  delay(600); // Waktu gerak servo

  // Detach untuk hemat daya dan hilangkan getaran/dengung motor
  servoSide1.detach();
  servoSide2.detach();
  servoSide3.detach();
  servoSide4.detach();
}

void onDataRecv(const uint8_t * mac, const uint8_t *incomingBytes, int len) {
  memcpy(&incomingData, incomingBytes, sizeof(incomingData));

  if (incomingData.triggerSiren || incomingData.alertLevel == 2) {
    // Bahaya Kritis -> Buka panel merah (90 derajat)
    setAllShutters(90);
  } else {
    // Normal -> Kembalikan ke posisi transparan (0 derajat)
    setAllShutters(0);
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  esp_now_init();
  esp_now_register_recv_cb(onDataRecv);
  setAllShutters(0); // Posisi awal normal
}

void loop() {
  delay(100);
}
```

---

## 5. Alur Skenario Demo Panggung (Pitching Lomba)

| Langkah | Aksi Presenter | Respon Sistem Fisik & Aplikasi | Efek ke Juri |
| :---: | :--- | :--- | :--- |
| **1** | Buka aplikasi Flutter di hadapan juri. | Menampilkan dashboard monitoring live stasiun cuaca Universitas Paramadina. | Menunjukkan sistem sudah aktif & terhubung cloud. |
| **2** | Buka **Slider Simulasi Interaktif** pada kartu kanal. | Gelombang 2D canvas bergerak mulus mengikuti hembusan angin riil. | Visual fluid physics terlihat sangat modern. |
| **3** | Tarik slider air ke atas $\ge 85\text{ cm}$ (simulasi banjir mendekati bibir kanal $\le 20\text{ cm}$). | **1. Air Raid Siren meraung keras.**<br>**2. Suara AI TTS berbahasa Indonesia memberi instruksi evakuasi.**<br>**3. ESP32 #1 mengirim sinyal ESP-NOW.**<br>**4. Seluruh 4 sisi box stasiun fisik seketika berubah merah total.** | **WOW Factor Maksimal!** Menunjukkan integrasi software, cloud, AI, dan mekatronika fisik. |
| **4** | Tarik slider kembali ke bawah ($30\text{ cm}$). | Sirine mati, suara tenang kembali, dan panel merah menutup kembali ke transparan. | Menunjukkan kehandalan *fail-safe* dan kontrol dua arah. |

---

## 6. Checklist Persiapan 2 Bulan Menuju Lomba

- [ ] **Bulan 1 (Minggu 1-2):** Perakitan mekanik sirip akrilik dan pemasangan stiker reflektif 3M pada box.
- [ ] **Bulan 1 (Minggu 3-4):** Pengujian koneksi ESP-NOW dual ESP32 dan kalibrasi sudut putar servo ($0^\circ \leftrightarrow 90^\circ$).
- [ ] **Bulan 2 (Minggu 1-2):** Uji coba luar ruangan (*field test*) di tepi kanal kampus Universitas Paramadina dan pengetesan ketahanan baterai solar 24 jam.
- [ ] **Bulan 2 (Minggu 3-4):** Latihan skenario pitching demo panggung, pembuatan slide presentasi, dan video teaser 1 menit.
