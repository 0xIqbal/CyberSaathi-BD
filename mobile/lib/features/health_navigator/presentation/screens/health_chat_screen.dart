import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/health_article.dart';
import '../providers/health_provider.dart';
import '../widgets/emergency_warning_card.dart';
import '../widgets/health_answer_card.dart';
import '../widgets/health_input_field.dart';
import '../widgets/health_source_card.dart';
import 'health_article_screen.dart';

class HealthChatScreen extends ConsumerStatefulWidget {
  const HealthChatScreen({super.key});

  @override
  ConsumerState<HealthChatScreen> createState() => _HealthChatScreenState();
}

class _HealthChatScreenState extends ConsumerState<HealthChatScreen> {
  final _controller = TextEditingController();
  static const _suggestions = [
    'জ্বর হলে কী করব?',
    'গর্ভাবস্থায় কী কী খেয়াল রাখব?',
    'কখন ডাক্তারের কাছে যেতে হবে?',
  ];

  @override
  void dispose() {
    ref.read(healthProvider.notifier).stopSpeaking();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    final lastAnswerIndex = state.messages.lastIndexWhere(
      (message) => !message.isUser,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('স্বাস্থ্য সহায়ক')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'আপনার প্রশ্ন লিখুন',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: _suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _controller.text = suggestion;
                      ref.read(healthProvider.notifier).askQuestion(suggestion);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          HealthInputField(
            controller: _controller,
            onSubmitted: (value) =>
                ref.read(healthProvider.notifier).askQuestion(value),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(state.errorMessage!,
                style: const TextStyle(color: AppColors.danger)),
          ],
          if (state.isAsking) ...[
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
          ],
          if (state.messages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...state.messages.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              if (message.isUser) {
                return _UserMessage(text: message.text);
              }

              final answer = message.answer;
              if (answer == null || index != lastAnswerIndex) {
                return _PreviousAnswer(text: message.text);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (answer.isEmergency)
                    EmergencyWarningCard(message: answer.answer),
                  const SizedBox(height: AppSpacing.sm),
                  HealthAnswerCard(
                    answer: answer.answer,
                    isSpeaking: state.isSpeaking,
                    onSpeak: () =>
                        ref.read(healthProvider.notifier).speakAnswer(),
                  ),
                  if (answer.sources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'তথ্যের উৎস',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...answer.sources
                        .map((source) => HealthSourceCard(source: source)),
                  ],
                  if (answer.warnings.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AnswerList(
                      title: 'সতর্কতা',
                      icon: Icons.warning_amber_rounded,
                      items: answer.warnings,
                    ),
                  ],
                  if (answer.nextSteps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AnswerList(
                      title: 'পরবর্তী পদক্ষেপ',
                      icon: Icons.check_circle_outline,
                      items: answer.nextSteps,
                    ),
                  ],
                  if (answer.relatedArticles.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'সম্পর্কিত নিবন্ধ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...answer.relatedArticles.map(
                      (article) => _RelatedArticle(
                        article: article,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HealthArticleScreen(slug: article.slug),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AnswerList extends StatelessWidget {
  const _AnswerList({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('• $item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(text),
        ),
      ),
    );
  }
}

class _PreviousAnswer extends StatelessWidget {
  const _PreviousAnswer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(text),
      ),
    );
  }
}

class _RelatedArticle extends StatelessWidget {
  const _RelatedArticle({required this.article, required this.onTap});

  final HealthArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title:
            Text(article.titleBn.isEmpty ? article.titleEn : article.titleBn),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
