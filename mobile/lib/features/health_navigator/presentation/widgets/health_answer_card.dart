import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HealthAnswerCard extends StatelessWidget {
  const HealthAnswerCard({
    required this.answer,
    required this.isSpeaking,
    required this.onSpeak,
    super.key,
  });

  final String answer;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.teal50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.teal700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'স্বাস্থ্য সহায়কের উত্তর',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: isSpeaking ? 'বন্ধ করুন' : 'উত্তর শুনুন',
                  onPressed: onSpeak,
                  icon: Icon(
                    isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(answer),
          ],
        ),
      ),
    );
  }
}
