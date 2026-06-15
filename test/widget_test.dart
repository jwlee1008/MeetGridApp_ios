import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetgrid/main.dart';

void main() {
  testWidgets('MeetGrid app renders', (tester) async {
    await tester.pumpWidget(const MeetGridApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MeetGrid'), findsWidgets);
  });
}
