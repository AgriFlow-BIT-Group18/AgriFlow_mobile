import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/translation_service.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriFlow Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6C50)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // Set the initial route for testing.
      // E.g. to test Farmer Onboarding:
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}