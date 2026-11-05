import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/views/login_screen.dart';

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
      body: const Center(child: Text('Protected dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: authViewModel.logout,
        label: const Text('Log out'),
        icon: const Icon(Icons.logout),
      ),
    );
  }
}
