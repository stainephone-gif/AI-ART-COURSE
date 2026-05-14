import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';
import '../services/storage_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<SleepRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await StorageService.loadSleepRecords();
    records.sort((a, b) => a.sleepTime.compareTo(b.sleepTime));
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  double get _avgQuality {
    if (_records.isEmpty) return 0;
    return _records.map((r) => r.quality).reduce((a, b) => a + b) /
        _records.length;
  }

  double get _avgDuration {
    if (_records.isEmpty) return 0;
    return _records.map((r) => r.durationHours).reduce((a, b) => a + b) /
        _records.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Статистика сна'),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF7B8CDE)))
          : _records.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _statsRow(),
                    const SizedBox(height: 24),
                    _durationChart(),
                    const SizedBox(height: 24),
                    _qualityChart(),
                    const SizedBox(height: 24),
                    _recentRecords(),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bedtime_outlined, size: 64, color: Color(0xFF37474F)),
          SizedBox(height: 16),
          Text(
            'Нет данных о сне',
            style: TextStyle(color: Color(0xFF546E7A), fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Включите звуки сна или будильник\nи оцените сон утром',
            style: TextStyle(color: Color(0xFF37474F), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
            child: _statCard('Ср. длит.',
                '${_avgDuration.toStringAsFixed(1)} ч', Icons.schedule)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                'Ср. качество',
                '${_avgQuality.toStringAsFixed(1)} / 5',
                Icons.star_outline)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                'Записей', '${_records.length}', Icons.history)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7B8CDE), size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF546E7A), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _durationChart() {
    final recent = _records.length > 7
        ? _records.sublist(_records.length - 7)
        : _records;
    final spots = recent.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.durationHours);
    }).toList();

    return _chartCard(
      title: 'Длительность сна (ч)',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 12,
          gridData: const FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      color: Color(0xFF546E7A), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < recent.length) {
                    return Text(
                      DateFormat('dd/MM')
                          .format(recent[idx].wakeTime),
                      style: const TextStyle(
                          color: Color(0xFF546E7A), fontSize: 9),
                    );
                  }
                  return const SizedBox();
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
              color: const Color(0xFF7B8CDE),
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF7B8CDE).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qualityChart() {
    final recent = _records.length > 7
        ? _records.sublist(_records.length - 7)
        : _records;
    final barGroups = recent.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.quality.toDouble(),
            color: _qualityColor(e.value.quality),
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return _chartCard(
      title: 'Качество сна (1-5)',
      child: BarChart(
        BarChartData(
          maxY: 5,
          minY: 0,
          gridData: const FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 20,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      color: Color(0xFF546E7A), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < recent.length) {
                    return Text(
                      DateFormat('dd/MM')
                          .format(recent[idx].wakeTime),
                      style: const TextStyle(
                          color: Color(0xFF546E7A), fontSize: 9),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Color _qualityColor(int q) {
    switch (q) {
      case 1:
        return const Color(0xFFEF5350);
      case 2:
        return const Color(0xFFFF7043);
      case 3:
        return const Color(0xFFFFCA28);
      case 4:
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF90A4AE), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }

  Widget _recentRecords() {
    final recent = _records.reversed.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ИСТОРИЯ',
          style: TextStyle(
              color: Color(0xFF546E7A),
              fontSize: 12,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        ...recent.map((r) => _recordTile(r)),
      ],
    );
  }

  Widget _recordTile(SleepRecord r) {
    const emojis = ['', '😩', '😔', '😐', '😊', '😄'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emojis[r.quality],
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'ru').format(r.wakeTime),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${DateFormat('HH:mm').format(r.sleepTime)} → '
                  '${DateFormat('HH:mm').format(r.wakeTime)} '
                  '(${r.durationHours.toStringAsFixed(1)} ч)',
                  style: const TextStyle(
                      color: Color(0xFF546E7A), fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(
                5,
                (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < r.quality
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF37474F),
                    )),
          ),
        ],
      ),
    );
  }
}
