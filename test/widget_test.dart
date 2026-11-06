// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vrcworldvoterdesktop/main.dart';

void main() {
  testWidgets('Login form starts without the two-factor field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Two-factor authentication code'), findsNothing);
    expect(find.text('Send'), findsOneWidget);
  });
}
