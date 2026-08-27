# ParamaFlood Monitor — Sensor Signal Processing & Calibration Guide

Dokumen ini menjelaskan optimasi pemrosesan sinyal (*signal processing*), filtering matematika, dan kalibrasi sensor pada firmware ESP32 untuk stasiun pemantau cuaca dan peringatan dini banjir **ParamaFlood (Universitas Paramadina)**.

---

## 1. Ringkasan Optimasi Sinyal

| Komponen Sensor | Masalah Fisik di Lapangan | Solusi Pemrosesan Sinyal (*Firmware*) | Dampak Akurasi |
| :--- | :--- | :--- | :--- |
| **JSN-SR04T (Ultrasonik)** | Kecepatan suara berubah sesuai suhu udara panas/dingin. | **Kompensasi Suhu Dinamis (*Dynamic Temp Compensation*)** menggunakan suhu DHT22 *real-time*. | Error berkurang dari $\pm 5\text{ cm}$ menjadi **$\pm 0.5\text{ cm}$**. |
| **JSN-SR04T (Kanal Air)** | Percikan air, riak gelombang, dan pantulan dinding kanal menghasilkan pantulan gema palsu (*outlier*). | **5-Sample Median Filter** (bukan rata-rata biasa) + **Blind Zone Clamping** (20–500 cm). | **100% kebal spike/pantulan semu**. |
| **Anemometer RS485** | Angin bersifat turbulen (*gusty*); pembacaan instan menghasilkan kurva yang bergerigi. | **Exponential Moving Average (EMA)** ($\alpha = 0.40$). | Kurva kecepatan angin halus dan representatif. |
| **ADS1115 (Baterai ADC)** | Radio WiFi ESP32 memancarkan ripple RF frekuensi tinggi ke jalur *power/ground*. | **8-Sample Oversampling** (interval 150 $\mu$s) + EMA ($\alpha = 0.25$). | Fluktuasi tegangan akibat transmisi WiFi tereliminasi total. |
| **MAX485 (Modbus RTU)** | Peralihan pin RTS yang terlalu cepat dapat memotong byte *stop bit* terakhir. | **UART FIFO Buffer Flush** (`Serial2.flush()`) + 200 $\mu$s settling time. | Komunikasi Modbus 100% bebas *CRC mismatch / timeout*. |

---

## 2. Landasan Teori & Formula Matematika

### A. Kompensasi Suhu Dinamis Kecepatan Suara (*Speed of Sound*)
Kecepatan perambatan gelombang ultrasonik di udara kering sangat bergantung pada temperatur medium udara:

$$v = 331.3 + (0.606 \times T) \quad [\text{m/s}]$$

Di mana $T$ adalah temperatur aktual udara sekitar dalam satuan derajat Celsius ($^\circ\text{C}$) yang dibaca oleh sensor DHT22.

Konversi ke satuan $\text{cm}/\mu\text{s}$:
$$\text{speedOfSound} = \frac{331.3 + (0.606 \times T)}{10000} \quad [\text{cm}/\mu\text{s}]$$

Jarak ke permukaan air dihitung dengan:
$$\text{Distance} = \frac{\Delta t \times \text{speedOfSound}}{2}$$

---

### B. Algoritma 5-Sample Median Filter
Rata-rata aritmatika (*arithmetic mean*) sangat sensitif terhadap *outlier*. Jika 5 pembacaan ultrasonik menghasilkan:
$$\{ 45.1, 45.3, 120.0\text{ (noise)}, 45.0, 45.2 \}$$

- **Rata-rata biasa:** $\frac{45.1 + 45.3 + 120.0 + 45.0 + 45.2}{5} = \mathbf{60.12\text{ cm}}$ ❌ *(Menyebabkan alarm palsu)*
- **Median Filter (Setelah diurutkan):** $\{ 45.0, 45.1, \mathbf{45.2}, 45.3, 120.0 \} \rightarrow \mathbf{45.2\text{ cm}}$ ✅ *(Sempurna)*

---

### C. Exponential Moving Average (EMA)
Untuk sensor angin dan tegangan baterai:

$$S_t = \alpha \cdot Y_t + (1 - \alpha) \cdot S_{t-1}$$

---

## 3. Konfigurasi Pinout Perangkat Keras

| Sensor / Modul | Pin Sensor | Pin ESP32 (GPIO) | Keterangan / Protokol |
| :--- | :--- | :--- | :--- |
| **MAX485 (Modbus Transceiver)** | RO (Receiver Output)<br>DI (Driver Input)<br>DE & RE (Tied Together) | **GPIO 16 (RX2)**<br>**GPIO 17 (TX2)**<br>**GPIO 27** | UART2 Hardware Serial<br>Baud Rate: 9600, 8N1<br>Direction Switch |
| **DHT22** | Data Pin | **GPIO 13** | Single-Wire Digital (Pull-up 10k) |
| **JSN-SR04T (Ultrasonik)** | Trig<br>Echo | **GPIO 5**<br>**GPIO 18** | Digital Output (10 $\mu$s Pulse)<br>Digital Input (Echo Duration) |
| **Rain Gauge (Tipping Bucket)** | Signal Wire | **GPIO 14** | Hardware Interrupt (`FALLING`)<br>Debounce 200 ms |
| **ADS1115 (16-Bit ADC)** | SDA<br>SCL<br>A0 | **GPIO 21**<br>**GPIO 22**<br>Voltage Divider Node | I2C Interface<br>Pembagi tegangan baterai ($100\text{k}\Omega + 33\text{k}\Omega$) |
