import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_saathi_bd/core/network/api_service.dart';
import 'package:cyber_saathi_bd/features/url_checker/data/models/url_analysis.dart';
import 'package:cyber_saathi_bd/features/url_checker/data/repositories/url_analysis_repository.dart';
import 'package:cyber_saathi_bd/features/url_checker/presentation/views/url_checker_screen.dart';
import 'package:cyber_saathi_bd/features/url_checker/presentation/viewmodels/url_analysis_provider.dart';

void main() {
  testWidgets('renders URL checker empty state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UrlCheckerScreen()),
      ),
    );

    expect(find.text('Check a suspicious link'), findsOneWidget);
    expect(find.text('Analyze URL'), findsOneWidget);
    expect(
      find.text('Enter a URL above to view its risk indicators.'),
      findsOneWidget,
    );
  });

  testWidgets('submits a URL and displays the returned analysis',
      (tester) async {
    final repository = _FakeUrlAnalysisRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          urlAnalysisRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: UrlCheckerScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'https://example.com');
    await tester.tap(find.text('Analyze URL'));
    await tester.pumpAndSettle();

    expect(repository.lastUrl, 'https://example.com');
    expect(find.text('LOW RISK · 0/100'), findsOneWidget);
    expect(find.text('No structural warning indicators were found.'),
        findsOneWidget);
  });
}

class _FakeUrlAnalysisRepository extends UrlAnalysisRepository {
  _FakeUrlAnalysisRepository() : super(ApiService());

  String? lastUrl;

  @override
  Future<UrlAnalysis> analyze(String url) async {
    lastUrl = url;
    return const UrlAnalysis(
      originalUrl: 'https://example.com',
      normalizedUrl: 'https://example.com/',
      riskLevel: 'low',
      riskScore: 0,
      indicators: [],
      limitations: ['Test limitation'],
    );
  }
}
