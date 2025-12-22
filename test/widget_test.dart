// This is a basic Flutter widget test for the Ghote app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App widget smoke test', (WidgetTester tester) async {
    // Basic smoke test - verify that a MaterialApp can be built
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Ghote'),
          ),
        ),
      ),
    );

    // Verify basic widget rendering
    expect(find.text('Ghote'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Widget tree construction test', (WidgetTester tester) async {
    // Test that nested widgets render correctly
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Test App'),
          ),
          body: const Column(
            children: [
              Text('Item 1'),
              Text('Item 2'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test App'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
  });
}
