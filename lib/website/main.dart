import 'package:flutter/material.dart';
import 'router.dart';
import 'i18n.dart';

void main() {
  runApp(const GhoteWebsiteApp());
}

class GhoteWebsiteApp extends StatelessWidget {
  const GhoteWebsiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp.router(
          key: ValueKey(localeController.locale),
          title: 'Ghote - 您的學習夥伴',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          routerConfig: websiteRouter,
        );
      },
    );
  }
}
