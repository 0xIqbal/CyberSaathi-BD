import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/premium_motion.dart';
import '../../data/models/health_article.dart';
import '../providers/health_provider.dart';
import 'health_article_screen.dart';
import 'health_chat_screen.dart';

class HealthHomeScreen extends ConsumerStatefulWidget {
  const HealthHomeScreen({super.key});

  @override
  ConsumerState<HealthHomeScreen> createState() => _HealthHomeScreenState();
}

class _HealthHomeScreenState extends ConsumerState<HealthHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProvider.notifier).loadHome());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Navigator'),
        actions: [
          IconButton(
            tooltip: 'Ask a question',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthChatScreen()),
            ),
            icon: const Icon(Icons.chat_rounded),
          ),
        ],
      ),
      body: state.isLoading && state.articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.articles.isEmpty
              ? AppErrorState(
                  title: 'Unable to load health information',
                  message: state.errorMessage,
                  onRetry: () => ref.read(healthProvider.notifier).loadHome(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(healthProvider.notifier).loadHome(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      PremiumReveal(
                        child: _HeroCard(
                          onAsk: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HealthChatScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _searchController,
                        onChanged:
                            ref.read(healthProvider.notifier).filterArticles,
                        decoration: const InputDecoration(
                          hintText: 'স্বাস্থ্য তথ্য খুঁজুন',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CategoryGrid(
                        topics: state.topics,
                        activeCategory: state.activeCategory,
                        onSelected: (category) => ref
                            .read(healthProvider.notifier)
                            .selectCategory(category),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'সাম্প্রতিক স্বাস্থ্য তথ্য',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.filteredArticles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child:
                              Center(child: Text('কোনো নিবন্ধ পাওয়া যায়নি।')),
                        )
                      else
                        ...state.filteredArticles.map(
                          (article) => PremiumReveal(
                            delay: const Duration(milliseconds: 70),
                            child: _ArticleTile(
                              article: article,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HealthArticleScreen(
                                    slug: article.slug,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navy950, AppColors.teal700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety,
                  color: AppColors.teal100, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'বিশ্বস্ত স্বাস্থ্য তথ্য, সহজ ভাষায়',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'নিরাপদ স্বাস্থ্য নির্দেশনা পেতে আপনার প্রশ্ন করুন। এটি চিকিৎসকের বিকল্প নয়।',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onAsk,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('স্বাস্থ্য সহায়ককে জিজ্ঞাসা করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.topics,
    required this.activeCategory,
    required this.onSelected,
  });

  final List<String> topics;
  final String? activeCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final visible = topics.isEmpty
        ? const ['pregnancy', 'medical_tests', 'doctor_navigation']
        : topics;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('সব'),
            selected: activeCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          ...visible.map(
            (topic) => FilterChip(
              avatar: const Icon(Icons.topic_outlined, size: 18),
              label: Text(_topicLabel(topic)),
              selected: activeCategory == topic,
              onSelected: (_) => onSelected(topic),
            ),
          ),
        ],
      ),
    );
  }

  String _topicLabel(String topic) {
    return switch (topic) {
      'pregnancy' => 'Pregnancy Care',
      'medical_tests' => 'Medical Tests',
      'doctor_navigation' => 'Doctor Navigation',
      _ => topic.replaceAll('_', ' '),
    };
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.onTap});

  final HealthArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          article.titleBn.isEmpty ? article.titleEn : article.titleBn,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(
          article.summaryBn.isEmpty ? article.summaryEn : article.summaryBn,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: const BoxDecoration(
            color: AppColors.teal50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.teal700,
          ),
        ),
      ),
    );
  }
}
