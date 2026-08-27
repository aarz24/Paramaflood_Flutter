import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_data.dart';
import '../services/app_theme.dart';

// ════════════════════════════════════════════════════════════════
//  ComparisonPanel — Sensor vs Internet bars
// ════════════════════════════════════════════════════════════════
class ComparisonPanel extends StatelessWidget {
  final WeatherData sensor;
  final InternetWeather? internet;

  const ComparisonPanel({super.key, required this.sensor, this.internet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.heroAcc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('SENSOR vs INTERNET',
                  style: GoogleFonts.outfit(
                      color: AppTheme.heroAcc, fontSize: 10, letterSpacing: 2)),
            ),
            const Spacer(),
            if (internet != null)
              Text('Open-Meteo · ${_ago(internet!.fetchedAt)}',
                  style: GoogleFonts.outfit(
                      color: AppTheme.subtext, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 14),
        if (internet == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Waiting for internet weather...',
                  style: GoogleFonts.outfit(
                      color: AppTheme.subtext, fontSize: 10)),
            ),
          )
        else ...[
          _compareRow('TEMP', sensor.temp,
              '${sensor.temp.toStringAsFixed(1)}°C',
              internet!.temp,
              '${internet!.temp.toStringAsFixed(1)}°C',
              AppTheme.colTemp, -10, 50),
          const SizedBox(height: 8),
          _compareRow('HUMIDITY', sensor.hum,
              '${sensor.hum.toStringAsFixed(0)}%',
              internet!.hum,
              '${internet!.hum.toStringAsFixed(0)}%',
              AppTheme.colHum, 0, 100),
          const SizedBox(height: 8),
          _compareRow('WIND', sensor.wind,
              '${sensor.wind.toStringAsFixed(1)} m/s',
              internet!.windSpeed,
              '${internet!.windSpeed.toStringAsFixed(1)} m/s',
              AppTheme.colWind, 0, 20),
          const SizedBox(height: 12),
          _analysisSummary(),
        ],
      ]),
    );
  }

  Widget _compareRow(
    String label,
    double sVal, String sStr,
    double iVal, String iStr,
    Color color,
    double min, double max,
  ) {
    final sPct = ((sVal - min) / (max - min)).clamp(0.0, 1.0);
    final iPct = ((iVal - min) / (max - min)).clamp(0.0, 1.0);
    final diff = sVal - iVal;
    final diffStr = diff >= 0
        ? '+${diff.toStringAsFixed(1)}'
        : diff.toStringAsFixed(1);
    final diffColor = diff.abs() > 3 ? AppTheme.offline : AppTheme.online;

    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(label,
            style: GoogleFonts.outfit(
                color: color.withValues(alpha: 0.8),
                fontSize: 8, letterSpacing: 1)),
      ),
      Expanded(
        child: Column(children: [
          _bar(sPct, color, sStr, AppTheme.heroAcc),
          const SizedBox(height: 3),
          _bar(iPct, AppTheme.internet, iStr, AppTheme.internet),
        ]),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: diffColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: diffColor.withValues(alpha: 0.5)),
        ),
        child: Text(diffStr,
            style: GoogleFonts.outfit(
                color: diffColor, fontSize: 8)),
      ),
    ]);
  }

  Widget _bar(double pct, Color barColor, String label, Color dotColor) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: dotColor, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Expanded(
        child: Stack(children: [
          Container(
              height: 6,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
                height: 6,
                decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3))),
          ),
        ]),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 55,
        child: Text(label,
            style:
                GoogleFonts.outfit(color: barColor, fontSize: 9),
            textAlign: TextAlign.right),
      ),
    ]);
  }

  Widget _analysisSummary() {
    if (internet == null) return const SizedBox();
    final issues = <String>[];
    if ((sensor.temp - internet!.temp).abs() > 5) {
      issues.add(
          'Temp Δ${(sensor.temp - internet!.temp).abs().toStringAsFixed(1)}°C — check sensor placement');
    }
    if ((sensor.hum - internet!.hum).abs() > 20) {
      issues.add(
          'Humidity Δ${(sensor.hum - internet!.hum).abs().toStringAsFixed(0)}% — indoor vs outdoor?');
    }
    if (sensor.distance > 0 && sensor.distance < 20) {
      issues.add('Air kanal tinggi — risiko banjir meningkat');
    }
    if (sensor.temp > 35 && sensor.hum > 70) {
      issues.add('Heat stress risk — high heat index');
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.heroAcc.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.analytics, color: AppTheme.heroAcc, size: 12),
          const SizedBox(width: 4),
          Text('ANALYSIS',
              style: GoogleFonts.outfit(
                  color: AppTheme.heroAcc,
                  fontSize: 9, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        if (issues.isEmpty)
          Text('✅ All readings consistent with internet data',
              style: GoogleFonts.outfit(
                  color: AppTheme.online, fontSize: 9))
        else
          ...issues.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 9)),
                  Expanded(
                      child: Text(i,
                          style: GoogleFonts.outfit(
                              color: AppTheme.offline, fontSize: 9))),
                ]),
              )),
        const SizedBox(height: 6),
        Row(children: [
          Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppTheme.heroAcc, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('Sensor  ',
              style: GoogleFonts.outfit(
                  color: AppTheme.heroAcc, fontSize: 8)),
          Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppTheme.internet, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('Internet',
              style: GoogleFonts.outfit(
                  color: AppTheme.internet, fontSize: 8)),
        ]),
      ]),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ════════════════════════════════════════════════════════════════
//  HistoryChart — 4 sensor tabs in creative glowing boxes
// ════════════════════════════════════════════════════════════════
class HistoryChart extends StatefulWidget {
  final List<WeatherData> history;
  const HistoryChart({super.key, required this.history});

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

  // (label, color, unit, icon)
  static const _cfg = [
    ('KETINGGIAN AIR', AppTheme.colDist,  'cm',  Icons.waves_rounded),
    ('HUJAN',          AppTheme.colRain,  'mm',  Icons.grain_rounded),
    ('SUHU',           AppTheme.colTemp,  '°C',  Icons.thermostat_rounded),
    ('KELEMBABAN',     AppTheme.colHum,   '%',   Icons.water_drop_rounded),
    ('ANGIN',          AppTheme.colWind,  'm/s', Icons.air_rounded),
    ('CAHAYA',         AppTheme.colLight, 'lx',  Icons.wb_sunny_rounded),
    ('BATERAI',        AppTheme.colBatt,  'V',   Icons.battery_charging_full_rounded),
  ];

  List<double> get _vals {
    return switch (_tab) {
      0 => widget.history.map((e) => e.distance).toList(),
      1 => widget.history.map((e) => e.rain).toList(),
      2 => widget.history.map((e) => e.temp).toList(),
      3 => widget.history.map((e) => e.hum).toList(),
      4 => widget.history.map((e) => e.wind).toList(),
      5 => widget.history.map((e) => e.light).toList(),
      6 => widget.history.map((e) => e.battery).toList(),
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _cfg[_tab].$2;
    final unit  = _cfg[_tab].$3;
    final vals  = _vals;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Section header ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            Text('HISTORY',
                style: GoogleFonts.outfit(
                    color: AppTheme.heroAcc,
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('LAST ${vals.length} READINGS',
                style: GoogleFonts.outfit(
                    color: AppTheme.subtext, fontSize: 9)),
          ]),
        ),

        const SizedBox(height: 10),

        // ── Sensor tab boxes in a 2-column grid ──────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemCount: _cfg.length,
            itemBuilder: (ctx, i) {
              final isActive = _tab == i;
              final cfg = _cfg[i];
              final tabColor = cfg.$2;
              // Compute current value for this tab
              double? cur;
              if (widget.history.isNotEmpty) {
                cur = switch (i) {
                  0 => widget.history.last.distance,
                  1 => widget.history.last.rain,
                  2 => widget.history.last.temp,
                  3 => widget.history.last.hum,
                  4 => widget.history.last.wind,
                  5 => widget.history.last.light,
                  6 => widget.history.last.battery,
                  _ => null,
                };
              }

              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isActive
                        ? tabColor.withValues(alpha: 0.10)
                        : AppTheme.bgAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? tabColor
                          : AppTheme.cardBorder,
                      width: isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: tabColor.withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(children: [
                      // Sensor icon
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: tabColor.withValues(alpha: isActive ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          cfg.$4,
                          size: isActive ? 16 : 14,
                          color: isActive ? tabColor : tabColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cfg.$1,
                                style: GoogleFonts.outfit(
                                    color: isActive
                                        ? tabColor
                                        : tabColor.withValues(alpha: 0.5),
                                    fontSize: 9,
                                    letterSpacing: 1.2,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                            if (cur != null)
                              Text(
                                '${cur.toStringAsFixed(1)} ${cfg.$3}',
                                style: GoogleFonts.outfit(
                                    color: isActive
                                        ? tabColor
                                        : tabColor.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      // Active indicator bar
                      if (isActive)
                        Container(
                          width: 3,
                          height: 28,
                          decoration: BoxDecoration(
                              color: tabColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                    color: tabColor.withValues(alpha: 0.3),
                                    blurRadius: 6)
                              ]),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ── Line chart ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: vals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No history data yet',
                        style: GoogleFonts.outfit(
                            color: AppTheme.subtext, fontSize: 10)),
                  ),
                )
              : _buildChart(vals, color, unit),
        ),
      ]),
    );
  }

  Widget _buildChart(List<double> vals, Color color, String unit) {
    final spots = vals.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minY = vals.reduce((a, b) => a < b ? a : b) * 0.97;
    final maxY = vals.reduce((a, b) => a > b ? a : b) * 1.03;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppTheme.divider,
                strokeWidth: 1,
                dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
                  style: GoogleFonts.outfit(
                      color: color.withValues(alpha: 0.6), fontSize: 8),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (vals.length / 5).ceilToDouble().clamp(1, 99),
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= widget.history.length) {
                    return const SizedBox();
                  }
                  final t = widget.history[i].timestamp;
                  final h = t.hour > 12
                      ? t.hour - 12
                      : (t.hour == 0 ? 12 : t.hour);
                  final ap = t.hour >= 12 ? 'P' : 'A';
                  return Text(
                    '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}$ap',
                    style: GoogleFonts.outfit(
                        color: AppTheme.subtext, fontSize: 7),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 2.5,
                  color: color,
                  strokeColor: AppTheme.cardSolid,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.25), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.cardSolid,
              tooltipBorder: BorderSide(color: color),
              getTooltipItems: (s) => s
                  .map((sp) => LineTooltipItem(
                        '${sp.y.toStringAsFixed(1)} $unit',
                        GoogleFonts.outfit(color: color, fontSize: 9),
                      ))
                  .toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WeatherAnalyticsPanel
// ════════════════════════════════════════════════════════════════
class WeatherAnalyticsPanel extends StatelessWidget {
  final WeatherData sensor;
  final InternetWeather? internet;
  final List<WeatherData> history;

  const WeatherAnalyticsPanel({
    super.key,
    required this.sensor,
    required this.history,
    this.internet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text('WEATHER ANALYTICS',
              style: GoogleFonts.outfit(
                  color: AppTheme.heroAcc,
                  fontSize: 10,
                  letterSpacing: 2.5)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _card('HEAT INDEX',
                '${sensor.feelsLike.toStringAsFixed(1)}°C',
                'Suhu terasa', AppTheme.colTemp),
            _card('KEKUATAN ANGIN', _beaufort(sensor.wind),
                '${sensor.wind.toStringAsFixed(1)} m/s  (${(sensor.wind * 3.6).toStringAsFixed(1)} km/h)',
                AppTheme.colWind),
            _card('KONDISI CUACA', sensor.condition,
                internet != null
                    ? 'Internet: ${internet!.conditionLabel}'
                    : 'Sensor: ${sensor.distanceLabel}',
                AppTheme.colRain),
            _card('KUALITAS UDARA', sensor.airQualityLabel,
                'Kelembaban ${sensor.hum.toStringAsFixed(0)}%  Suhu ${sensor.temp.toStringAsFixed(1)}°C',
                _aqColor(sensor.airQualityLabel)),
            if (history.length >= 3) ...[
              _card('TREN SUHU',
                  _trend(history.map((e) => e.temp).toList()),
                  '${history.length} pembacaan terakhir', AppTheme.colTemp),
              _card('TREN HUJAN',
                  _trend(history.map((e) => e.rain).toList()),
                  '${history.last.rain.toStringAsFixed(1)} mm', AppTheme.colRain),
              _card('TREN AIR',
                  _trend(history.map((e) => 400.0 - e.distance).toList()),
                  history.last.distanceLabel, AppTheme.colDist),
              _card('TREN BATERAI',
                  _trend(history.map((e) => e.battery).toList()),
                  history.last.batteryLabel, AppTheme.colBatt),
            ],
          ],
        ),
      ]),
    );
  }

  Widget _card(String title, String value, String sub, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardSolid,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: GoogleFonts.outfit(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 7, letterSpacing: 1)),
            Text(value,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text(sub,
                style: GoogleFonts.outfit(
                    color: AppTheme.subtext, fontSize: 8),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  String _beaufort(double mps) {
    if (mps < 0.5) return 'BFT 0';
    if (mps < 1.5) return 'BFT 1';
    if (mps < 3.4) return 'BFT 2';
    if (mps < 5.5) return 'BFT 3';
    if (mps < 8.0) return 'BFT 4';
    if (mps < 10.8) return 'BFT 5';
    if (mps < 13.9) return 'BFT 6';
    return 'BFT 7+';
  }

  String _trend(List<double> vals) {
    if (vals.length < 3) return '—';
    final delta = vals.last - vals[vals.length - 3];
    if (delta > 1.0) return 'RISING ↑';
    if (delta < -1.0) return 'FALLING ↓';
    return 'STABLE →';
  }

  Color _aqColor(String label) {
    if (label == 'GOOD') return AppTheme.online;
    if (label == 'MODERATE') return AppTheme.heroAcc;
    return AppTheme.offline;
  }
}
