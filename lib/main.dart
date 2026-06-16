import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  Future<void> _toggleTheme(bool value, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode_$uid', value);
    if (mounted) setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueGrey,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
      ),
      home: SplashRouter(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
        onDarkModeLoaded: (val) {
          if (mounted) setState(() => _isDarkMode = val);
        },
      ),
    );
  }
}

class SplashRouter extends StatefulWidget {
  final bool isDarkMode;
  final Future<void> Function(bool value, String uid) onThemeChanged;
  final ValueChanged<bool> onDarkModeLoaded;

  const SplashRouter({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onDarkModeLoaded,
  });

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  bool _checking = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(Duration(milliseconds: 300));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Load this user's theme
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('darkMode_${user.uid}') ?? false;
      widget.onDarkModeLoaded(isDark);
    }

    if (mounted) {
      setState(() {
        _user = user;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: Color(0xFF1A237E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Assignment App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    if (_user != null) {
      return HomePage(
        username: _user!.email!.split('@')[0],
        onThemeChanged: (val) => widget.onThemeChanged(val, _user!.uid),
        isDarkMode: widget.isDarkMode,
      );
    }

    return LoginPage(
      onThemeChanged: (val) => widget.onThemeChanged(val, ''),
      isDarkMode: false,
    );
  }
}
