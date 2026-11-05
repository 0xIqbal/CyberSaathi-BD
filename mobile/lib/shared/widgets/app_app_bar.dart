import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ??
          (showBackButton
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null),
      titleSpacing: leading == null && !showBackButton ? AppSpacing.md : 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
