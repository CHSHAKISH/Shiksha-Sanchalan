import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiksha_sanchalan/providers/theme_provider.dart';
import 'package:shiksha_sanchalan/screens/home_screen.dart';
import 'package:shiksha_sanchalan/screens/login_screen.dart';
import 'package:shiksha_sanchalan/screens/onboarding_screen.dart';
import 'firebase_options.dart';

// Your existing color swatch
const MaterialColor appPrimaryColor = MaterialColor(
  0xFF1F319D,
  <int, Color>{
    50: Color(0xFFEDF0FF), 100: Color(0xFFC5CAE9), 200: Color(0xFF9FA8DA),
    300: Color(0xFF7986CB), 400: Color(0xFF5C6BC0), 500: Color(0xFF1F319D),
    600: Color(0xFF1A237E), 700: Color(0xFF1A237E), 800: Color(0xFF1A237E),
    900: Color(0xFF1A237E),
  },
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
  final bool isDarkMode = prefs.getBool('theme_preference') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode),
      child: MyApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingComplete;
  const MyApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Shiksha Sanchalan',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.currentTheme,
      // Light Theme Definition
      theme: ThemeData(
        primarySwatch: appPrimaryColor,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: appPrimaryColor,
          accentColor: const Color(0xFFFFD600),
          backgroundColor: const Color(0xFFF5F6FA),
          cardColor: Colors.white,
          brightness: Brightness.light,
        ).copyWith(secondary: const Color(0xFFFFD600), error: const Color(0xFFEA0831)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF4D4D4D),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Poppins', color: Color(0xFF000000), fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: appPrimaryColor, width: 2.0))),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white, selectedItemColor: appPrimaryColor, unselectedItemColor: Colors.grey, showUnselectedLabels: true, type: BottomNavigationBarType.fixed),
      ),
      // Dark Theme Definition
      darkTheme: ThemeData(
        primarySwatch: appPrimaryColor,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: appPrimaryColor,
          accentColor: const Color(0xFFFFD600),
          backgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFFFFD600), error: const Color(0xFFCF6679)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(elevation: 0, color: const Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1E1E1E), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: appPrimaryColor, width: 2.0))),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1E1E1E), selectedItemColor: appPrimaryColor, unselectedItemColor: Colors.grey, showUnselectedLabels: true, type: BottomNavigationBarType.fixed),
      ),
      home: onboardingComplete ? const AuthWrapper() : const OnboardingScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
