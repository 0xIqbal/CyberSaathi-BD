import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppStatus { safe, success, warning, danger, info, neutral }

class AppStatusIndicator extends StatelessWidget {
  const AppStatusIndicator({
    required this.label,
    required this.status,
    super.key,
    this.icon,
  });

  final String label;
  final AppStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(status);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.circle, size: 12, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _colors(AppStatus value) {
    return switch (value) {
      AppStatus.safe || AppStatus.success => (
          background: AppColors.successBackground,
          foreground: AppColors.success,
        ),
      AppStatus.warning => (
          background: AppColors.warningBackground,
          foreground: AppColors.warning,
        ),
      AppStatus.danger => (
          background: AppColors.dangerBackground,
          foreground: AppColors.danger,
        ),
      AppStatus.info => (
          background: AppColors.infoBackground,
          foreground: AppColors.info,
        ),
      AppStatus.neutral => (
          background: AppColors.surfaceMuted,
          foreground: AppColors.textMuted,
        ),
    };
  }
}
