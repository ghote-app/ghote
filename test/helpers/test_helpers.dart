import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to wrap widgets with MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Helper function to wrap widgets with specific theme
Widget createThemedWidget(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(
      body: child,
    ),
  );
}

/// Helper to create a widget wrapped in a SizedBox for size testing
Widget createSizedWidget(Widget child, {double? width, double? height}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    ),
  );
}

/// Extension on WidgetTester for common test operations
extension WidgetTesterExtension on WidgetTester {
  /// Pump widget and wait for all animations to complete
  Future<void> pumpAndSettle() async {
    await pump();
    await pumpAndSettle();
  }
  
  /// Enter text in a TextField by key
  Future<void> enterTextByKey(Key key, String text) async {
    await tap(find.byKey(key));
    await pump();
    await enterText(find.byKey(key), text);
    await pump();
  }
}
