import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_saathi_bd/app/app.dart';

void main() {
  testWidgets('renders the CyberSaathi BD loading state', (tester) async {
    await tester.pumpWidget(const CyberSaathiApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
