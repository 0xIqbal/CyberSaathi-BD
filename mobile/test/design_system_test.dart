import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_saathi_bd/core/theme/app_theme.dart';

void main() {
  test('configures the CyberSaathi BD Material 3 theme', () {
    final theme = AppTheme.light;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
  });
}
