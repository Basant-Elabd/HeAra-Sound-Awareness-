import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'firebase_options.dart';

import 'features/splash/splash_screen.dart';
import 'core/audio_recording_service.dart';
import 'features/ble/ble_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  AudioRecordingService.initCommunicationPort();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        routes: {
          '/ble': (context) => const BLEPage(),
        },

        home: const SplashScreen(),
      ),
    );
  }
}