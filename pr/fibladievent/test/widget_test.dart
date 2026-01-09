import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p/main.dart';

void main() {
  testWidgets('Simple MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('hi'))));
    await tester.pump();

    expect(find.text('hi'), findsOneWidget);
  });
}
