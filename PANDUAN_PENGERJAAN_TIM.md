# 📘 Panduan Pengerjaan Teknis Super-Detail — Team Ariel & Naina

> **Project:** Paramaflood IoT & Weather Monitor (AI Competition Integration)  
> **Target:** Integrasi Gemini AI 2.0 Flash + UI Premium + Logo Branding  
> **Stack:** Flutter (Dart), Firebase Realtime DB, Google Generative AI (Gemini)

---

## 📌 Daftar Isi
1. [Struktur File & Modifikasi](#1-struktur-file--modifikasi)
2. [⚙️ PANDUAN NAINA — Backend & Service AI](#2-panduan-naina--backend--service-ai)
   - [Langkah 1: Setup API Key & Dependency](#langkah-1-setup-api-key--dependency)
   - [Langkah 2: Membuat `lib/config/api_keys.dart`](#langkah-2-membuat-libconfigapi_keysdart)
   - [Langkah 3: Membuat `lib/services/gemini_service.dart` (KODE LENGKAP)](#langkah-3-membuat-libservicesgemini_servicedart-kode-lengkap)
   - [Langkah 4: Modifikasi `lib/services/app_state.dart`](#langkah-4-modifikasi-libservicesapp_statedart)
3. [🎨 PANDUAN ARIEL — Frontend UI & Logo](#3-panduan-ariel--frontend-ui--logo)
   - [Langkah 1: Desain & Integration Logo (PFWM-1)](#langkah-1-desain--integration-logo-pfwm-1)
   - [Langkah 2: Membuat `lib/widgets/ai_insight_panel.dart` (KODE LENGKAP)](#langkah-2-membuat-libwidgetsai_insight_paneldart-kode-lengkap)
   - [Langkah 3: Integrasi ke `lib/screens/dashboard_screen.dart`](#langkah-3-integrasi-ke-libscreensdashboard_screendart)
   - [Langkah 4: Membuat `lib/widgets/ai_chat_panel.dart` (KODE LENGKAP)](#langkah-4-membuat-libwidgetsai_chat_paneldart-kode-lengkap)
4. [🧪 Testing & Integrasi Bersama](#4-testing--integrasi-bersama)

---

## 1. Struktur File & Modifikasi

```text
lib/
├── config/
│   └── api_keys.dart                  ← [NAINA] Baru (Jangan dipush ke Git!)
├── models/
│   └── weather_data.dart              (Sudah ada - tidak diubah)
├── services/
│   ├── app_state.dart                 ← [NAINA] Modifikasi (Integrasi GeminiState)
│   ├── app_theme.dart                 (Sudah ada - patokan warna UI Ariel)
│   ├── firebase_service.dart          (Sudah ada)
│   ├── gemini_service.dart            ← [NAINA] Baru (Komunikasi ke Gemini API)
│   └── location_weather_service.dart (Sudah ada)
├── widgets/
│   ├── ai_insight_panel.dart          ← [ARIEL] Baru (Panel Analisis AI + Badge Risk)
│   ├── ai_chat_panel.dart             ← [ARIEL] Baru (Dialog Chat AI ParaBot)
│   ├── analytics_panel.dart           (Sudah ada)
│   ├── hero_panel.dart                (Sudah ada)
│   └── sensor_card.dart               (Sudah ada)
└── screens/
    └── dashboard_screen.dart          ← [ARIEL] Modifikasi (Tampilkan AI Panel)
```

---

## 2. ⚙️ PANDUAN NAINA — Backend & Service AI

### Langkah 1: Setup API Key & Dependency

1. Buka [Google AI Studio](https://aistudio.google.com/apikey).
2. Login akun Google, klik **"Create API Key"**.
3. Copy API Key tersebut.
4. Buka terminal di folder root project, jalankan:
   ```bash
   flutter pub add google_generative_ai
   ```
5. Buka file `.gitignore` di root project, tambahkan baris berikut di bagian bawah:
   ```text
   # Gemini API Config
   lib/config/api_keys.dart
   ```

---

### Langkah 2: Membuat `lib/config/api_keys.dart`

Buat file baru di `lib/config/api_keys.dart`:

```dart
// ⚠️ JANGAN DI-PUSH KE GITHUB PUBLIC!
class ApiKeys {
  // Ganti string ini dengan API Key asli dari Google AI Studio
  static const String geminiApiKey = 'PASTE_GEMINI_API_KEY_KAMU_DISINI';
}
```

---

### Langkah 3: Membuat `lib/services/gemini_service.dart` (KODE LENGKAP)

Buat file baru `lib/services/gemini_service.dart` dan isi dengan kode berikut:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/weather_data.dart';

class GeminiService {
  late final GenerativeModel _model;
  DateTime? _lastCallTime;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.6,
        maxOutputTokens: 600,
      ),
    );
  }

  /// 🧠 Analisis Cuaca & Prediksi Risiko Banjir
  Future<Map<String, String>> analyzeWeather({
    required WeatherData current,
    required List<WeatherData> history,
    InternetWeather? internet,
  }) async {
    // Rate Limiting: Minimal 45 detik antar panggil untuk hemat kuota
    if (_lastCallTime != null &&
        DateTime.now().difference(_lastCallTime!) < const Duration(seconds: 45)) {
      final sisa = 45 - DateTime.now().difference(_lastCallTime!).inSeconds;
      return {
        'risk': 'UNKNOWN',
        'analysis': 'Harap tunggu $sisa detik sebelum memperbarui analisis AI kembali.'
      };
    }
    _lastCallTime = DateTime.now();

    final prompt = _buildAnalysisPrompt(current, history, internet);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final rawText = response.text ?? '';
      return _parseAiResponse(rawText);
    } catch (e) {
      debugPrint('Error Gemini API: $e');
      return {
        'risk': 'UNKNOWN',
        'analysis': 'Gagal menghubungkan ke Gemini AI: ${e.toString()}'
      };
    }
  }

  /// 💬 Chat dengan AI ParaBot
  Future<String> chat({
    required String userMessage,
    required WeatherData current,
    required List<WeatherData> history,
  }) async {
    final contextText = _buildShortContext(current, history);
    final prompt = '''
Kamu adalah "ParaBot", asisten pintar pemantau cuaca dan peringatan dini banjir Paramaflood.
Gunakan data sensor real-time berikut untuk menjawab pertanyaan user secara akurat dan ramah.

DATA SENSOR SAAT INI:
$contextText

PERTANYAAN USER: "$userMessage"

ATURAN JAWABAN:
1. Jawab singkat, padat (maksimal 120 kata), mudah dipahami warga.
2. Selalu sebutkan angka sensor aktual jika relevan.
3. Gunakan bahasa Indonesia santai tapi informatif dengan emoji yang sesuai.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Maaf, ParaBot tidak dapat merespon saat ini.';
    } catch (e) {
      return 'Error merespon: $e';
    }
  }

  // Helper Prompt Engineering Analisis
  String _buildAnalysisPrompt(
    WeatherData current,
    List<WeatherData> history,
    InternetWeather? internet,
  ) {
    // Hitung tren sederhana dari history
    double tempChange = 0;
    double distChange = 0;
    if (history.length >= 5) {
      tempChange = current.temp - history[history.length - 5].temp;
      distChange = current.distance - history[history.length - 5].distance;
    }

    return '''
Kamu adalah sistem AI Evaluator Banjir dan Cuaca untuk Paramaflood.

DATA SENSOR STASIUN LOKAL (ESP32):
- Suhu Air/Udara: ${current.temp.toStringAsFixed(1)}°C (${current.tempLabel})
- Kelembaban: ${current.hum.toStringAsFixed(0)}% (${current.humLabel})
- Kecepatan Angin: ${current.wind.toStringAsFixed(1)} m/s (${current.windLabel})
- Intensitas Cahaya: ${current.light.toStringAsFixed(0)} Lux (${current.lightLabel})
- Curah Hujan: ${current.rain.toStringAsFixed(1)} mm (${current.rainLabel})
- Jarak Ultrasonik ke Permukaan Air: ${current.distance.toStringAsFixed(1)} cm (${current.distanceLabel})
  *(Catatan: Semakin KECIL nilai jarak, permukaan air semakin NAIK/TINGGI!)*
- Tegangan Baterai: ${current.battery.toStringAsFixed(1)} V (${current.batteryLabel})
- Heat Index (Terasa Seperti): ${current.feelsLike.toStringAsFixed(1)}°C

TREN 5 PEMBACAAN TERAKHIR:
- Perubahan Suhu: ${tempChange >= 0 ? '+' : ''}${tempChange.toStringAsFixed(1)}°C
- Perubahan Jarak Air: ${distChange >= 0 ? '+' : ''}${distChange.toStringAsFixed(1)} cm (${distChange < 0 ? 'AIR MAKIN NAIK' : 'AIR SURUT/STABIL'})

DATA CUACA INTERNET (${internet?.location ?? 'Lokasi Terdeteksi'}):
- Suhu Internet: ${internet?.temp ?? '-'}°C | Kelembaban: ${internet?.hum ?? '-'}%
- Kondisi: ${internet?.conditionLabel ?? 'Tidak ada data'} | Tekanan Udara: ${internet?.pressure ?? '-'} hPa

TUGAS KAMU:
Berikan output DENGAN FORMAT PERSIS SEPERTI DI BAWAH INI (Jangan ubah format header [RISK_LEVEL]):

[RISK_LEVEL]: <Pilih salah satu: RENDAH | SEDANG | TINGGI | KRITIS>
[ANALYSIS]:
<Tuliskan 2-3 paragraf singkat berisi:
1. Ringkasan kondisi saat ini & analisis korelasinya dengan sensor.
2. Penjelasan tingkat risiko banjir berdasarkan tren air & hujan.
3. Rekomendasi tindakan konkret untuk warga/pengguna stasiun cuaca.>
''';
  }

  String _buildShortContext(WeatherData d, List<WeatherData> history) {
    return '''
Suhu: ${d.temp.toStringAsFixed(1)}°C | Kelembaban: ${d.hum.toStringAsFixed(0)}%
Angin: ${d.wind.toStringAsFixed(1)} m/s | Curah Hujan: ${d.rain.toStringAsFixed(1)} mm
Jarak Air: ${d.distance.toStringAsFixed(1)} cm (Status: ${d.distanceLabel})
Kondisi Cuaca: ${d.condition} | Air Quality: ${d.airQualityLabel}
''';
  }

  Map<String, String> _parseAiResponse(String raw) {
    String risk = 'RENDAH';
    String analysis = raw;

    if (raw.contains('[RISK_LEVEL]:')) {
      final parts = raw.split('[ANALYSIS]:');
      final riskLine = parts[0].replaceAll('[RISK_LEVEL]:', '').trim();

      if (riskLine.contains('KRITIS')) {
        risk = 'KRITIS';
      } else if (riskLine.contains('TINGGI')) {
        risk = 'TINGGI';
      } else if (riskLine.contains('SEDANG')) {
        risk = 'SEDANG';
      } else {
        risk = 'RENDAH';
      }

      if (parts.length > 1) {
        analysis = parts[1].trim();
      }
    }

    return {'risk': risk, 'analysis': analysis};
  }
}
```

---

### Langkah 4: Modifikasi `lib/services/app_state.dart`

Buka file `lib/services/app_state.dart`, tambahkan GeminiState berikut:

```dart
// TAMBAHKAN IMPORT INI DI ATAS
import '../services/gemini_service.dart';

class AppState extends ChangeNotifier {
  final _firebase = FirebaseService();
  final _locSvc   = LocationWeatherService();
  final _gemini   = GeminiService(); // ← [NAINA] Tambah instance ini

  // ── AI State Variables ──────────────────────────────────────────
  String _aiAnalysis = '';
  String _floodRiskLevel = 'RENDAH'; // RENDAH, SEDANG, TINGGI, KRITIS, UNKNOWN
  bool   _isAiLoading = false;
  String _aiError = '';
  final List<Map<String, String>> _chatMessages = [];

  // ── AI Getters ──────────────────────────────────────────────────
  String get aiAnalysis => _aiAnalysis;
  String get floodRiskLevel => _floodRiskLevel;
  bool   get isAiLoading => _isAiLoading;
  String get aiError => _aiError;
  List<Map<String, String>> get chatMessages => List.unmodifiable(_chatMessages);

  // ── AI Methods ──────────────────────────────────────────────────
  Future<void> refreshAiAnalysis() async {
    if (_isAiLoading) return;
    _isAiLoading = true;
    _aiError = '';
    notifyListeners();

    try {
      final res = await _gemini.analyzeWeather(
        current: _live,
        history: _history,
        internet: _internet,
      );
      _floodRiskLevel = res['risk'] ?? 'RENDAH';
      _aiAnalysis = res['analysis'] ?? 'Tidak ada analisis.';
    } catch (e) {
      _aiError = 'Gagal memproses AI: $e';
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Push pesan user
    _chatMessages.add({'sender': 'user', 'message': text});
    notifyListeners();

    // Dapatkan respon Gemini
    final reply = await _gemini.chat(
      userMessage: text,
      current: _live,
      history: _history,
    );

    _chatMessages.add({'sender': 'bot', 'message': reply});
    notifyListeners();
  }

  // Panggil refreshAiAnalysis() saat pertama kali live data diterima di init()
  // Tambahkan panggil `refreshAiAnalysis();` di dalam callback `_liveSub` jika belum pernah dipanggil.
}
```

---

## 3. 🎨 PANDUAN ARIEL — Frontend UI & Logo

### Langkah 1: Desain & Integration Logo (PFWM-1)

1. Buat desain logo di [Canva / Figma](https://www.canva.com/create/logos/).  
   - Format: PNG Transparan (rasio 1:1, misal 512x512 px).
   - Simpan dengan nama: `logo_paramaflood.png`.
2. Buat folder di root project (jika belum ada): `assets/images/`.
3. Masukkan `logo_paramaflood.png` ke folder `assets/images/`.
4. Buka `pubspec.yaml`, pastikan bagian assets sudah aktif:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```

---

### Langkah 2: Membuat `lib/widgets/ai_insight_panel.dart` (KODE LENGKAP)

Buat file baru di `lib/widgets/ai_insight_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

class AiInsightPanel extends StatelessWidget {
  const AiInsightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppTheme.cardSolid,
              AppTheme.cardSolid.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Risk Badge + Refresh Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.heroAcc.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🧠', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALISIS AI GEMINI',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 12,
                              color: AppTheme.heroAcc,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ringkasan Sistem & Prediksi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildRiskBadge(state.floodRiskLevel),
                IconButton(
                  onPressed: state.isAiLoading ? null : () => state.refreshAiAnalysis(),
                  icon: state.isAiLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, color: AppTheme.subtext),
                  tooltip: 'Perbarui Analisis AI',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Content Area
            if (state.isAiLoading && state.aiAnalysis.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('AI sedang menganalisis data sensor...'),
                    ],
                  ),
                ),
              )
            ] else if (state.aiAnalysis.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => state.refreshAiAnalysis(),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Jalankan Analisis AI Pertama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.heroAcc.withOpacity(0.2),
                      foregroundColor: AppTheme.text,
                    ),
                  ),
                ),
              )
            ] else ...[
              SelectableText(
                state.aiAnalysis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppTheme.text.withOpacity(0.9),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String level) {
    Color bg;
    Color fg = Colors.white;
    String label;
    IconData icon;

    switch (level.toUpperCase()) {
      case 'KRITIS':
        bg = const Color(0xFFEF4444);
        label = 'RISIKO KRITIS';
        icon = Icons.warning_amber_rounded;
        break;
      case 'TINGGI':
        bg = const Color(0xFFF97316);
        label = 'RISIKO TINGGI';
        icon = Icons.error_outline_rounded;
        break;
      case 'SEDANG':
        bg = const Color(0xFFF59E0B);
        label = 'RISIKO SEDANG';
        icon = Icons.info_outline_rounded;
        break;
      case 'RENDAH':
      default:
        bg = const Color(0xFF10B981);
        label = 'KONDISI AMAN';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bg, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Langkah 3: Integrasi ke `lib/screens/dashboard_screen.dart`

Buka file `lib/screens/dashboard_screen.dart`:
1. Import Widget AI Insight Panel:
   ```dart
   import '../widgets/ai_insight_panel.dart';
   import '../widgets/ai_chat_panel.dart'; // untuk floating action button chat
   ```
2. Tambahkan `AiInsightPanel()` di dalam daftar widget `SingleChildScrollView` atau `ListView` utama Dashboard (misal di bawah `HeroPanel` atau di atas `AnalyticsPanel`):

```dart
// Di dalam Column / ListView Dashboard Screen:
const HeroPanel(),
const SizedBox(height: 16),

// 🧠 TAMPILKAN PANEL AI DISINI
const AiInsightPanel(),

const SizedBox(height: 16),
// Widget sensor cards atau analytics panel...
```

3. (Opsional) Tambahkan Floating Action Button di Dashboard untuk membuka Chat ParaBot:
```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiChatPanel(),
    );
  },
  icon: const Icon(Icons.smart_toy_rounded),
  label: const Text('Tanya ParaBot'),
  backgroundColor: AppTheme.heroAcc,
),
```

---

### Langkah 4: Membuat `lib/widgets/ai_chat_panel.dart` (KODE LENGKAP)

Buat file baru di `lib/widgets/ai_chat_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<AppState>().sendChatMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.bgAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardSolid,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.heroAcc,
                  child: Text('🤖', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ParaBot AI Assistant',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Tanyakan kondisi cuaca & sensor real-time',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: state.chatMessages.length,
              itemBuilder: (ctx, idx) {
                final msg = state.chatMessages[idx];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.heroAcc : AppTheme.cardSolid,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.black : AppTheme.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.cardSolid,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tanyakan sesuatu (misal: "Aman keluar?")...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: AppTheme.bg,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.heroAcc),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. 🧪 Testing & Integrasi Bersama

1. **Jalankan App:**  
   Jalankan `flutter run` di VS Code / Android Studio.
2. **Koneksi Internet:**  
   Pastikan perangkat/emulator terhubung ke internet agar Gemini API dapat merespon.
3. **Uji Coba Panggil AI:**  
   - Buka Dashboard → Klik tombol **Refresh 🔄** di Panel Analisis AI.
   - Perhatikan badge risiko dan hasil teks dari Gemini AI.
4. **Uji Coba Chat:**  
   - Klik Floating Action Button **"Tanya ParaBot"** → Ketik pertanyaan *"Bagaimana kondisi air saat ini?"*.
   - Verifikasi bahwa ParaBot menjawab dengan angka aktual sensor dari `WeatherData`.

---
> 💡 *Dokumen ini sudah dirancang agar siap dipakai tanpa perlu bingung menyesuaikan nama variabel atau styling.*
