import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hackathon_app/main.dart';

void main() {
  testWidgets('boots into sign in and supports auth navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.ensureVisible(find.text('Don\'t have an account? Sign up'));
    await tester.tap(find.text('Don\'t have an account? Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
