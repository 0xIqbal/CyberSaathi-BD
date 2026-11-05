import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label ?? 'Loading',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(label!),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    required this.child,
    super.key,
    this.loading = false,
    this.label,
  });

  final Widget child;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (!loading) return child;
    return Stack(
      children: [
        child,
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Color(0x33071A2B),
          ),
        ),
        Positioned.fill(child: AppLoading(label: label ?? 'Loading')),
      ],
    );
  }
}
