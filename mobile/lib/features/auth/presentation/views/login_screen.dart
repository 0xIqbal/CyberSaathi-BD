import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../viewmodels/auth_view_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authViewModel, super.key});

  final AuthViewModel authViewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authViewModel: widget.authViewModel),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.authViewModel.login(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Subtle cyber-grid & radial emerald glow background
          Positioned.fill(
            child: CustomPaint(painter: _CyberBackdropPainter()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.forestSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.forestBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 42,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.08),
                          blurRadius: 36,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 780;
                            if (isWide) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(
                                      flex: 11,
                                      child: _CyberShowcasePane(),
                                    ),
                                    Container(
                                      width: 1,
                                      color: AppColors.forestBorder,
                                    ),
                                    Expanded(
                                      flex: 10,
                                      child: _buildFormPane(context),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                const _CyberShowcasePane(compact: true),
                                Container(
                                  height: 1,
                                  color: AppColors.forestBorder,
                                ),
                                _buildFormPane(context),
                              ],
                            );
                          },
                        ),
                        // Solid emerald bottom accent strip matching reference screenshot
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.emeraldDark,
                                AppColors.emerald,
                                AppColors.emeraldGlow,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPane(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 44),
      child: ListenableBuilder(
        listenable: widget.authViewModel,
        builder: (context, child) {
          final isSubmitting =
              widget.authViewModel.status == AuthStatus.submitting;

          return Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Centered spaced brand title matching reference right pane
                const Text(
                  'C Y B E R S A A T H I',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome back! Please login to your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 34),

                // Clean underline-style Email field
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: _underlineDecoration(
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email address.'
                      : null,
                ),
                const SizedBox(height: 22),

                // Clean underline-style Password field
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: _underlineDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 19,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your password.'
                      : null,
                ),
                const SizedBox(height: 16),

                // Remember me + Security status row
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        activeColor: AppColors.emerald,
                        checkColor: Colors.white,
                        side: const BorderSide(color: AppColors.forestBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _rememberMe = !_rememberMe),
                      child: const Text(
                        'Remember me',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 13,
                          color: AppColors.emerald,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'TLS Encrypted',
                          style: TextStyle(
                            color: AppColors.emerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (widget.authViewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      widget.authViewModel.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Side-by-side Login & Sign up buttons matching reference screenshot
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : _openRegister,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.emerald,
                          side: const BorderSide(
                            color: AppColors.emerald,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Bottom footer link matching "Contact us" underline accent in reference
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'CyberSaathi BD • Citizen Digital Protection',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 34,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _underlineDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      prefixIcon: Icon(icon, size: 19, color: AppColors.textMuted),
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.forestBorder, width: 1.4),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.emerald, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 1.4),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }
}

class _CyberShowcasePane extends StatelessWidget {
  const _CyberShowcasePane({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 28 : 42,
        vertical: compact ? 30 : 44,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF131026),
            Color(0xFF0D0B1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Two-line display title matching reference ("Trends" / "Healthcare")
          const Text(
            'CyberSaathi',
            style: TextStyle(
              color: Color(0xFFB8B2D8),
              fontSize: 38,
              fontWeight: FontWeight.w300,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Security',
            style: TextStyle(
              color: AppColors.emerald,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Defend against phishing links, exposed NID documents, and medical misinformation with real-time AI protection built for Bangladesh.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          SizedBox(height: compact ? 24 : 34),

          // Cybersecurity & Health Protection Centerpiece Illustration
          const Center(child: _CyberShieldIllustration()),
        ],
      ),
    );
  }
}

class _CyberShieldIllustration extends StatelessWidget {
  const _CyberShieldIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient circular halo matching reference illustration backdrop
          Container(
            width: 195,
            height: 195,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.2),
              ),
            ),
          ),
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.28),
              ),
            ),
          ),

          // Central Glowing Cyber Shield
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.emeraldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),

          // Orbiting Cyber & Health Capability Badges
          const Positioned(
            top: 14,
            left: 16,
            child: _OrbitNode(
              icon: Icons.radar_rounded,
              label: 'Phishing Guard',
              color: AppColors.cyan,
            ),
          ),
          const Positioned(
            top: 18,
            right: 12,
            child: _OrbitNode(
              icon: Icons.health_and_safety_rounded,
              label: 'Health AI',
              color: AppColors.emerald,
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 10,
            child: _OrbitNode(
              icon: Icons.document_scanner_outlined,
              label: 'PII Redact',
              color: AppColors.warning,
            ),
          ),
          const Positioned(
            bottom: 14,
            right: 14,
            child: _OrbitNode(
              icon: Icons.lock_outline_rounded,
              label: 'Evidence Vault',
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitNode extends StatelessWidget {
  const _OrbitNode({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forestElevated,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    const spacing = 44.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}