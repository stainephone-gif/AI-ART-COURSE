import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_ringing_screen.dart';
import 'services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.init();
  runApp(const SleepAlarmApp());
}

class SleepAlarmApp extends StatefulWidget {
  const SleepAlarmApp({super.key});

  @override
  State<SleepAlarmApp> createState() => _SleepAlarmAppState();
}

class _SleepAlarmAppState extends State<SleepAlarmApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AlarmService.ringStream.listen((alarmSettings) {
      if (alarmSettings != null) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) =>
                AlarmRingingScreen(alarmSettings: alarmSettings),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SleepWell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B8CDE),
          surface: Color(0xFF1A2744),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B2A),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
