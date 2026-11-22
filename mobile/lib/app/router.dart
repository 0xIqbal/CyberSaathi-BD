import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

class _DashboardPlaceholder extends StatefulWidget {
  const _DashboardPlaceholder({required this.authViewModel});

  final AuthViewModel authViewModel;

  @override
  State<_DashboardPlaceholder> createState() => _DashboardPlaceholderState();
}

class _DashboardPlaceholderState extends State<_DashboardPlaceholder> {
  bool _isBangla = false;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openPortfolio() {
    try {
      html.window.open('https://portfolio-diu-iqbal.vercel.app/', '_blank');
    } catch (_) {
      Clipboard.setData(const ClipboardData(
        text: 'https://portfolio-diu-iqbal.vercel.app/',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portfolio link copied to clipboard!'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.authViewModel.user?.name ?? 'Citizen Member';

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Hero Canvas
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      18,
                      AppSpacing.lg,
                      44,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Floating Top Navigation Bar
                        _TopNavBar(
                          isBangla: _isBangla,
                          onOpenHealth: () =>
                              _open(context, const HealthHomeScreen()),
                          onOpenScanner: () =>
                              _open(context, const UrlCheckerScreen()),
                          onOpenDeveloper: _openPortfolio,
                          onLogout: widget.authViewModel.logout,
                        ),
                        const SizedBox(height: 26),

                        // 2. Centered Pill Language Switcher
                        Center(
                          child: _LanguagePillSwitch(
                            isBangla: _isBangla,
                            onChanged: (bn) => setState(() => _isBangla = bn),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 3. Asymmetric Split Hero + Interactive Sovereign Pass
                        PremiumReveal(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              final heroCopy = _HeroCopySection(
                                isBangla: _isBangla,
                                isWide: isWide,
                                onPrimaryTap: () =>
                                    _open(context, const HealthHomeScreen()),
                                onSecondaryTap: () =>
                                    _open(context, const UrlCheckerScreen()),
                              );
                              final interactiveCard = _InteractiveSaathiCard(
                                userName: userName,
                                isBangla: _isBangla,
                                onQuickHealthTap: () =>
                                    _open(context, const HealthHomeScreen()),
                                onOpenUrl: () =>
                                    _open(context, const UrlCheckerScreen()),
                                onOpenDoc: () => _open(
                                    context, const DocumentScannerScreen()),
                                onOpenVault: () =>
                                    _open(context, const EvidenceHomeScreen()),
                              );

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(flex: 6, child: heroCopy),
                                    const SizedBox(width: 48),
                                    Expanded(flex: 5, child: interactiveCard),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  heroCopy,
                                  const SizedBox(height: 36),
                                  interactiveCard,
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Full-Bleed Edge-to-Edge Telemetry Metric Strip
              _FullBleedMetricsStrip(isBangla: _isBangla),

              // 5. Four Core Safety & Health Modules Section
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      44,
                      AppSpacing.lg,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isBangla
                                  ? 'আপনার ডিজিটাল সুরক্ষা টুলকিট'
                                  : 'Sovereign Safety & Health Modules',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldTint,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                                border: Border.all(
                                  color:
                                      AppColors.emerald.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: AppColors.emerald,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '4 Active Modules',
                                    style: TextStyle(
                                      color: AppColors.emerald,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 780 ? 2 : 1;
                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: columns == 2 ? 2.45 : 2.55,
                              children: [
                                PremiumReveal(
                                  delay: const Duration(milliseconds: 60),
                                  child: _ModuleCard(
                                    icon: Icons.health_and_safety_rounded,
                                    badge: 'AI + Verified',
                                    title: _isBangla
                                        ? 'স্বাস্থ্য সহায়ক (Health Navigator)'
                                        : 'Health Navigator',
                                    subtitle: _isBangla
                                        ? 'বাংলা ও বাংলিশে যাচাইকৃত চিকিৎসা তথ্য ও পরামর্শ।'
                                        : 'Fast Bangla & Banglish health guidance backed by official sources.',
                                    accent: AppColors.emerald,
                                    onTap: () => _open(
                                        context, const HealthHomeScreen()),
                                  ),
                                ),
                                PremiumReveal(
                                  delay: const Duration(milliseconds: 120),
                                  child: _ModuleCard(
                                    icon: Icons.travel_explore_rounded,
                                    badge: 'Phishing Shield',
                                    title: _isBangla
                                        ? 'লিংক স্ক্যানার (URL Scanner)'
                                        : 'URL Scanner',
                                    subtitle: _isBangla
                                        ? 'সন্দেহজনক ওয়েবসাইট ও ফিশিং লিংক যাচাই করুন।'
                                        : 'Inspect suspicious websites and phishing links safely.',
                                    accent: AppColors.cyan,
                                    onTap: () => _open(
                                        context, const UrlCheckerScreen()),
                                  ),
                                ),
                                PremiumReveal(
                                  delay: const Duration(milliseconds: 180),
                                  child: _ModuleCard(
                                    icon: Icons.document_scanner_outlined,
                                    badge: 'PII Guard',
                                    title: _isBangla
                                        ? 'ডকুমেন্ট স্ক্যানার'
                                        : 'Document Scanner',
                                    subtitle: _isBangla
                                        ? 'শেয়ার করার আগে সংবেদনশীল NID ও ব্যক্তিগত তথ্য শনাক্ত করুন।'
                                        : 'Detect exposed NID and sensitive data before sharing files.',
                                    accent: AppColors.warning,
                                    onTap: () => _open(context,
                                        const DocumentScannerScreen()),
                                  ),
                                ),
                                PremiumReveal(
                                  delay: const Duration(milliseconds: 240),
                                  child: _ModuleCard(
                                    icon: Icons.verified_user_outlined,
                                    badge: 'Encrypted Log',
                                    title: _isBangla
                                        ? 'এভিডেন্স ভল্ট (Evidence Vault)'
                                        : 'Evidence Vault',
                                    subtitle: _isBangla
                                        ? 'সাইবার ঘটনার প্রমাণ সুরক্ষিতভাবে সংরক্ষণ করুন।'
                                        : 'Organize and preserve cyber incident evidence securely.',
                                    accent: AppColors.purple,
                                    onTap: () => _open(
                                        context, const EvidenceHomeScreen()),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 36),

                        // 6. Developer Spotlight Card (Iqbal Portfolio)
                        PremiumReveal(
                          delay: const Duration(milliseconds: 300),
                          child: _DeveloperSpotlightCard(
                            onTap: _openPortfolio,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.isBangla,
    required this.onOpenHealth,
    required this.onOpenScanner,
    required this.onOpenDeveloper,
    required this.onLogout,
  });

  final bool isBangla;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenDeveloper;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 820;

    return Row(
      children: [
        // Brand Logo Mark
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CyberSaathi ',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'BD',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Text(
              'DIGITAL HEALTH & CYBER SHIELD',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.25,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isWide) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.forestSurface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.forestBorder),
            ),
            child: Row(
              children: [
                _NavPillItem(
                  icon: Icons.health_and_safety_outlined,
                  label: isBangla ? 'স্বাস্থ্য সহায়ক' : 'Health AI',
                  onTap: onOpenHealth,
                ),
                const SizedBox(width: 4),
                _NavPillItem(
                  icon: Icons.radar_rounded,
                  label: isBangla ? 'লিংক যাচাই' : 'URL Shield',
                  onTap: onOpenScanner,
                ),
                const SizedBox(width: 4),
                _NavPillItem(
                  icon: Icons.code_rounded,
                  label: 'Developer',
                  onTap: onOpenDeveloper,
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
        OutlinedButton.icon(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: AppColors.forestSurface,
            side: const BorderSide(color: AppColors.forestBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 15),
          label: Text(
            isBangla ? 'লগ আউট' : 'Sign Out',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onOpenHealth,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.auto_awesome_rounded, size: 15),
          label: Text(
            isBangla ? 'প্রশ্ন করুন' : 'Ask Saathi',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePillSwitch extends StatelessWidget {
  const _LanguagePillSwitch({
    required this.isBangla,
    required this.onChanged,
  });

  final bool isBangla;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.forestSurface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.forestBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangTab(
            label: 'English',
            active: !isBangla,
            onTap: () => onChanged(false),
          ),
          _LangTab(
            label: 'বাংলা',
            active: isBangla,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _LangTab extends StatelessWidget {
  const _LangTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _HeroCopySection extends StatelessWidget {
  const _HeroCopySection({
    required this.isBangla,
    required this.isWide,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final bool isBangla;
  final bool isWide;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final headlineSize = isWide ? 50.0 : 38.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.emeraldTint,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla
                    ? 'সুরক্ষিত স্বাস্থ্য ও সাইবার নিরাপত্তা প্ল্যাটফর্ম'
                    : 'Sovereign Health & Cyber Safety Architecture',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        Text(
          isBangla ? 'একটি প্ল্যাটফর্ম।' : 'One companion.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: headlineSize,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        Text(
          isBangla ? 'নিরাপদ স্বাস্থ্য ও সুরক্ষা।' : 'Trusted Health & Safety.',
          style: TextStyle(
            color: AppColors.emerald,
            fontSize: headlineSize,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        Text(
          isBangla ? 'বাংলাদেশের জন্য তৈরি।' : 'Made for Bangladesh.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: headlineSize,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          isBangla
              ? 'ভুল চিকিৎসা তথ্য, ফিশিং লিংক এবং ব্যক্তিগত ডকুমেন্ট ফাঁস হওয়া থেকে নিজেকে সুরক্ষিত রাখুন — বাংলা ও বাংলিশ এআই সহায়তায়।'
              : 'A privacy-first digital health and cyber protection suite that replaces unverified medical rumors, risky links, and exposed documents.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 30),

        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onPrimaryTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                isBangla ? 'স্বাস্থ্য পরামর্শ নিন' : 'Open Health Navigator',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onSecondaryTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                backgroundColor: AppColors.forestSurface,
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.forestBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: Text(
                isBangla ? 'সন্দেহজনক লিংক যাচাই' : 'Scan Suspicious URL',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Wrap(
          spacing: 22,
          runSpacing: 8,
          children: [
            _TrustBadge(
              icon: Icons.lock_outline_rounded,
              label: isBangla ? 'গোপনীয়তা সুরক্ষিত' : 'Privacy-first design',
            ),
            _TrustBadge(
              icon: Icons.verified_outlined,
              label: isBangla
                  ? 'যাচাইকৃত স্বাস্থ্য সূত্র'
                  : 'Official BD & WHO sources',
            ),
            _TrustBadge(
              icon: Icons.bolt_rounded,
              label: isBangla ? 'তাৎক্ষণিক বাংলা উত্তর' : 'Real-time Bangla AI',
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.emerald),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InteractiveSaathiCard extends StatefulWidget {
  const _InteractiveSaathiCard({
    required this.userName,
    required this.isBangla,
    required this.onQuickHealthTap,
    required this.onOpenUrl,
    required this.onOpenDoc,
    required this.onOpenVault,
  });

  final String userName;
  final bool isBangla;
  final VoidCallback onQuickHealthTap;
  final VoidCallback onOpenUrl;
  final VoidCallback onOpenDoc;
  final VoidCallback onOpenVault;

  @override
  State<_InteractiveSaathiCard> createState() => _InteractiveSaathiCardState();
}

class _InteractiveSaathiCardState extends State<_InteractiveSaathiCard> {
  Offset _tilt = Offset.zero;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 340,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.16),
                blurRadius: 95,
                spreadRadius: 24,
              ),
            ],
          ),
        ),
        Column(
          children: [
            MouseRegion(
              onHover: (event) {
                final size = context.size;
                if (size == null) return;
                final dx = (event.localPosition.dx / size.width - 0.5) * 0.14;
                final dy = (event.localPosition.dy / size.height - 0.5) * -0.14;
                setState(() => _tilt = Offset(dx, dy));
              },
              onExit: (_) => setState(() => _tilt = Offset.zero),
              child: GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: Offset.zero, end: _tilt),
                  duration: const Duration(milliseconds: 160),
                  builder: (context, offset, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(offset.dx)
                        ..rotateX(offset.dy),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF311B6B),
                          Color(0xFF201347),
                          Color(0xFF120B29),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.48),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          bottom: -14,
                          child: Icon(
                            Icons.shield_outlined,
                            size: 185,
                            color: Colors.white.withValues(alpha: 0.045),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFFDDD6FE),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'CYBERSAATHI BD',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'CITIZEN SAFETY & HEALTH PASS',
                                        style: TextStyle(
                                          color: Color(0xFFC4B5FD),
                                          fontSize: 9.5,
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(
                                          AppRadii.pill),
                                      border: Border.all(
                                        color: AppColors.emerald
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Color(0xFFDDD6FE),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const _EmvChipGraphic(),
                                  InkWell(
                                    onTap: widget.onQuickHealthTap,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.isBangla
                                                ? 'স্বাস্থ্য চ্যাট খুলুন'
                                                : 'Launch Health AI',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SAATHI SHIELD IDENTIFIER',
                                    style: TextStyle(
                                      color: Color(0xFFC4B5FD),
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        _revealed
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _revealed
                                            ? 'Tap to mask'
                                            : 'Tap to reveal',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _revealed
                                    ? 'CSBD-8801-9420-SAFE'
                                    : 'CSBD-8801-••••-SAFE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Color(0xFFEDE9FE),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 7,
                                      runSpacing: 6,
                                      children: [
                                        _CardTag(
                                          label: 'Health AI',
                                          onTap: widget.onQuickHealthTap,
                                        ),
                                        _CardTag(
                                          label: 'URL Shield',
                                          onTap: widget.onOpenUrl,
                                        ),
                                        _CardTag(
                                          label: 'PII Scan',
                                          onTap: widget.onOpenDoc,
                                        ),
                                        _CardTag(
                                          label: 'Vault',
                                          onTap: widget.onOpenVault,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PROOF-OF-SAFETY',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: AppColors.emerald,
                ),
                SizedBox(width: 6),
                Text(
                  'Interactive pass: Move cursor to tilt, tap card to reveal ID',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _EmvChipGraphic extends StatelessWidget {
  const _EmvChipGraphic();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Container(
              width: 0.8,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Container(
              width: 0.8,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.8,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.8,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  const _CardTag({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 12,
              color: AppColors.emerald,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullBleedMetricsStrip extends StatelessWidget {
  const _FullBleedMetricsStrip({required this.isBangla});

  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        value: '< 1.8s',
        label: isBangla ? 'এআই রেসপন্স সময়' : 'AI RESPONSE LATENCY',
      ),
      _MetricItem(
        value: '100%',
        label: isBangla ? 'যাচাইকৃত তথ্যসূত্র' : 'DEDUPLICATED SOURCES',
      ),
      _MetricItem(
        value: 'BN / EN',
        label: isBangla ? 'দ্বিভাষিক সহায়তা' : 'BILINGUAL GUIDANCE',
      ),
      _MetricItem(
        value: '4-in-1',
        label: isBangla ? 'নিরাপত্তা ও স্বাস্থ্য স্যুট' : 'SAFETY & HEALTH SUITE',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0D1F),
        border: Border(
          top: BorderSide(color: AppColors.forestBorder),
          bottom: BorderSide(color: AppColors.forestBorder),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 680) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items,
                );
              }
              return Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 28,
                runSpacing: 20,
                children: items,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.15,
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.forestSurface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.forestBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.forestElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forestBorder),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperSpotlightCard extends StatelessWidget {
  const _DeveloperSpotlightCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.forestSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emeraldTint,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.emerald,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SYSTEM ARCHITECT & DEVELOPER',
                          style: TextStyle(
                            color: AppColors.emerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: const Text(
                            'Portfolio Live',
                            style: TextStyle(
                              color: AppColors.emerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Designed & Developed by Iqbal',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Click to open portfolio: portfolio-diu-iqbal.vercel.app',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.forestElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forestBorder),
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.emerald,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}