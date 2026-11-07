import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/health_source.dart';

class HealthSourceCard extends StatelessWidget {
  const HealthSourceCard({required this.source, super.key});

  final HealthSource source;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: Text(source.name),
        subtitle: Text(source.publisher ?? _label(source.sourceType)),
        trailing: IconButton(
          tooltip: 'উৎস খুলুন',
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: source.url.isEmpty
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Official source'),
                      content: SelectableText(source.url),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  String _label(String? value) {
    if (value == null || value.isEmpty) return 'Official source';
    return value.toUpperCase();
  }
}
