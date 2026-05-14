import 'package:flutter/material.dart';

class SleepQualityDialog extends StatefulWidget {
  const SleepQualityDialog({super.key});

  @override
  State<SleepQualityDialog> createState() => _SleepQualityDialogState();
}

class _SleepQualityDialogState extends State<SleepQualityDialog> {
  int _selected = 3;

  @override
  Widget build(BuildContext context) {
    const labels = ['Ужасно', 'Плохо', 'Нормально', 'Хорошо', 'Отлично'];
    const emojis = ['😩', '😔', '😐', '😊', '😄'];

    return AlertDialog(
      backgroundColor: const Color(0xFF1A2744),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Как вы поспали?',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emojis[_selected - 1],
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            labels[_selected - 1],
            style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final val = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selected = val),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star,
                    size: 36,
                    color: val <= _selected
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF37474F),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text(
            'Сохранить',
            style: TextStyle(color: Color(0xFF7B8CDE), fontSize: 16),
          ),
        ),
      ],
    );
  }
}
