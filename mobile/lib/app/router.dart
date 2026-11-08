import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/document_scanner/presentation/views/document_scanner_screen.dart';
import '../features/evidence_vault/presentation/views/evidence_home_screen.dart';
import '../features/health_navigator/presentation/screens/health_home_screen.dart';
import '../features/url_checker/presentation/views/url_checker_screen.dart';
import '../shared/widgets/premium_motion.dart';

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
      appBar: AppBar(
        title: const Text('CyberSaathi BD'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: authViewModel.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            const PremiumReveal(child: _DashboardHero()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your safety toolkit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: columns == 2 ? 1.65 : 2.25,
                  children: [
                    PremiumReveal(
                      delay: const Duration(milliseconds: 80),
                      child: _FeatureCard(
                        icon: Icons.travel_explore_rounded,
                        title: 'URL Scanner',
                        subtitle: 'Check suspicious websites safely.',
                        color: AppColors.medicalBlue,
                        onTap: () => _open(context, const UrlCheckerScreen()),
                      ),
                    ),
                    PremiumReveal(
                      delay: const Duration(milliseconds: 140),
                      child: _FeatureCard(
                        icon: Icons.health_and_safety_rounded,
                        title: 'Health Navigator',
                        subtitle: 'Understand health information easily.',
                        color: AppColors.teal600,
                        onTap: () => _open(context, const HealthHomeScreen()),
                      ),
                    ),
                    PremiumReveal(
                      delay: const Duration(milliseconds: 200),
                      child: _FeatureCard(
                        icon: Icons.description_outlined,
                        title: 'Document Scanner',
                        subtitle: 'Find sensitive information before sharing.',
                        color: AppColors.warning,
                        onTap: () =>
                            _open(context, const DocumentScannerScreen()),
                      ),
                    ),
                    PremiumReveal(
                      delay: const Duration(milliseconds: 260),
                      child: _FeatureCard(
                        icon: Icons.shield_outlined,
                        title: 'Evidence Vault',
                        subtitle: 'Organize incident evidence securely.',
                        color: AppColors.navy800,
                        onTap: () => _open(context, const EvidenceHomeScreen()),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _DashboardDataNote(),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          colors: [AppColors.navy950, Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          AppColors.cardShadow,
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Digital Safety Companion',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Protect your links, documents, health information and evidence in one place.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: Colors.white24),
            ),
            child: const PulseIcon(
              icon: Icons.security_rounded,
              size: 48,
              color: AppColors.teal100,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardDataNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.infoBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_outlined, color: AppColors.info),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Security activity summaries will appear here as supported by your connected modules. No statistics are shown until real data is available.',
                style: TextStyle(color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
