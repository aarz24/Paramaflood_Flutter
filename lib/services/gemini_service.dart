import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/weather_data.dart';

/// Service utama komunikasi ke Google Gemini API.
///
/// Fitur:
///  1. 🧠 Analisis Cuaca AI          → [analyzeWeather] (digabung dgn fitur 2)
///  2. 🌊 Prediksi Risiko Banjir AI  → [analyzeWeather] (satu prompt, hemat kuota)
///  3. 💬 Chat AI "ParaBot"          → [chat]
///  4. 📊 Laporan Harian AI          → [generateDailyReport]
///  5. ⚡ Notifikasi Cerdas AI       → [generateSmartAlert]
class GeminiService {
  late final GenerativeModel _model;
  DateTime? _lastAnalysisCall;

  /// Minimal jeda antar panggilan analisis — hemat kuota free tier.
  static const _analysisCooldown = Duration(seconds: 45);

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.6,
        // JANGAN set maxOutputTokens: gemini-2.5-flash memakai "thinking
        // tokens" dari budget yang sama sehingga teks jawaban terpotong
        // (MAX_TOKENS). Panjang jawaban sudah dibatasi lewat prompt
        // (maks 40-200 kata per fitur).
      ),
    );
  }

  bool get isConfigured =>
      ApiKeys.geminiApiKey.isNotEmpty &&
      !ApiKeys.geminiApiKey.startsWith('PASTE_');

  /// Sisa detik cooldown sebelum boleh analisis lagi (0 = siap).
  int get cooldownRemaining {
    if (_lastAnalysisCall == null) return 0;
    final elapsed = DateTime.now().difference(_lastAnalysisCall!);
    final left = _analysisCooldown.inSeconds - elapsed.inSeconds;
    return left > 0 ? left : 0;
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 1 & 2: Analisis Cuaca + Prediksi Risiko Banjir
  //  (Digabung jadi satu panggilan API biar hemat kuota)
  // ══════════════════════════════════════════════════════════
  Future<Map<String, String>> analyzeWeather({
    required WeatherData current,
    required List<WeatherData> history,
    InternetWeather? internet,
  }) async {
    if (!isConfigured) {
      return {
        'risk': 'UNKNOWN',
        'analysis':
            'API key Gemini belum diisi. Buka lib/config/api_keys.dart dan '
                'tempel API key dari https://aistudio.google.com/apikey.',
      };
    }

    // Rate limiting: hemat kuota free tier
    final sisa = cooldownRemaining;
    if (sisa > 0) {
      return {
        'risk': 'COOLDOWN',
        'analysis':
            'Harap tunggu $sisa detik sebelum memperbarui analisis AI kembali.',
      };
    }
    _lastAnalysisCall = DateTime.now();

    final prompt = _buildAnalysisPrompt(current, history, internet);

    try {
      final response = await _generateWithRetry(prompt);
      final rawText = response.text ?? '';
      return _parseAiResponse(rawText);
    } catch (e) {
      debugPrint('Error Gemini API: $e');
      return {
        'risk': 'UNKNOWN',
        'analysis': 'Gagal menghubungkan ke Gemini AI: ${e.toString()}',
      };
    }
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 3: Chat dengan AI ParaBot
  // ══════════════════════════════════════════════════════════
  Future<String> chat({
    required String userMessage,
    required WeatherData current,
    required List<WeatherData> history,
    InternetWeather? internet,
  }) async {
    if (!isConfigured) {
      return 'ParaBot belum aktif — API key Gemini belum diisi di '
          'lib/config/api_keys.dart.';
    }

    final contextText = _buildShortContext(current, history, internet);
    final prompt = '''
Kamu adalah "ParaBot", asisten pintar pemantau cuaca dan peringatan dini banjir Paramaflood.
Gunakan data sensor real-time berikut untuk menjawab pertanyaan user secara akurat dan ramah.

DATA SENSOR SAAT INI:
$contextText

PERTANYAAN USER: "$userMessage"

ATURAN JAWABAN:
1. Jawab dalam bahasa yang sama dengan pertanyaan user (default Bahasa Indonesia).
2. Jawab singkat, padat (maksimal 120 kata), mudah dipahami warga.
3. Selalu sebutkan angka sensor aktual jika relevan.
4. Untuk pertanyaan keselamatan banjir, selalu utamakan kehati-hatian.
5. Jika ditanya hal di luar cuaca/banjir/sensor, arahkan kembali dengan sopan.
6. Gunakan emoji yang sesuai agar mudah dibaca.
7. Tulis dalam teks biasa — JANGAN gunakan format markdown (tanpa ** atau #).
''';

    try {
      final response = await _generateWithRetry(prompt);
      return _clean(response.text ?? 'Maaf, ParaBot tidak dapat merespon saat ini.');
    } catch (e) {
      debugPrint('Error Gemini chat: $e');
      return 'Error merespon: $e';
    }
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 4: Laporan Harian AI
  // ══════════════════════════════════════════════════════════
  Future<String> generateDailyReport({
    required List<WeatherData> todayHistory,
  }) async {
    if (!isConfigured) {
      return 'API key Gemini belum diisi di lib/config/api_keys.dart.';
    }
    if (todayHistory.isEmpty) {
      return 'Belum ada data sensor hari ini untuk dilaporkan.';
    }

    final stats = _buildHistoryStats(todayHistory);
    final prompt = '''
Kamu adalah sistem pelaporan AI untuk stasiun cuaca & banjir Paramaflood.

STATISTIK DATA SENSOR HARI INI (${todayHistory.length} pembacaan):
$stats

TUGAS KAMU:
Buat "Laporan Harian Paramaflood" singkat (maksimal 200 kata) dalam Bahasa Indonesia yang mencakup:
1. Ringkasan suhu (min/max/rata-rata) dan kelembaban.
2. Curah hujan total dan kategorinya.
3. Kondisi ketinggian air (stabil/naik/turun, aman/tidak).
4. Kesehatan baterai stasiun.
5. Catatan anomali atau kejadian penting (jika ada).
6. Kesimpulan satu kalimat: ada/tidaknya kejadian banjir hari ini.

Gunakan emoji untuk kejelasan visual. Gunakan angka spesifik dari data.
Tulis dalam teks biasa — JANGAN gunakan format markdown (tanpa ** atau #).
''';

    try {
      final response = await _generateWithRetry(prompt);
      return _clean(response.text ?? 'AI tidak dapat membuat laporan saat ini.');
    } catch (e) {
      debugPrint('Error Gemini daily report: $e');
      return 'Gagal membuat laporan harian: $e';
    }
  }

  // ══════════════════════════════════════════════════════════
  //  FITUR 5: Notifikasi Cerdas AI
  // ══════════════════════════════════════════════════════════
  Future<String> generateSmartAlert({
    required WeatherData current,
    required String alertType, // 'flood', 'heat', 'battery', 'storm'
  }) async {
    if (!isConfigured) {
      // Fallback ke pesan statis kalau AI belum siap
      return _fallbackAlert(current, alertType);
    }

    final prompt = '''
Kamu adalah sistem notifikasi darurat AI untuk Paramaflood.

DATA SENSOR SAAT INI:
${_buildShortContext(current, const [], null)}

JENIS PERINGATAN: $alertType

TUGAS KAMU:
Tulis SATU notifikasi peringatan singkat (maksimal 40 kata) dalam Bahasa Indonesia yang:
1. Menyebutkan angka sensor aktual yang relevan.
2. Menjelaskan bahayanya secara singkat.
3. Memberi satu saran tindakan konkret.
4. Diawali emoji yang sesuai (⚠️/🌡️/🔋/⛈️).
Jawab HANYA teks notifikasinya, tanpa penjelasan tambahan.
''';

    try {
      final response = await _generateWithRetry(prompt);
      return response.text?.trim() ?? _fallbackAlert(current, alertType);
    } catch (e) {
      debugPrint('Error Gemini smart alert: $e');
      return _fallbackAlert(current, alertType);
    }
  }

  String _fallbackAlert(WeatherData d, String alertType) {
    switch (alertType) {
      case 'flood':
        return '⚠️ Ketinggian air kritis: ${d.distance.toStringAsFixed(0)} cm. Waspada banjir!';
      case 'heat':
        return '🌡️ Suhu tinggi ${d.temp.toStringAsFixed(1)}°C. Hindari aktivitas luar ruangan.';
      case 'battery':
        return '🔋 Baterai lemah ${d.battery.toStringAsFixed(1)}V. Segera isi ulang.';
      default:
        return '⚠️ Kondisi cuaca perlu diwaspadai. Periksa dashboard Paramaflood.';
    }
  }

  // ── Helper: Prompt Engineering Analisis ─────────────────────────
  String _buildAnalysisPrompt(
    WeatherData current,
    List<WeatherData> history,
    InternetWeather? internet,
  ) {
    // Hitung tren sederhana dari history
    double tempChange = 0;
    double distChange = 0;
    double rainTotal = current.rain;
    if (history.length >= 5) {
      tempChange = current.temp - history[history.length - 5].temp;
      distChange = current.distance - history[history.length - 5].distance;
      rainTotal = history
          .sublist(history.length - 5)
          .fold(0.0, (sum, d) => sum + d.rain);
    }

    return '''
Kamu adalah sistem AI Evaluator Banjir dan Cuaca untuk Paramaflood, sistem peringatan dini banjir IoT di Indonesia.

DATA SENSOR STASIUN LOKAL (ESP32):
- Suhu Udara: ${current.temp.toStringAsFixed(1)}°C (${current.tempLabel})
- Kelembaban: ${current.hum.toStringAsFixed(0)}% (${current.humLabel})
- Tekanan Udara: ${current.pres.toStringAsFixed(1)} hPa (${current.presLabel})
- Kecepatan Angin: ${current.wind.toStringAsFixed(1)} m/s (${current.windLabel})
- Intensitas Cahaya: ${current.light.toStringAsFixed(0)} Lux (${current.lightLabel})
- Curah Hujan: ${current.rain.toStringAsFixed(1)} mm (${current.rainLabel})
- Jarak Ultrasonik ke Permukaan Air: ${current.distance.toStringAsFixed(1)} cm (${current.distanceLabel})
  *(Catatan: Semakin KECIL nilai jarak, permukaan air semakin NAIK/TINGGI!)*
- Tegangan Baterai: ${current.battery.toStringAsFixed(1)} V (${current.batteryLabel})
- Heat Index (Terasa Seperti): ${current.feelsLike.toStringAsFixed(1)}°C

TREN 5 PEMBACAAN TERAKHIR (dari ${history.length} riwayat):
- Perubahan Suhu: ${tempChange >= 0 ? '+' : ''}${tempChange.toStringAsFixed(1)}°C
- Perubahan Jarak Air: ${distChange >= 0 ? '+' : ''}${distChange.toStringAsFixed(1)} cm (${distChange < 0 ? 'AIR MAKIN NAIK' : 'AIR SURUT/STABIL'})
- Akumulasi Hujan Terakhir: ${rainTotal.toStringAsFixed(1)} mm

DATA CUACA INTERNET (${internet?.location ?? 'Tidak tersedia'}):
- Suhu Internet: ${internet?.temp.toStringAsFixed(1) ?? '-'}°C | Kelembaban: ${internet?.hum.toStringAsFixed(0) ?? '-'}%
- Angin: ${internet?.windSpeed.toStringAsFixed(1) ?? '-'} m/s | Tekanan Udara: ${internet?.pressure.toStringAsFixed(0) ?? '-'} hPa
- Kondisi: ${internet?.conditionLabel ?? 'Tidak ada data'}

TUGAS KAMU:
WAJIB balas HANYA dengan format persis di bawah ini. Baris PERTAMA HARUS diawali "[RISK_LEVEL]:". DILARANG memakai format markdown (jangan gunakan ** atau #).

[RISK_LEVEL]: <Pilih SATU: RENDAH | SEDANG | TINGGI | KRITIS>
[ANALYSIS]:
<Tuliskan 2-3 paragraf singkat (maksimal 200 kata) dalam Bahasa Indonesia berisi:
1. Ringkasan kondisi saat ini & analisis korelasi antar sensor (bandingkan juga dengan data internet).
2. Penjelasan tingkat risiko banjir berdasarkan tren air & hujan.
3. Rekomendasi tindakan konkret untuk warga/pengguna stasiun cuaca.
Gunakan angka spesifik dari data. Jangan jawab generik. Gunakan emoji untuk kejelasan visual.>
''';
  }

  // ── Helper: Konteks singkat untuk chat & alert ──────────────────
  String _buildShortContext(
    WeatherData d,
    List<WeatherData> history,
    InternetWeather? internet,
  ) {
    final buf = StringBuffer('''
Suhu: ${d.temp.toStringAsFixed(1)}°C (${d.tempLabel}) | Kelembaban: ${d.hum.toStringAsFixed(0)}% (${d.humLabel})
Heat Index: ${d.feelsLike.toStringAsFixed(1)}°C | Angin: ${d.wind.toStringAsFixed(1)} m/s (${d.windLabel})
Curah Hujan: ${d.rain.toStringAsFixed(1)} mm (${d.rainLabel}) | Cahaya: ${d.light.toStringAsFixed(0)} lux (${d.lightLabel})
Jarak ke Air: ${d.distance.toStringAsFixed(1)} cm (Status: ${d.distanceLabel})
Baterai: ${d.battery.toStringAsFixed(1)} V (${d.batteryLabel})
Kondisi Cuaca: ${d.condition} | Kualitas Udara: ${d.airQualityLabel}
''');
    if (history.isNotEmpty) {
      buf.writeln('Jumlah data riwayat: ${history.length} pembacaan');
    }
    if (internet != null) {
      buf.writeln(
          'Cuaca Internet (${internet.location}): ${internet.temp.toStringAsFixed(1)}°C, '
          '${internet.conditionLabel}, tekanan ${internet.pressure.toStringAsFixed(0)} hPa');
    }
    return buf.toString();
  }

  // ── Helper: Statistik ringkas untuk laporan harian ──────────────
  String _buildHistoryStats(List<WeatherData> hist) {
    double tMin = hist.first.temp, tMax = hist.first.temp, tSum = 0;
    double hMin = hist.first.hum, hMax = hist.first.hum, hSum = 0;
    double dMin = hist.first.distance, dMax = hist.first.distance;
    double rainTotal = 0;
    double battLast = hist.last.battery;

    for (final d in hist) {
      if (d.temp < tMin) tMin = d.temp;
      if (d.temp > tMax) tMax = d.temp;
      tSum += d.temp;
      if (d.hum < hMin) hMin = d.hum;
      if (d.hum > hMax) hMax = d.hum;
      hSum += d.hum;
      if (d.distance < dMin) dMin = d.distance;
      if (d.distance > dMax) dMax = d.distance;
      rainTotal += d.rain;
    }

    return '''
- Suhu: Min ${tMin.toStringAsFixed(1)}°C, Max ${tMax.toStringAsFixed(1)}°C, Rata-rata ${(tSum / hist.length).toStringAsFixed(1)}°C
- Kelembaban: Rentang ${hMin.toStringAsFixed(0)}-${hMax.toStringAsFixed(0)}%, rata-rata ${(hSum / hist.length).toStringAsFixed(0)}%
- Curah hujan total: ${rainTotal.toStringAsFixed(1)} mm
- Jarak ke air: Rentang ${dMin.toStringAsFixed(0)}-${dMax.toStringAsFixed(0)} cm (terkecil = air tertinggi)
- Baterai terakhir: ${battLast.toStringAsFixed(1)} V
- Data terakhir: ${hist.last.distanceLabel} (level air), ${hist.last.rainLabel} (hujan)
''';
  }

  // ── Helper: Panggil Gemini + 1x retry untuk error transient ─────
  Future<GenerateContentResponse> _generateWithRetry(String prompt) async {
    try {
      return await _model.generateContent([Content.text(prompt)]);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final transient = msg.contains('503') ||
          msg.contains('unavailable') ||
          msg.contains('overloaded') ||
          msg.contains('high demand');
      if (!transient) rethrow;
      // Gemini sedang overload — coba sekali lagi setelah jeda singkat.
      await Future.delayed(const Duration(seconds: 2));
      return await _model.generateContent([Content.text(prompt)]);
    }
  }

  // ── Helper: Parse output AI [RISK_LEVEL] + [ANALYSIS] ───────────
  Map<String, String> _parseAiResponse(String raw) {
    String risk;
    String analysis = raw;

    if (raw.contains('[RISK_LEVEL]:')) {
      final parts = raw.split('[ANALYSIS]:');
      final riskLine = parts[0].replaceAll('[RISK_LEVEL]:', '').trim();
      risk = _riskFromText(riskLine.toUpperCase());
      if (parts.length > 1) {
        analysis = parts[1].trim();
      }
    } else {
      // Fallback: model tidak mengikuti format header —
      // simpulkan level risiko dari isi teks agar badge tidak salah.
      risk = _riskFromText(raw.toUpperCase());
    }

    return {'risk': risk, 'analysis': _clean(analysis)};
  }

  // ── Helper: Simpulkan level risiko dari teks bebas ──────────────
  String _riskFromText(String upper) {
    // Kata kunci level eksplisit didahulukan (urutan = prioritas).
    if (upper.contains('KRITIS')) return 'KRITIS';
    if (upper.contains('TINGGI')) return 'TINGGI';
    if (upper.contains('SEDANG')) return 'SEDANG';
    if (upper.contains('RENDAH')) return 'RENDAH';
    // Tidak ada level eksplisit → infer dari kata bahaya.
    const bahayaTinggi = [
      'EVAKUASI', 'SEGERA MENGUNGSI', 'PERINGATAN BADAI',
      'PERINGATAN BANJIR', 'BANJIR!', 'BAHAYA'
    ];
    for (final w in bahayaTinggi) {
      if (upper.contains(w)) return 'TINGGI';
    }
    if (upper.contains('WASPADA') ||
        upper.contains('BADAI') ||
        upper.contains('BANJIR')) {
      return 'SEDANG';
    }
    return 'RENDAH';
  }

  // ── Helper: Bersihkan markdown agar tampil rapi di UI ───────────
  String _clean(String s) {
    return s
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '• ')
        .trim();
  }
}
