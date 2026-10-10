import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  // Ensure native bindings are stable
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SolarAppState(),
      child: const SolarCalcApp(),
    ),
  );
}

class SolarCalcApp extends StatelessWidget {
  const SolarCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarCalcPK',
      debugShowCheckedModeBanner: false,

      // Elegant Solar-Teal Emerald theme profile configuration matching Material 3 patterns
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1D9E75),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          primary: const Color(0xFF1D9E75),
          secondary: const Color(0xFF107B58),
          surface: const Color(0xFFF5F5F5),
        ),

        // Form field uniform styles
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1D9E75)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2),
          ),
          labelStyle: const TextStyle(
            color: Colors.blueGrey,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Button style templates
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: const Color(0xFF1F2933),
          displayColor: const Color(0xFF1F2933),
        ),
      ),

      home: Consumer<SolarAppState>(
        builder: (context, appState, _) {
          if (!appState.isLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return appState.setupComplete
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}
