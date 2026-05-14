import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../widgets/alarm_card.dart';
import 'add_alarm_screen.dart';
import 'sleep_sounds_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<AlarmModel> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.loadAlarms();
    setState(() => _alarms = alarms);
  }

  Future<void> _toggleAlarm(AlarmModel alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await StorageService.saveAlarm(updated);
    if (updated.isEnabled) {
      await AlarmService.scheduleAlarm(updated);
    } else {
      await AlarmService.cancelAlarm(updated.id);
    }
    await _loadAlarms();
  }

  Future<void> _deleteAlarm(AlarmModel alarm) async {
    await AlarmService.cancelAlarm(alarm.id);
    await StorageService.deleteAlarm(alarm.id);
    await _loadAlarms();
  }

  Future<void> _addAlarm() async {
    final result = await Navigator.push<AlarmModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddAlarmScreen()),
    );
    if (result != null) await _loadAlarms();
  }

  Future<void> _editAlarm(AlarmModel alarm) async {
    final result = await Navigator.push<AlarmModel>(
      context,
      MaterialPageRoute(
          builder: (_) => AddAlarmScreen(existing: alarm)),
    );
    if (result != null) await _loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: IndexedStack(
        index: _tab,
        children: [
          _alarmsTab(),
          const SleepSoundsScreen(),
          const StatisticsScreen(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF7B8CDE),
              foregroundColor: Colors.white,
              onPressed: _addAlarm,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF1A2744),
        selectedItemColor: const Color(0xFF7B8CDE),
        unselectedItemColor: const Color(0xFF546E7A),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Будильники',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Звуки сна',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
        ],
      ),
    );
  }

  Widget _alarmsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Будильники',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _nextAlarmText(),
              style: const TextStyle(
                  color: Color(0xFF546E7A), fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _alarms.isEmpty
                  ? _noAlarmsPlaceholder()
                  : ListView.builder(
                      itemCount: _alarms.length,
                      itemBuilder: (_, i) {
                        final alarm = _alarms[i];
                        return AlarmCard(
                          alarm: alarm,
                          onToggle: () => _toggleAlarm(alarm),
                          onEdit: () => _editAlarm(alarm),
                          onDelete: () => _deleteAlarm(alarm),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextAlarmText() {
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return 'Нет активных будильников';
    final next = enabled
        .map((a) => a.nextAlarmTime())
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final diff = next.difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return 'Следующий через $h ч $m мин';
    return 'Следующий через $m мин';
  }

  Widget _noAlarmsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alarm_off,
              size: 64, color: Color(0xFF37474F)),
          const SizedBox(height: 16),
          const Text(
            'Нет будильников',
            style: TextStyle(color: Color(0xFF546E7A), fontSize: 18),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addAlarm,
            icon: const Icon(Icons.add,
                color: Color(0xFF7B8CDE)),
            label: const Text('Добавить будильник',
                style: TextStyle(color: Color(0xFF7B8CDE))),
          ),
        ],
      ),
    );
  }
}
