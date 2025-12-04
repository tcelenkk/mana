import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  WidgetsFlutterBinding.ensureInitialized();
    
    // EKRAN HEP DİKEY KALSIN
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode),
      child: const ManaApp(),
    ),
  );
}

class ManaApp extends StatelessWidget {
  const ManaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mânâ',
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.transparent, // BU SATIR ÇOK ÖNEMLİ!
            fontFamily: 'Ubuntu',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent, // BU SATIR ÇOK ÖNEMLİ!
            fontFamily: 'Ubuntu',
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
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
        if (snapshot.connectionState == ConnectionState.active) {
          return const HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// TEMA SAĞLAYICI – HATA YOK
class ThemeProvider with ChangeNotifier {
  late bool _isDark;        // late eklendi
  late ThemeMode _themeMode; // late eklendi

  ThemeProvider(bool isDark) {
    _isDark = isDark;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => _isDark;
  ThemeMode get themeMode => _themeMode;

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    _themeMode = _isDark ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);

    notifyListeners();
  }
}