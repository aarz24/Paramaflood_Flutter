# 🌊 DOKUMENTASI LENGKAP SISTEM PARAMAFLOOD MONITOR
> **ESP32 IoT Flood & Weather Monitoring Dashboard**  
> **Universitas Paramadina · 2026**  
> **Tim Peneliti:** Ariel & Naina (bersama Arya)  

---

## 📌 1. Pendahuluan & Ringkasan Sistem

**ParamaFlood Monitor** adalah sistem pemantauan banjir dan stasiun cuaca berbasis **Internet of Things (IoT)** yang terintegrasi secara *realtime* dengan **Google Gemini Artificial Intelligence (AI)** dan **Open-Meteo Weather API**. 

Sistem ini dirancang untuk mendeteksi kenaikan volume air sungai/kanal secara dini, menganalisis faktor pencetus banjir (curah hujan, kelembaban, tekanan udara), serta memberikan peringatan dini (*early warning system*) yang cerdas bagi masyarakat dan tim peneliti.

---

## 🏗️ 2. Arsitektur Teknis & Spesifikasi Teknologi

```
┌────────────────────────┐      ┌─────────────────────────────┐      ┌──────────────────────────────┐
│  Hardware Stasiun IoT  │ ────►│  Firebase Realtime Database │ ────►│  Flutter Application (State) │
│   (ESP32 + 7 Sensor)   │      │  (weather_station & history)│      │  (AppState Provider Manager) │
└────────────────────────┘      └─────────────────────────────┘      └──────────────┬───────────────┘
                                                                                    │
                                ┌─────────────────────────────┐                     │
                                │   Google Gemini AI Engine   │ ◄───────────────────┤
                                │ (Analyze, Chat & SmartAlert)│                     │
                                └─────────────────────────────┘                     ▼
                                ┌─────────────────────────────┐      ┌──────────────────────────────┐
                                │     Open-Meteo Weather API  │ ◄───►│  UI Dashboard / Hero Panel   │
                                │  (Geolocator GPS Provider)  │      │  (Sensor Cards & Analytics)  │
                                └─────────────────────────────┘      └──────────────────────────────┘
```

### 🛠️ Technology Stack:
- **Framework Mobile & Web**: Flutter 3.44+ (Dart 3.12)
- **State Management**: `provider` (Reactive AppState Architecture)
- **Backend Realtime Database**: Google Firebase Realtime Database
- **Artificial Intelligence**: Google Gemini 1.5 / 2.5 Flash API (`google_generative_ai`)
- **Internet Weather & Geocoding**: Open-Meteo API + `geolocator` + `geocoding`
- **Charts & Data Visualization**: `fl_chart` (Interactive Multi-sensor Curve Chart)
- **Design System & Motion**: Modern Glassmorphism, Google Fonts (`Outfit`), `flutter_animate`

---

## 🌊 3. Hero Panel (Ketinggian Air & Tanggul Realtime)

**Hero Panel** adalah komponen visual utama di bagian atas Dashboard yang berfungsi sebagai indikator utama ancaman banjir.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 📍 Jakarta Selatan                                            🟢 ONLINE     │
│ Sistem Monitoring Ketinggian Air                                            │
│                                                                             │
│      120 cm                  14:32:05                                       │
│    [ SAFE ]                 Sabtu, 8 Ags                                    │
│ Jarak Permukaan Air      32.5°C ⛅ Open-Meteo                                │
│                                                                             │
│ ~~~~~~~~~~~~~~~~~~~~~ Animasi Gelombang Air ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ │
│ ─────────────────────────────────────────────────────────────────────────── │
│ 🌡️ 31.5°C  │  💧 78%  │  💨 2.1 m/s  │  🔽 101.3 kPa  │  🔄 #1428           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔹 Fitur-Fitur Utama Hero Panel:
1. **Custom Canvas Animated Water Wave Painter (`_WaterWavePainter`)**:
   - Menampilkan visualisasi permukaan gelombang air yang bergerak secara dinamis sesuai persentase ketinggian air.
   - Formula kalkulasi kedalaman: `Fill = ((400cm - Jarak) / 400cm)`.

2. **Pengukuran Jarak Permukaan Air (Sensor Ultrasonik HC-SR04)**:
   - Angka berukuran super besar (62pt) yang menampilkan jarak aktual dari bibir sensor/tanggul ke permukaan air dalam satuan **centimeter (cm)**.
   - Dilengkapi animasi skala (`scaleXY`) dan kemunculan halus saat data ter-update.

3. **Status Risiko Ketinggian Air (`distanceLabel`)**:
   - **`SAFE` (Aman)**: Jarak air ke sensor $\ge 100\text{ cm}$. Warna hijau aksen.
   - **`HIGH LVL` (Siaga / Air Tinggi)**: Jarak air $50\text{ cm} \le x < 100\text{ cm}$. Warna kuning.
   - **`WARNING` (Waspada)**: Jarak air $20\text{ cm} \le x < 50\text{ cm}$. Warna oranye.
   - **`CRITICAL` (Bahaya / Kritis)**: Jarak air $< 20\text{ cm}$. Warna merah berkedip.

4. **Indikator Koneksi IoT Realtime (`_StatusDot`)**:
   - Menampilkan status **ONLINE** (hijau berdenyut/glowing) atau **OFFLINE** (merah) sesuai deteksi aliran data dari Firebase.

5. **Integrasi Jam Realtime & Lokasi GPS**:
   - Menampilkan jam digital `HH:mm:ss` dan tanggal lengkap yang diperbarui setiap detik.
   - Menampilkan nama kecamatan/kota pengguna dari GPS HP yang disinkronkan dengan data cuaca internet Open-Meteo.

6. **Quick Telemetry Chips**:
   - Chip ringkas di bagian bawah Hero Panel untuk pemantauan instan: Suhu, Kelembaban, Kecepatan Angin, Tekanan Udara, serta Frame Count data Firebase.

---

## 📊 4. Core Sensor Cards (Telemetri 6 Sensor ESP32)

Grid 2 kolom yang menampilkan 6 kartu telemetri fisik dari stasiun pemantau ESP32. Setiap kartu dilengkapi **Arc Gauge Custom Painter** yang melengkung presisi dengan gradien warna HSL khusus, nilai kuantitatif, label kualitatif, indikator tren (`↑` naik, `↓` turun, `—` stabil), dan badge perbandingan data internet.

```
┌──────────────────────────────┐  ┌──────────────────────────────┐
│ 🌡️ SUHU         Sensor ESP32  │  │ 💧 KELEMBABAN   Sensor ESP32  │
│ [ ↑ ]                        │  │ [ — ]                        │
│                              │  │                              │
│           31.5 °C            │  │             78 %             │
│            WARM              │  │            HUMID             │
│ ☁️ OpenWeather: 32.0°C       │  │ ☁️ OpenWeather: 75%         │
└──────────────────────────────┘  └──────────────────────────────┘
```

### 📋 Detail Sensor Cards:

| Nama Sensor | Parameter & Satuan | Rentang Ukur | Kategori Label Status | Warna UI |
| :--- | :--- | :--- | :--- | :--- |
| **Suhu** | Temperature (`°C`) | -10 s/d 50 °C | `FREEZING`, `COLD`, `COOL`, `MILD`, `WARM`, `HOT` | 🟠 Red-Orange (`AppTheme.colTemp`) |
| **Kelembaban** | Humidity (`%`) | 0 s/d 100 % | `DRY`, `COMFORT`, `MODERATE`, `HUMID` | 🔵 Cyan-Blue (`AppTheme.colHum`) |
| **Kecepatan Angin** | Wind Speed (`m/s`) | 0 s/d 20 m/s | `CALM`, `LIGHT`, `BREEZE`, `GENTLE`, `MODERATE`, `FRESH`, `STRONG` | 🩵 Teal Light (`AppTheme.colWind`) |
| **Intensitas Cahaya** | Light Intensity (`lx`) | 0 s/d 65.000 lx | `DARK`, `OVERCAST`, `CLOUDY`, `BRIGHT`, `SUNNY` | 🟡 Amber Gold (`AppTheme.colLight`) |
| **Curah Hujan** | Rainfall (`mm`) | 0 s/d 50 mm | `NO RAIN`, `LIGHT`, `MODERATE`, `HEAVY`, `EXTREME` | 🔷 Indigo Blue (`AppTheme.colRain`) |
| **Ketinggian Air** | Water Distance (`cm`) | 0 s/d 400 cm | `SAFE`, `HIGH LVL`, `WARNING`, `CRITICAL` | 🌊 Ocean Blue (`AppTheme.colDist`) |
| **Tegangan Baterai** | Voltage (`V`) | 8 s/d 14 V | `DEPLETED`, `LOW`, `GOOD`, `FULL` | 🔋 Emerald Green (`AppTheme.colBatt`) |

---

## 🧠 5. Fitur Kecerdasan Buatan (Google Gemini AI Engine)

Aplikasi ParamaFlood Monitor mengintegrasikan **Google Gemini AI (2.5 Flash / 1.5 Flash)** untuk mentransformasi data mentah sensor menjadi analisis bahasa manusia yang mudah dipahami.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🧠 ANALISIS KECERDASAN AI                          [ SKALA RISIKO: RENDAH ] │
│ Ringkasan Cuaca & Prediksi Banjir                                 [ 🔄 ]    │
│ ─────────────────────────────────────────────────────────────────────────── │
│ 🔔 ALERT: Hujan lebat terdeteksi. Ketinggian air meningkat 15cm dalam 10m. │
│ ─────────────────────────────────────────────────────────────────────────── │
│ "Berdasarkan pembacaan sensor ESP32 dan data Open-Meteo, kondisi wilayah    │
│  dalam status AMAN. Suhu udara 31.5°C dengan kelembaban 78%. Risiko banjir │
│  saat ini RENDAH karena jarak permukaan air ke tanggul masih 120 cm."       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 💡 4 Pilar Fitur Utama Gemini AI:

1. **Analisis Cuaca & Prediksi Risiko Banjir (`AiInsightPanel`)**:
   - Menganalisis gabungan data sensor ESP32, data riwayat 48 poin terakhir, dan perkiraan cuaca internet.
   - Menghasilkan ringkasan naratif beserta penetapan **Risk Badge Level**: `RENDAH`, `SEDANG`, `TINGGI`, atau `KRITIS`.

2. **ParaBot AI Chat Assistant (`AiChatPanel`)**:
   - Panel percakapan interaktif berbasis *Bottom Sheet Modal*.
   - Menginjeksikan status sensor *live* ke dalam *system prompt* Gemini, sehingga AI dapat menjawab pertanyaan spesifik pengguna seperti:
     - *"Apakah aman beraktivitas di luar rumah saat ini?"*
     - *"Berapa jarak air ke tanggul sekarang?"*
     - *"Mengapa suhu sensor beda dengan aplikasi cuaca lain?"*

3. **Smart Alert Banner System (`_checkSmartAlerts`)**:
   - Peringatan melayang otomatis (*Smart Banner*) yang muncul jika terjadi anomali ekstrem:
     - Air mendekati tanggul ($< 20\text{ cm}$).
     - Suhu indeks panas ekstrem ($> 40^\circ\text{C}$).
     - Baterai alat dropping ($< 10.5\text{V}$).
   - Dilengkapi *cooldown protection logic* (maksimal 1 alert per 30 menit) untuk menghemat kuota *free tier* API Gemini.

4. **Laporan Harian Otomatis (`generateDailyReport`)**:
   - Membuat rekapitulasi performa stasiun cuaca dan tren ancaman banjir harian secara terstruktur.

---

## 📈 6. Riwayat & Analisis Grafis (`HistoryScreen`)

Layar **Riwayat (`HistoryScreen`)** menyajikan analisis mendalam terkait tren perubahan data sensor dari waktu ke waktu.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 📈 HISTORY & ANALYTICS                                                       │
│ Rolling sensor history across the last 48 readings                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔹 Komponen Utama Layar Riwayat:

1. **HistoryChart (Interactive FL Chart)**:
   - 8 Tab Sensor (`Suhu`, `Kelembaban`, `Tekanan`, `Angin`, `Ketinggian Air`, `Baterai`, `Cahaya`, `Hujan`).
   - Menampilkan grafik garis bersinar (*glowing curved line chart*) dari 48 poin rekaman data terakhir di Firebase.
   - Dilengkapi nilai rata-rata (*Average*), nilai maksimum (*Peak*), dan minimum (*Lowest*).

2. **ComparisonPanel (Sensor Physical vs Internet Weather API)**:
   - Panel komparasi antara pembacaan fisik stasiun ESP32 dengan data satelit Open-Meteo.
   - **Audit Anomali Otomatis**: Menampilkan peringatan jika terjadi selisih signifikan (misal: suhu sensor lebih panas $> 3^\circ\text{C}$ dibanding internet akibat paparan sinar matahari langsung).

---

## ⚙️ 7. Layar Pengaturan & Informasi Tim (`SettingsScreen`)

Layar **Pengaturan (`SettingsScreen`)** mencakup informasi kredensial proyek, status perangkat, dan peta jalan (*roadmap*) pengembangan.

### 📋 Informasi Proyek & Tim:
- **Nama Aplikasi**: ParamaFlood Monitor
- **Versi**: 2.0.0 (Phase 1 Prototyping)
- **Arsitektur**: ESP32 IoT Microcontroller + Flutter Mobile/Web + Firebase RTDB
- **Institusi**: Universitas Paramadina
- **Tim Peneliti**: **Ariel**, **Naina**, dan **Arya**

### 📍 Card Device Location:
- Menampilkan lokasi geografis GPS stasiun/device.
- Tombol tindakan cepat (*Quick Action*): **Retry Location** (jika GPS terlepas) dan **Open Settings** (jika izin lokasi ditolak).

### 🚀 Roadmap Pengembangan Phase 2:
1. **Push Notifications (FCM)**: Notifikasi bahaya banjir langsung ke HP pengguna (*background service*).
2. **Prediksi AI LSTM**: Estimasi kenaikan air 3 jam ke depan menggunakan model Deep Learning LSTM.
3. **Data Export CSV/PDF**: Fitur unduh riwayat telemetri sensor untuk kebutuhan jurnal & skripsi.
4. **Full Bahasa Indonesia**: Lokalisasi bahasa aplikasi secara menyeluruh.

---

## 🎨 8. Branding Visual & Launcher Icons

- **Splash Screen**: Tampilan pembuka aplikasi dengan efek gelombang air dan logo resmi `assets/images/splashscreen.png` / `splashscreen.jpg`.
- **App Launcher Icon**: Launcher icon Android, iOS, dan Web terintegrasi menggunakan `assets/images/Logo.jpg` / `Logo.jpeg`.
- **Top Bar Branding**: Header aplikasi bersih (*clean design*) tanpa box latar belakang, menampilkan logo ParamaFlood secara presisi.

---

## 🏆 Kesimpulan

Aplikasi **ParamaFlood Monitor** karya **Ariel, Naina, dan Arya (Universitas Paramadina)** merupakan solusi IoT dan Artificial Intelligence terdepan yang mengintegrasikan pengawasan fisik sensor dan kecerdasan analisis untuk keselamatan masyarakat dari ancaman banjir.
