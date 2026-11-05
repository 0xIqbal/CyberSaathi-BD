import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    return onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: card,
          );
  }
}
