import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../data/models/health_source.dart';
import '../providers/health_provider.dart';
import '../widgets/health_source_card.dart';

class HealthArticleScreen extends ConsumerStatefulWidget {
  const HealthArticleScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<HealthArticleScreen> createState() =>
      _HealthArticleScreenState();
}

class _HealthArticleScreenState extends ConsumerState<HealthArticleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(healthProvider.notifier).loadArticle(widget.slug),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    final article = state.selectedArticle;
    return Scaffold(
      appBar: AppBar(title: const Text('Health article')),
      body: state.isLoading && article == null
          ? const Center(child: CircularProgressIndicator())
          : article == null
              ? AppErrorState(
                  title: 'Article unavailable',
                  message: state.errorMessage,
                  onRetry: () => ref
                      .read(healthProvider.notifier)
                      .loadArticle(widget.slug),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(
                      article.titleBn.isEmpty
                          ? article.titleEn
                          : article.titleBn,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (article.titleEn.isNotEmpty &&
                        article.titleBn.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(article.titleEn),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 18),
                      label: Text(article.category.replaceAll('_', ' ')),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MarkdownBody(
                      data: article.contentBn.isEmpty
                          ? article.contentEn
                          : article.contentBn,
                      selectable: true,
                    ),
                    if (article.sources.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Official sources',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...article.sources.map(
                        (source) => _OfficialSource(source: source),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _OfficialSource extends StatelessWidget {
  const _OfficialSource({required this.source});

  final HealthSource source;

  @override
  Widget build(BuildContext context) {
    final label = source.sourceType?.toUpperCase() ?? 'OFFICIAL';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: const Icon(Icons.verified_rounded, size: 18),
          label: Text(label == 'GOVERNMENT' ? 'DGHS / DGFP' : label),
        ),
        HealthSourceCard(source: source),
      ],
    );
  }
}
