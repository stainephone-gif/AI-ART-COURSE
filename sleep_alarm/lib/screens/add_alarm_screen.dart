import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';

class AddAlarmScreen extends StatefulWidget {
  final AlarmModel? existing;

  const AddAlarmScreen({super.key, this.existing});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late int _hour;
  late int _minute;
  late TextEditingController _labelCtrl;
  late bool _smartAlarm;
  late int _smartWindow;
  late bool _gradual;
  late List<bool> _repeatDays;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _hour = a?.hour ?? TimeOfDay.now().hour;
    _minute = a?.minute ?? TimeOfDay.now().minute;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _smartAlarm = a?.isSmartAlarm ?? false;
    _smartWindow = a?.smartWindowMinutes ?? 30;
    _gradual = a?.gradualAlarm ?? false;
    _repeatDays = a?.repeatDays ?? List.filled(7, false);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7B8CDE),
            surface: Color(0xFF1A2744),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    final id = widget.existing?.id ?? StorageService.generateAlarmId();
    final alarm = AlarmModel(
      id: id,
      hour: _hour,
      minute: _minute,
      label: _labelCtrl.text.trim(),
      isEnabled: true,
      isSmartAlarm: _smartAlarm,
      smartWindowMinutes: _smartWindow,
      gradualAlarm: _gradual,
      repeatDays: List.from(_repeatDays),
    );
    await StorageService.saveAlarm(alarm);
    await AlarmService.scheduleAlarm(alarm);
    if (mounted) Navigator.of(context).pop(alarm);
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Text(widget.existing == null
            ? 'Новый будильник'
            : 'Изменить будильник'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Сохранить',
                style: TextStyle(color: Color(0xFF7B8CDE), fontSize: 16)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _pickTime,
            child: Center(
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Название'),
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'например: Работа',
              hintStyle: const TextStyle(color: Color(0xFF546E7A)),
              filled: true,
              fillColor: const Color(0xFF1A2744),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Повтор'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              return GestureDetector(
                onTap: () =>
                    setState(() => _repeatDays[i] = !_repeatDays[i]),
                child: CircleAvatar(
                  backgroundColor: _repeatDays[i]
                      ? const Color(0xFF7B8CDE)
                      : const Color(0xFF1A2744),
                  radius: 20,
                  child: Text(
                    days[i],
                    style: TextStyle(
                      color: _repeatDays[i]
                          ? Colors.white
                          : const Color(0xFF546E7A),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Улучшение сна'),
          _settingTile(
            icon: Icons.psychology_outlined,
            title: 'Умный будильник',
            subtitle: 'Разбудит в фазе лёгкого сна (±$_smartWindow мин)',
            trailing: Switch(
              value: _smartAlarm,
              onChanged: (v) => setState(() => _smartAlarm = v),
              activeThumbColor: const Color(0xFF7B8CDE),
            ),
          ),
          if (_smartAlarm) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text('Окно:',
                      style: TextStyle(color: Color(0xFF90A4AE))),
                  Expanded(
                    child: Slider(
                      value: _smartWindow.toDouble(),
                      min: 10,
                      max: 30,
                      divisions: 2,
                      label: '$_smartWindow мин',
                      activeColor: const Color(0xFF7B8CDE),
                      onChanged: (v) =>
                          setState(() => _smartWindow = v.toInt()),
                    ),
                  ),
                  Text('$_smartWindow мин',
                      style: const TextStyle(
                          color: Color(0xFF7B8CDE), fontSize: 13)),
                ],
              ),
            ),
          ],
          _settingTile(
            icon: Icons.volume_up_outlined,
            title: 'Плавный будильник',
            subtitle: 'Громкость нарастает 2 минуты',
            trailing: Switch(
              value: _gradual,
              onChanged: (v) => setState(() => _gradual = v),
              activeThumbColor: const Color(0xFF7B8CDE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: Color(0xFF546E7A),
            fontSize: 12,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B8CDE), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF90A4AE), fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
