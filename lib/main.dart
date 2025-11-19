import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'website/main.dart' as website;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional - .env file may not exist)
  // Skip loading on web platform to avoid 404 errors
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env file is optional - API key can be set in settings or via environment variables
      debugPrint('Info: .env file not found, using settings or environment variables for API keys');
    }
  }
  
  // Check if running on web platform
  if (kIsWeb) {
    // Run website version
    website.main();
    return;
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Set platform-specific system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghote',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark, // Force dark theme for consistency
      debugShowCheckedModeBanner: false,
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  User? _user;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onAnimationComplete: _onSplashComplete);
    }

    if (_user == null) {
      return LoginScreen(onLogin: (_, __) {});
    }

    return DashboardScreen(
      userName: _user!.displayName ?? _user!.email ?? '',
      onLogout: () async {
        await FirebaseAuth.instance.signOut();
      },
    );
  }
}