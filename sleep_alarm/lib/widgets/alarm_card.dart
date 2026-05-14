import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final hasRepeat = alarm.repeatDays.any((d) => d);

    return Card(
      color: const Color(0xFF1A2744),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.timeString,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w200,
                            color: alarm.isEnabled
                                ? Colors.white
                                : const Color(0xFF546E7A),
                            letterSpacing: 2,
                          ),
                        ),
                        if (alarm.label.isNotEmpty)
                          Text(
                            alarm.label,
                            style: const TextStyle(
                                color: Color(0xFF90A4AE), fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: const Color(0xFF7B8CDE),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFF546E7A)),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (alarm.isSmartAlarm) ...[
                    _chip('🧠 Умный'),
                    const SizedBox(width: 6),
                  ],
                  if (alarm.gradualAlarm) ...[
                    _chip('🌅 Плавный'),
                    const SizedBox(width: 6),
                  ],
                  if (hasRepeat)
                    ...List.generate(7, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          dayNames[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: alarm.repeatDays[i]
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: alarm.repeatDays[i]
                                ? const Color(0xFF7B8CDE)
                                : const Color(0xFF37474F),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF7B8CDE), fontSize: 11)),
    );
  }
}
