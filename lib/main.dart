import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'dart:io';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  String? _userName;
  bool _showSplash = true;

  void _onLogin(String name, String email) {
    setState(() {
      _userName = name;
    });
  }

  void _onLogout() {
    setState(() {
      _userName = null;
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

    if (_userName == null) {
      return LoginScreen(onLogin: _onLogin);
    }

    return DashboardScreen(userName: _userName!, onLogout: _onLogout);
  }
}