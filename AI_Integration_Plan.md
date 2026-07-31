# 🤖 Rencana Integrasi AI — Paramaflood

> **Untuk Lomba IoT — Tema AI**
> Tim: Arya, Aril, Naina
> Terakhir diperbarui: Juli 2026

---

## 📋 Daftar Isi

1. [Ringkasan Sistem Kita Sekarang](#-ringkasan-sistem-kita-sekarang)
2. [Apa Itu Gemini API?](#-apa-itu-gemini-api)
3. [5 Fitur AI yang Akan Dibuat](#-5-fitur-ai-yang-akan-dibuat)
4. [Arsitektur Sistem](#-arsitektur-sistem-setelah-ditambah-ai)
5. [Cara Setup Gemini API](#-cara-setup-gemini-api-step-by-step)
6. [Implementasi Teknis](#-implementasi-teknis)
7. [Prompt Engineering](#-prompt-engineering-cara-ngomong-ke-ai)
8. [File yang Perlu Dibuat/Diubah](#-file-yang-perlu-dibuatdiubah)
9. [Pembagian Tugas](#-pembagian-tugas)
10. [Timeline](#-timeline)
11. [Tips Lomba](#-tips-lomba)
12. [Batas Pemakaian Gratis](#-batas-pemakaian-gratis-gemini-free-tier)

---

## 🏗 Ringkasan Sistem Kita Sekarang

### Apa yang Sudah Ada

Sistem Paramaflood kita sekarang punya 4 lapisan:

| Lapisan | Teknologi | Fungsi |
|---------|-----------|--------|
| **Hardware** | ESP32 + Sensor-sensor | Mengumpulkan data cuaca & banjir dari lingkungan |
| **Cloud** | Firebase Realtime Database | Menyimpan data secara real-time ke cloud |
| **Aplikasi** | Flutter (Android/iOS/Web) | Menampilkan dashboard, grafik, perbandingan data |
| **API Cuaca** | Open-Meteo | Mengambil data cuaca internet sebagai pembanding |

### Data yang Dikumpulkan Sensor ESP32

Setiap ~1 detik, ESP32 mengirim data berikut ke Firebase:

| Sensor | Data | Satuan | Contoh |
|--------|------|--------|--------|
| DHT22 | Suhu | °C | 28.5 |
| DHT22 | Kelembaban | % | 72.0 |
| Anemometer | Kecepatan Angin | m/s | 3.2 |
| DFRobot Ambient Light | Cahaya | lux | 15000 |
| Rain Gauge | Curah Hujan | mm | 2.5 |
| JSN-SR04T (Ultrasonik) | Jarak ke Air | cm | 85.0 |
| Voltage Divider | Tegangan Baterai | V | 12.1 |

### Data dari Open-Meteo (Internet)

Setiap 10 menit, aplikasi mengambil data cuaca dari internet:

| Data | Contoh |
|------|--------|
| Suhu internet | 29.0°C |
| Kelembaban internet | 68% |
| Kecepatan angin internet | 2.8 m/s |
| Tekanan udara internet | 1010 hPa |
| Kode cuaca (WMO) | 3 (Berawan) |
| Lokasi | Jakarta |

---

## 🤖 Apa Itu Gemini API?

**Gemini** adalah AI buatan Google (sama kayak ChatGPT tapi punya Google). Kita bisa "ngobrol" sama Gemini lewat kode program — kirim data sensor kita, lalu minta Gemini menganalisis dan memberikan insight.

### Cara Kerjanya (Simpel)

```
Kita kirim:
"Hei Gemini, ini data sensor saya:
 - Suhu: 28°C
 - Tekanan: 998 hPa (turun dari 1015 tadi pagi)
 - Air naik 18cm dalam 2 jam
 - Hujan: 12mm/jam
 Tolong analisis apakah ada risiko banjir?"

Gemini jawab:
"⚠️ Risiko banjir TINGGI. Tekanan udara turun drastis 17 hPa
 menunjukkan badai mendekat. Air naik cepat 9cm/jam.
 Estimasi 3 jam lagi mencapai level kritis.
 Saran: Siapkan jalur evakuasi sekarang."
```

### Kenapa Gemini?

| Keunggulan | Penjelasan |
|------------|------------|
| **Gratis** | Free tier cukup untuk proyek kita (1.500 request/hari) |
| **Mudah** | Ada package Flutter resmi (`google_generative_ai`) |
| **Google** | Cocok sama ecosystem kita (Firebase + Flutter = Google juga) |
| **Cepat** | Model `gemini-2.5-flash` responsnya < 2 detik |

---

## 🎯 5 Fitur AI yang Akan Dibuat

### Fitur 1: 🧠 Analis Cuaca AI (WAJIB — Prioritas Utama)

**Apa ini?**
Saat ini, analisis cuaca kita pakai kode hardcode (aturan tetap), contoh:

```dart
// Kode sekarang (bodoh, cuma cek satu variabel)
if (sensor.temp - internet.temp > 5) {
  issues.add('Temp Δ5.3°C — check sensor placement');
}
if (sensor.pres < 990) {
  issues.add('Low pressure — possible storm approaching');
}
```

**Masalahnya**: Kode ini cuma bisa cek satu variabel satu-satu. Dia nggak bisa GABUNGKAN semua data untuk analisis yang lebih cerdas.

**Dengan AI**: Kita kirim SEMUA data sensor + history + cuaca internet ke Gemini. AI bisa menghubungkan semuanya:

> *"🌧️ Analisis Cuaca — 29 Juli 2026, 14:00 WIB*
>
> *Tekanan udara turun dari 1015 ke 998 hPa dalam 3 jam terakhir, sementara kelembaban melonjak ke 92%. Curah hujan meningkat dari 2mm ke 8mm/jam. Dikombinasikan dengan kenaikan permukaan air sebesar 18cm, ini menunjukkan sistem badai sedang mendekat.*
>
> *Risiko Banjir: **TINGGI** 🔴*
>
> *Saran: Pantau ketinggian air setiap 15 menit. Siapkan jalur evakuasi untuk area rendah. Perkiraan waktu mencapai level kritis: ~3.5 jam."*

**Kenapa ini penting untuk lomba?**
- Menunjukkan bahwa sistem kita bukan cuma MENAMPILKAN data, tapi MEMAHAMI data
- Ini pembeda utama dari proyek IoT biasa

---

### Fitur 2: 🌊 Prediksi Risiko Banjir AI (WAJIB — Prioritas Utama)

**Apa ini?**
AI menilai risiko banjir berdasarkan KOMBINASI banyak faktor, bukan cuma ketinggian air.

**Faktor yang dipertimbangkan AI:**

```
Tren ketinggian air (naik/stabil/turun)         ──┐
+ Intensitas hujan (tidak ada/ringan/sedang/deras) │
+ Tren tekanan udara (turun = cuaca buruk datang)  ├─→ AI Flood Risk Score
+ Prakiraan cuaca internet                         │
+ Data historis                                   ──┘
```

**Contoh Output AI:**

| Situasi | Analisis AI |
|---------|------------|
| Air stabil, tidak hujan, tekanan naik | *"🟢 Risiko Banjir: RENDAH (12%). Kondisi aman. Tidak ada indikasi hujan dalam beberapa jam ke depan."* |
| Hujan ringan, air mulai naik | *"🟡 Risiko Banjir: SEDANG (45%). Hujan ringan terdeteksi. Air naik 3cm/jam. Pantau terus."* |
| Hujan deras, air naik cepat, tekanan turun | *"🔴 Risiko Banjir: TINGGI (82%). Air naik 8cm/jam dengan hujan deras 15mm/jam. Estimasi 2 jam mencapai level kritis!"* |

**💡 Catatan**: Fitur 1 dan Fitur 2 bisa DIGABUNG jadi satu panggilan API (satu prompt). Jadi hemat kuota.

---

### Fitur 3: 💬 Asisten Chat AI (BONUS — Bikin Juri Kagum)

**Apa ini?**
Panel chat di dalam aplikasi. User bisa bertanya tentang data cuaca mereka.

**Contoh percakapan:**

```
👤 User: "Apakah aman untuk beraktivitas di luar?"

🤖 ParaBot: "Berdasarkan data sensor saat ini:
   - Suhu: 34°C dengan kelembaban 78%
   - Heat Index (terasa seperti): 42°C
   - Tidak ada hujan terdeteksi
   - Angin: 2.1 m/s (sepoi-sepoi)

   ⚠️ Disarankan menghindari aktivitas berat di luar ruangan
   karena heat index tinggi. Risiko heat stroke.
   Jika harus keluar, bawa minum dan istirahat rutin."
```

```
👤 User: "Kenapa suhu sensor beda jauh sama internet?"

🤖 ParaBot: "Sensor membaca 38.2°C sementara internet
   menunjukkan 31°C (selisih 7.2°C). Kemungkinan penyebab:
   1. Sensor terkena sinar matahari langsung
   2. Sensor terlalu dekat dengan permukaan beton/aspal
   3. Ventilasi housing sensor kurang baik

   Saran: Pastikan sensor berada dalam radiation shield
   dan terlindung dari sinar matahari langsung."
```

**Cara kerjanya:**
- User ketik pertanyaan
- Aplikasi kirim pertanyaan + data sensor terbaru ke Gemini
- Gemini jawab berdasarkan data aktual (bukan jawaban generik)

---

### Fitur 4: 📊 Laporan Harian AI (BONUS)

**Apa ini?**
Sekali sehari, AI otomatis membuat ringkasan cuaca hari itu dari semua data yang terkumpul.

**Contoh Output:**

> *📅 Laporan Harian Paramaflood — 29 Juli 2026*
>
> *🌡️ Suhu: Min 24.2°C (05:00), Max 33.8°C (14:00), Rata-rata 28.5°C*
> *💧 Kelembaban: Rentang 52-89%, rata-rata 68%*
> *🌧️ Curah hujan total: 12.3mm (kategori ringan-sedang)*
> *🌊 Ketinggian air: Stabil, rentang 115-125cm (AMAN)*
> *🔋 Baterai: Sehat di 12.1V*
>
> *📝 Catatan: Terjadi lonjakan suhu pada pukul 14:00 (38°C) yang kemungkinan disebabkan paparan sinar matahari langsung ke sensor. Hujan ringan terjadi pukul 16:00-17:30.*
>
> *Tidak ada kejadian banjir hari ini. ✅*

**Kapan dipanggil:** Sekali sehari (bisa pukul 23:59 atau saat user minta)

---

### Fitur 5: ⚡ Notifikasi Cerdas AI (BONUS)

**Apa ini?**
Saat ini, notifikasi kita pakai aturan sederhana:
```dart
// Sekarang (kaku)
if (distance < 20) {
  showNotification("Water level critical: 18cm");
}
```

**Dengan AI**, notifikasi jadi lebih informatif dan kontekstual:

| Notifikasi Lama | Notifikasi AI |
|-----------------|---------------|
| *"Water level critical: 18cm"* | *"⚠️ PERINGATAN BANJIR: Ketinggian air 18cm dan masih NAIK (+5cm/jam). Hujan deras 15mm/jam. Segera evakuasi area rawan banjir!"* |
| *"Temperature high: 38°C"* | *"🌡️ Suhu tinggi 38°C dengan kelembaban 75%. Heat index 45°C. Hindari aktivitas luar ruangan. Pastikan hidrasi cukup."* |
| *"Battery low: 9.5V"* | *"🔋 Baterai lemah 9.5V (estimasi sisa 12 jam). Segera isi ulang atau ganti baterai untuk menjaga monitoring banjir tetap aktif."* |

---

## 🏛 Arsitektur Sistem (Setelah Ditambah AI)

```
┌──────────────────────────────────────────────────────────────────┐
│                       APLIKASI FLUTTER                           │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Dashboard    │  │ Panel AI     │  │ Chat AI (opsional)      │ │
│  │ (yang sudah  │  │ Insight      │  │ Tanya jawab soal cuaca  │ │
│  │  ada)        │  │ (BARU)       │  │ (BARU)                  │ │
│  └──────┬──────┘  └──────┬───────┘  └────────┬────────────────┘ │
│         │                │                    │                  │
│         └────────────────┼────────────────────┘                  │
│                          ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    AppState (State Management)            │   │
│  │                                                           │   │
│  │  Data yang sudah ada:           Data baru:                │   │
│  │  - live (data sensor ESP32)     - aiAnalysis (teks AI)    │   │
│  │  - history[] (riwayat)          - floodRisk (skor)        │   │
│  │  - internet (Open-Meteo)        - chatMessages[]          │   │
│  └───────────┬────────────────────────┬─────────────────────┘   │
│              │                        │                          │
│              ▼                        ▼                          │
│  ┌───────────────────────┐   ┌───────────────────────┐          │
│  │ Firebase Service       │   │ Gemini Service (BARU) │          │
│  │ (sudah ada)            │   │                       │          │
│  │                        │   │ - analyzeWeather()    │          │
│  │ - Ambil data sensor    │   │ - assessFloodRisk()   │          │
│  │ - Simpan riwayat       │   │ - chat()              │          │
│  │                        │   │ - dailyReport()       │          │
│  └───────────────────────┘   └───────────┬───────────┘          │
│                                          │                       │
└──────────────────────────────────────────┼───────────────────────┘
                                           │ HTTP Request
                                           ▼
                              ┌────────────────────────┐
                              │    Google Gemini API    │
                              │    (gratis, cloud)      │
                              │                        │
                              │    Model: gemini-2.5   │
                              │    flash               │
                              └────────────────────────┘
```

### Alur Data (Sederhana)

```
ESP32 Sensor ──(kirim data)──→ Firebase ──(stream)──→ Flutter App
                                                          │
                                                          ├── Tampilkan di Dashboard (sudah ada)
                                                          │
                                                          └── Kirim ke Gemini API (BARU)
                                                                    │
                                                                    ▼
                                                              AI Analisis
                                                              & Prediksi
                                                                    │
                                                                    ▼
                                                          Tampilkan di Panel AI (BARU)
```

---

## 🔑 Cara Setup Gemini API (Step by Step)

### Langkah 1: Dapatkan API Key

1. Buka browser, pergi ke: **https://aistudio.google.com/apikey**
2. Login pakai akun Google
3. Klik **"Create API Key"**
4. Pilih project (atau buat baru)
5. **Copy API key** yang muncul (contoh: `AIzaSyD...panjang...xyz`)
6. Simpan di tempat aman, JANGAN share ke publik

### Langkah 2: Tambah Package ke Project Flutter

Buka terminal di folder project, jalankan:

```bash
flutter pub add google_generative_ai
```

Ini akan otomatis menambahkan ke `pubspec.yaml`:
```yaml
dependencies:
  google_generative_ai: ^0.4.0
```

### Langkah 3: Buat File API Key

Buat file baru: `lib/config/api_keys.dart`
```dart
// ⚠️ FILE INI JANGAN DI-PUSH KE GITHUB!
// Tambahkan ke .gitignore

class ApiKeys {
  // Ganti dengan API key asli dari Google AI Studio
  static const geminiApiKey = 'PASTE_API_KEY_KAMU_DISINI';
}
```

### Langkah 4: Tambahkan ke .gitignore

Buka file `.gitignore` di root project, tambahkan baris:
```
# Gemini API Key — jangan di-push!
lib/config/api_keys.dart
```

**⚠️ PENTING**: API key itu kayak password. Kalau sampai ke-push ke GitHub publik, orang lain bisa pakai kuota gratis kita.

---

## 🔧 Implementasi Teknis

### File: `lib/services/gemini_service.dart` (BARU)

Ini adalah service utama yang menghubungkan aplikasi kita ke Gemini AI.

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/weather_data.dart';

class GeminiService {
  late final GenerativeModel _model;
  DateTime? _lastCallTime;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',    // Model cepat & gratis (2.0-flash free tier sudah limit:0)
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,            // 0 = kaku, 1 = kreatif. 0.7 = seimbang
        maxOutputTokens: 500,        // Batas panjang jawaban AI
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 1 & 2: Analisis Cuaca + Prediksi Banjir
  //  (Digabung jadi satu panggilan API biar hemat kuota)
  // ══════════════════════════════════════════════════════════
  Future<String> analyzeWeather({
    required WeatherData current,        // Data sensor sekarang
    required List<WeatherData> history,  // Riwayat 48 data terakhir
    InternetWeather? internet,           // Data cuaca internet
  }) async {
    // Rate limiting: minimal 1 menit antar panggilan
    if (_lastCallTime != null &&
        DateTime.now().difference(_lastCallTime!) < Duration(minutes: 1)) {
      return 'Tunggu sebentar...';
    }
    _lastCallTime = DateTime.now();

    // Bangun prompt (lihat bagian Prompt Engineering di bawah)
    final prompt = _buildAnalysisPrompt(current, history, internet);

    try {
      // Kirim ke Gemini, tunggu jawaban
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'AI tidak bisa menganalisis saat ini.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 3: Chat — Tanya jawab soal cuaca
  // ══════════════════════════════════════════════════════════
  Future<String> chat({
    required String pertanyaanUser,      // Pertanyaan dari user
    required WeatherData current,        // Data sensor sekarang
    required List<WeatherData> history,  // Riwayat
  }) async {
    final konteksData = _buildDataContext(current, history);

    final prompt = '''
Kamu adalah "ParaBot", asisten AI untuk sistem pemantauan banjir Paramaflood.
Kamu bisa melihat data sensor cuaca real-time dari stasiun cuaca ESP32.

Data sensor saat ini:
$konteksData

Pertanyaan user: $pertanyaanUser

Aturan:
- Jawab dalam bahasa yang sama dengan pertanyaan user
- Gunakan angka aktual dari data sensor dalam jawabanmu
- Jawaban maksimal 150 kata
- Untuk pertanyaan keselamatan banjir, selalu utamakan kehati-hatian
- Jika ditanya hal di luar cuaca/banjir, arahkan kembali dengan sopan
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Maaf, tidak bisa menjawab saat ini.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 4: Laporan Harian
  // ══════════════════════════════════════════════════════════
  Future<String> generateDailyReport({
    required List<WeatherData> todayHistory,
  }) async {
    // ... mirip analyzeWeather tapi promptnya minta ringkasan harian
    // Implementasi nanti
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 5: Notifikasi Cerdas
  // ══════════════════════════════════════════════════════════
  Future<String> generateSmartAlert({
    required WeatherData current,
    required String alertType,  // 'flood', 'heat', 'battery', dll
  }) async {
    // ... mirip tapi prompt minta notifikasi singkat
    // Implementasi nanti
  }

  // ── Helper: Bangun konteks data sensor ──────────────────
  String _buildDataContext(WeatherData d, List<WeatherData> history) {
    return '''
- Suhu: ${d.temp.toStringAsFixed(1)}°C (${d.tempLabel})
- Kelembaban: ${d.hum.toStringAsFixed(0)}% (${d.humLabel})
- Kecepatan Angin: ${d.wind.toStringAsFixed(1)} m/s (${d.windLabel})
- Cahaya: ${d.light.toStringAsFixed(0)} lux (${d.lightLabel})
- Curah Hujan: ${d.rain.toStringAsFixed(1)} mm (${d.rainLabel})
- Jarak ke Air: ${d.distance.toStringAsFixed(1)} cm (${d.distanceLabel})
- Baterai: ${d.battery.toStringAsFixed(1)} V (${d.batteryLabel})
- Heat Index: ${d.feelsLike.toStringAsFixed(1)}°C
- Jumlah data riwayat: ${history.length} pembacaan
''';
  }

  // ── Helper: Bangun prompt analisis lengkap ──────────────
  String _buildAnalysisPrompt(
    WeatherData current,
    List<WeatherData> history,
    InternetWeather? internet,
  ) {
    // Lihat bagian Prompt Engineering di bawah
    return '...'; // Template lengkap ada di bawah
  }
}
```

### Penjelasan Kode di Atas

| Bagian | Penjelasan |
|--------|------------|
| `GenerativeModel(...)` | Membuat koneksi ke Gemini API. Cukup sekali saat app dibuka |
| `temperature: 0.7` | Seberapa "kreatif" AI. 0 = selalu jawab sama, 1 = sangat kreatif |
| `maxOutputTokens: 500` | Batas panjang jawaban (~375 kata). Biar jawaban ringkas |
| `_lastCallTime` | Mencegah spam ke API. Minimal 1 menit antar panggilan |
| `Content.text(prompt)` | Mengirim teks prompt ke Gemini |
| `response.text` | Jawaban AI dalam bentuk String |

---

## 📝 Prompt Engineering (Cara "Ngomong" ke AI)

Prompt itu = instruksi yang kita kirim ke AI. Semakin bagus prompt, semakin bagus jawabannya.

### Template Prompt Analisis Cuaca + Banjir

```
Kamu adalah ahli meteorologi AI untuk Paramaflood, sistem peringatan dini banjir IoT di Indonesia.

## Data Sensor ESP32 (Real-time)
- Suhu: {temp}°C ({tempLabel})
- Kelembaban: {hum}% ({humLabel})
- Kecepatan Angin: {wind} m/s ({windLabel})
- Cahaya: {light} lux ({lightLabel})
- Curah Hujan: {rain} mm ({rainLabel})
- Jarak Ultrasonik ke Air: {distance} cm ({distanceLabel})
- Baterai: {battery}V ({batteryLabel})
- Heat Index (Terasa Seperti): {feelsLike}°C

## Data Cuaca Internet (Open-Meteo — {location})
- Suhu: {iTemp}°C
- Kelembaban: {iHum}%
- Angin: {iWind} m/s
- Tekanan: {iPres} hPa
- Kondisi: {iCondition}

## Tren (dari {N} pembacaan terakhir)
- Tren suhu: {tempTrend} (Δ{tempDelta}°C)
- Tren ketinggian air: {waterTrend} (Δ{waterDelta} cm)
- Akumulasi hujan 1 jam terakhir: {rainTotal} mm

## Tugasmu
Berikan analisis cuaca singkat (maksimal 200 kata) yang mencakup:
1. **Kondisi Saat Ini** — Ringkasan singkat kondisi cuaca
2. **Penilaian Risiko Banjir** — Beri rating RENDAH/SEDANG/TINGGI/KRITIS dengan alasan
3. **Peringatan** — Anomali atau hal yang perlu diperhatikan
4. **Rekomendasi** — Apa yang harus dilakukan warga?

Jawab dalam Bahasa Indonesia. Gunakan emoji untuk kejelasan visual.
Gunakan angka spesifik dari data. Jangan jawab generik.
```

### Cara Pakai Template

Ganti semua `{...}` dengan data aktual dari sensor. Contoh:
- `{temp}` → `28.5`
- `{tempLabel}` → `WARM`
- `{distance}` → `85.0`
- dst.

Di kode Dart, pakai string interpolation:
```dart
final prompt = '''
...
- Suhu: ${current.temp.toStringAsFixed(1)}°C (${current.tempLabel})
- Kelembaban: ${current.hum.toStringAsFixed(0)}% (${current.humLabel})
...
''';
```

---

## 🗂 File yang Perlu Dibuat/Diubah

### File BARU (yang harus dibuat dari nol)

| File | Fungsi | Estimasi Baris |
|------|--------|----------------|
| `lib/config/api_keys.dart` | Menyimpan API key Gemini | ~5 baris |
| `lib/services/gemini_service.dart` | Service utama komunikasi dengan Gemini API | ~150-200 baris |
| `lib/widgets/ai_insight_panel.dart` | Widget tampilan analisis AI di dashboard | ~200-300 baris |
| `lib/widgets/ai_chat_panel.dart` | Widget chat dengan AI (opsional) | ~250-350 baris |

### File yang DIMODIFIKASI (sudah ada, perlu ditambah)

| File | Perubahan |
|------|-----------|
| `lib/services/app_state.dart` | Tambah instance GeminiService, state untuk AI analysis, method untuk refresh AI |
| `lib/screens/dashboard_screen.dart` | Tambah AiInsightPanel widget ke dalam layout dashboard |
| `pubspec.yaml` | Tambah dependency `google_generative_ai` |
| `.gitignore` | Tambah `lib/config/api_keys.dart` |

### Visualisasi Struktur Folder

```
lib/
├── config/
│   └── api_keys.dart              ← BARU (API key, jangan push ke git!)
├── models/
│   └── weather_data.dart          (tidak diubah)
├── services/
│   ├── app_state.dart             ← DIMODIFIKASI (tambah AI state)
│   ├── app_theme.dart             (tidak diubah)
│   ├── firebase_service.dart      (tidak diubah)
│   ├── gemini_service.dart        ← BARU (service komunikasi ke Gemini)
│   └── location_weather_service.dart (tidak diubah)
├── widgets/
│   ├── ai_insight_panel.dart      ← BARU (tampilan analisis AI)
│   ├── ai_chat_panel.dart         ← BARU (opsional, chat dengan AI)
│   ├── analytics_panel.dart       (tidak diubah)
│   ├── hero_panel.dart            (tidak diubah)
│   └── sensor_card.dart           (tidak diubah)
├── screens/
│   ├── dashboard_screen.dart      ← DIMODIFIKASI (tambah panel AI)
│   ├── history_screen.dart        (tidak diubah)
│   ├── main_shell.dart            (tidak diubah)
│   ├── onboarding_screen.dart     (tidak diubah)
│   ├── settings_screen.dart       (tidak diubah)
│   └── splash_screen.dart         (tidak diubah)
├── firebase_options.dart          (tidak diubah)
└── main.dart                      (tidak diubah)
```

---

## 👥 Pembagian Tugas

Isi nama kalian di kolom "Siapa":

| Tugas | Siapa | Prioritas | Estimasi Waktu |
|-------|-------|-----------|----------------|
| Buat API key di Google AI Studio | **???** | 🔴 WAJIB | 30 menit |
| Buat `api_keys.dart` + update `.gitignore` | **???** | 🔴 WAJIB | 15 menit |
| Buat `gemini_service.dart` (service utama) | **???** | 🔴 WAJIB | 2-3 jam |
| Tulis & test prompt (prompt engineering) | **???** | 🔴 WAJIB | 2-3 jam |
| Buat `ai_insight_panel.dart` (UI panel AI) | **???** | 🔴 WAJIB | 2-3 jam |
| Modifikasi `app_state.dart` (tambah AI state) | **???** | 🔴 WAJIB | 1-2 jam |
| Modifikasi `dashboard_screen.dart` (taruh panel AI) | **???** | 🟡 SEDANG | 1 jam |
| Buat `ai_chat_panel.dart` (chat UI) | **???** | 🟢 BONUS | 3-4 jam |
| Error handling + rate limiting | **???** | 🟡 SEDANG | 1-2 jam |
| Testing dengan data sensor asli | **SEMUA** | 🔴 WAJIB | 2-3 jam |
| Persiapan demo lomba | **SEMUA** | 🔴 WAJIB | 2-3 jam |

---

## ⏰ Timeline

### Fase 1: Fondasi AI (Hari 1-2) — WAJIB SELESAI

- [ ] Setup API key Gemini
- [ ] Tambah package `google_generative_ai`
- [ ] Buat `gemini_service.dart` dengan method `analyzeWeather()`
- [ ] Buat `ai_insight_panel.dart` (UI dasar)
- [ ] Integrasikan ke dashboard
- [ ] Test dengan data sensor asli

### Fase 2: Kecerdasan Banjir (Hari 2-3) — WAJIB SELESAI

- [ ] Tulis prompt khusus prediksi banjir
- [ ] Buat badge/indikator risiko banjir (warna: hijau/kuning/oranye/merah)
- [ ] Fine-tune prompt biar akurat
- [ ] Test skenario ekstrem (hujan deras, air naik cepat)

### Fase 3: Chat + Polish (Hari 3-4) — BONUS

- [ ] Buat `ai_chat_panel.dart` (UI chat)
- [ ] Integrasikan chat ke dalam app
- [ ] Fitur laporan harian
- [ ] Loading states + error handling
- [ ] Rate limiting yang proper

### Fase 4: Persiapan Lomba (Hari 5)

- [ ] Siapkan skenario demo
- [ ] Test edge cases
- [ ] Polish UI + animasi
- [ ] Buat slide presentasi

---

## 💡 Tips Lomba

### 1. Demo dengan Data Asli
Bawa ESP32 yang nyala saat demo. Tunjukkan AI menganalisis data real-time. Ini 10x lebih impresif daripada data dummy.

### 2. Simulasi Banjir
Pelan-pelan dekatkan sensor ultrasonik ke air untuk simulasi kenaikan level air. Tunjukkan bagaimana AI mendeteksi tren dan menaikkan level peringatan.

### 3. Tunjukkan Perbandingan: Sebelum vs Sesudah AI

| Sebelum AI (Sekarang) | Sesudah AI |
|----------------------|------------|
| *"Low pressure — possible storm approaching"* | *"Tekanan turun 17 hPa dalam 3 jam terakhir, dikombinasikan dengan hujan 12mm/jam dan air naik 18cm. Risiko banjir TINGGI."* |

Perbedaannya SANGAT jelas. AI bisa menggabungkan semua data, kode hardcode tidak bisa.

### 4. Tekankan "Kenapa AI"
> *"Aturan if-else hanya bisa cek satu variabel. AI bisa mengkorelasikan 8 sensor sekaligus dan memberikan analisis yang manusia butuhkan."*

### 5. Argumen Biaya
Gemini free tier = Rp 0 untuk seluruh sistem. Ini membuat sistem viable untuk deployment nyata di daerah rawan banjir di Indonesia.

### 6. Bilingual
Tunjukkan AI bisa menjawab dalam Bahasa Indonesia DAN Inggris. Juri suka fleksibilitas ini.

---

## 📊 Batas Pemakaian Gratis (Gemini Free Tier)

> ⚠️ **PENTING — Pelajaran dari lapangan (Juli 2026):**
> Model **`gemini-2.0-flash` sudah TIDAK punya free tier** (`limit: 0` → error 429 `RESOURCE_EXHAUSTED`).
> Gunakan **`gemini-2.5-flash`** yang masih gratis. Ini sudah diterapkan di kode.
>
> Selain itu, API key **HARUS** berformat `AIzaSy...` dari [Google AI Studio](https://aistudio.google.com/apikey).
> Token berformat `AQ.Ab8...` (OAuth/ephemeral) akan terautentikasi tapi tetap `limit: 0`.

### Berapa Kuota Gratis?

| Batas | Nilai | Artinya |
|-------|-------|---------|
| Request per menit (RPM) | **15** | Maksimal 15 panggilan API per menit |
| Request per hari (RPD) | **1.500** | Maksimal 1.500 panggilan per hari |
| Token per menit (TPM) | **1.000.000** | Token = satuan teks. 1 token ≈ 0.75 kata |

### Estimasi Pemakaian Kita (Semua 5 Fitur)

| Fitur | Seberapa Sering | Panggilan/Hari | Token/Panggilan |
|-------|-----------------|----------------|-----------------|
| 🧠 Analisis Cuaca | Setiap 15 menit | ~96 | ~800 |
| 🌊 Prediksi Banjir | Digabung dengan ☝️ | **0 tambahan** | sudah termasuk |
| 💬 Chat AI | Saat user bertanya | ~20-50 | ~600 |
| 📊 Laporan Harian | 1x per hari | **1** | ~1.000 |
| ⚡ Notifikasi Cerdas | Saat ada event | ~5-10 | ~400 |

### Total Pemakaian vs Batas

| Metrik | Pemakaian Kita | Batas Gratis | Persentase |
|--------|----------------|--------------|------------|
| Panggilan/hari | ~120-160 | 1.500 | **~10%** ✅ |
| Panggilan/menit (peak) | ~2-3 | 15 | **~20%** ✅ |
| Token/panggilan | ~800 rata-rata | 1.000.000/menit | **~0.08%** ✅ |

**✅ Kesimpulan: SEMUA 5 fitur bisa jalan di free tier, bahkan kalau 3 HP pakai app sekaligus!**

---

## 📚 Link Penting

| Resource | Link |
|----------|------|
| Dapatkan API Key | https://aistudio.google.com/apikey |
| Package Flutter Gemini | https://pub.dev/packages/google_generative_ai |
| Dokumentasi Gemini API | https://ai.google.dev/gemini-api/docs |
| Harga & Batas Gratis | https://ai.google.dev/pricing |
| Panduan Prompt Engineering | https://ai.google.dev/gemini-api/docs/prompting-strategies |

---

> **Ayo gas tim, kita masak yang enak 🔥🫡**
>
> Kalau ada pertanyaan atau bingung bagian mana, tanya aja.
> Kita bisa mulai ngoding kapan aja udah siap.
