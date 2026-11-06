import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_saathi_bd/features/url_checker/presentation/viewmodels/url_analysis_provider.dart';

void main() {
  test('empty URL produces a validation error without a request', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(urlAnalysisProvider.notifier).analyze(' ');

    expect(
      container.read(urlAnalysisProvider).errorMessage,
      'Enter a URL to analyze.',
    );
    expect(container.read(urlAnalysisProvider).isLoading, isFalse);
  });
}
