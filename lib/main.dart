import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.init();
  runApp(const PickleballApp());
}

class PickleballApp extends StatelessWidget {
  const PickleballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Picklyball App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050506),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFACC15),
          selectionColor: Color(0x55FACC15),
          selectionHandleColor: Color(0xFFFACC15),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
