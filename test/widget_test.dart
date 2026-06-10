import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ember/main.dart';

void main() {
  testWidgets('App renders library screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EmberApp());
    expect(find.text('library'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
