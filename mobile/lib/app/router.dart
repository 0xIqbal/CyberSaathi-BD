import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/document_scanner/presentation/views/document_scanner_screen.dart';
import '../features/evidence_vault/presentation/views/evidence_home_screen.dart';
import '../features/url_checker/presentation/views/url_checker_screen.dart';

abstract final class AppRouter {
  static ThemeData get theme => AppTheme.light;

  static Widget buildHome(AuthViewModel authViewModel) {
    return ListenableBuilder(
      listenable: authViewModel,
      builder: (context, child) {
        if (authViewModel.status == AuthStatus.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authViewModel.isAuthenticated) {
          return _DashboardPlaceholder(authViewModel: authViewModel);
        }

        return LoginScreen(authViewModel: authViewModel);
      },
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder({required this.authViewModel});

  final AuthViewModel authViewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CyberSaathi BD')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UrlCheckerScreen()),
              ),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Check a URL'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DocumentScannerScreen(),
                ),
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Scan a document'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EvidenceHomeScreen(),
                ),
              ),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('Evidence vault'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: authViewModel.logout,
        label: const Text('Log out'),
        icon: const Icon(Icons.logout),
      ),
    );
  }
}
