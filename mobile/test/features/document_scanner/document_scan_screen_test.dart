import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyber_saathi_bd/features/document_scanner/presentation/views/document_scanner_screen.dart';

void main() {
  testWidgets('renders document scanner empty state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DocumentScannerScreen()),
      ),
    );

    expect(find.text('Check document privacy'), findsOneWidget);
    expect(find.text('Select PDF or DOCX'), findsOneWidget);
    expect(
      find.text('Select a private PDF or DOCX file to begin.'),
      findsOneWidget,
    );
  });
}
