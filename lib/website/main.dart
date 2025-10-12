import 'package:flutter/material.dart';
import 'router.dart';

void main() {
  runApp(const GhoteWebsiteApp());
}

class GhoteWebsiteApp extends StatelessWidget {
  const GhoteWebsiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ghote - 您的學習夥伴',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: websiteRouter,
    );
  }
}
