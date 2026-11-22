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

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthChatScreen()),
    );
  }

  void _openArticle(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HealthArticleScreen(slug: slug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    final articles = state.filteredArticles;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.emeraldTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.emerald,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Health Navigator',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _openChat,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('AI সহায়ক'),
            ),
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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.xl * 1.5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Centered Bold Editorial Header (Video 00:00)
                              const PremiumReveal(
                                child: _EditorialHeader(),
                              ),
                              const SizedBox(height: 24),

                              // 2. Icon-Topped Category Bar (Video 00:00)
                              _IconCategoryBar(
                                topics: state.topics,
                                activeCategory: state.activeCategory,
                                onSelected: (category) => ref
                                    .read(healthProvider.notifier)
                                    .selectCategory(category),
                              ),
                              const SizedBox(height: 24),

                              // 3. Featured Spotlight Card + Rolling Ticker (Video 00:01-00:02)
                              PremiumReveal(
                                delay: const Duration(milliseconds: 60),
                                child: _FeaturedSpotlightBanner(
                                  featuredArticle:
                                      articles.isNotEmpty ? articles.first : null,
                                  onAskAi: _openChat,
                                  onOpenArticle: articles.isNotEmpty
                                      ? () => _openArticle(articles.first.slug)
                                      : _openChat,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 4. Sleek Search Input Bar
                              TextField(
                                controller: _searchController,
                                onChanged: ref
                                    .read(healthProvider.notifier)
                                    .filterArticles,
                                decoration: InputDecoration(
                                  hintText:
                                      'স্বাস্থ্য তথ্য, রোগ বা লক্ষণ খুঁজুন...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.emerald,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.forestSurface,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: const BorderSide(
                                      color: AppColors.forestBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: const BorderSide(
                                      color: AppColors.forestBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: const BorderSide(
                                      color: AppColors.emerald,
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (articles.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: AppColors.forestSurface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.forestBorder,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'কোনো নিবন্ধ পাওয়া যায়নি।',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                // 5. "Recommended for You" 3-Column Bento Grid (Video 00:04-00:05)
                                _SectionTitleRow(
                                  eyebrow: 'Recommended for You',
                                  title: 'প্রস্তাবিত স্বাস্থ্য নির্দেশিকা',
                                  count: articles.length,
                                ),
                                const SizedBox(height: 16),
                                _RecommendedBentoRow(
                                  articles: articles.take(3).toList(),
                                  onTapArticle: _openArticle,
                                ),

                                // 6. 2-Column Featured Visual Cards (Video 00:07-00:08)
                                if (articles.length > 3) ...[
                                  const SizedBox(height: 36),
                                  const _SectionTitleRow(
                                    eyebrow: 'Featured Advisories',
                                    title: 'বিশেষ স্বাস্থ্য সতর্কতা ও সচেতনতা',
                                  ),
                                  const SizedBox(height: 16),
                                  _FeaturedVisualPair(
                                    articles: articles.skip(3).take(2).toList(),
                                    onTapArticle: _openArticle,
                                  ),
                                ],

                                // 7. 3-Column "Our Quality" Trust Strip (Video 00:09)
                                const SizedBox(height: 36),
                                const _QualityAssuranceStrip(),

                                // 8. Asymmetric Bento Showcase + Remaining Articles (Video 00:11-00:12)
                                if (articles.length > 5) ...[
                                  const SizedBox(height: 36),
                                  const _SectionTitleRow(
                                    eyebrow: 'Knowledge Library',
                                    title: 'সম্পূর্ণ স্বাস্থ্য তথ্যভাণ্ডার',
                                  ),
                                  const SizedBox(height: 16),
                                  _AsymmetricBentoSection(
                                    articles: articles.skip(5).toList(),
                                    onTapArticle: _openArticle,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emeraldTint,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'VERIFIED HEALTH & CLINICAL GUIDANCE',
            style: TextStyle(
              color: AppColors.emerald,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'বিশ্বস্ত স্বাস্থ্য তথ্য',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: isWide ? 40 : 30,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ),
        Text(
          'আপনার ও পরিবারের সুরক্ষায়',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.emerald,
            fontSize: isWide ? 40 : 30,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _IconCategoryBar extends StatelessWidget {
  const _IconCategoryBar({
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
          _CategoryIconCard(
            icon: Icons.grid_view_rounded,
            label: 'সব তথ্য',
            selected: activeCategory == null,
            onTap: () => onSelected(null),
          ),
          ...visible.map(
            (topic) => _CategoryIconCard(
              icon: _topicIcon(topic),
              label: _shortTopicLabel(topic),
              selected: activeCategory == topic,
              onTap: () => onSelected(topic),
            ),
          ),
        ],
      ),
    );
  }

  IconData _topicIcon(String topic) {
    final lower = topic.toLowerCase();
    if (lower.contains('cardio')) return Icons.favorite_border_rounded;
    if (lower.contains('zoonotic')) return Icons.pets_outlined;
    if (lower.contains('liver')) return Icons.medical_information_outlined;
    if (lower.contains('water') || lower.contains('food')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('mosquito')) return Icons.bug_report_outlined;
    if (lower.contains('pregnancy')) return Icons.pregnant_woman_rounded;
    return Icons.health_and_safety_outlined;
  }

  String _shortTopicLabel(String topic) {
    final cleaned = topic
        .replaceAll('Non-communicable Disease — ', '')
        .replaceAll('Infectious Disease — ', '')
        .replaceAll('_', ' ');
    return cleaned.isEmpty ? topic : cleaned;
  }
}

class _CategoryIconCard extends StatelessWidget {
  const _CategoryIconCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.emeraldTint : AppColors.forestSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.emerald : AppColors.forestBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.emerald : AppColors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.emerald : AppColors.text,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedSpotlightBanner extends StatelessWidget {
  const _FeaturedSpotlightBanner({
    required this.featuredArticle,
    required this.onAskAi,
    required this.onOpenArticle,
  });

  final HealthArticle? featuredArticle;
  final VoidCallback onAskAi;
  final VoidCallback onOpenArticle;

  @override
  Widget build(BuildContext context) {
    final title = featuredArticle == null
        ? 'আপনার স্বাস্থ্য প্রশ্ন করুন, তাৎক্ষণিক নিরাপদ উত্তর পান'
        : (featuredArticle!.titleBn.isEmpty
            ? featuredArticle!.titleEn
            : featuredArticle!.titleBn);
    final summary = featuredArticle == null
        ? 'বাংলাদেশ ও আন্তর্জাতিক চিকিৎসা নির্দেশিকার আলোকে সহজ বাংলায় পরামর্শ।'
        : (featuredArticle!.summaryBn.isEmpty
            ? featuredArticle!.summaryEn
            : featuredArticle!.summaryBn);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.45)),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2D1963),
            Color(0xFF1B113D),
            Color(0xFF0F0B21),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [AppColors.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 740;
                final leftContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: const Text(
                            'AI HEALTH ASSIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '24/7 বাংলা ও বাংলিশ সাপোর্ট',
                          style: TextStyle(
                            color: Color(0xFFDDD6FE),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onAskAi,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                          label: const Text('স্বাস্থ্য সহায়ককে জিজ্ঞাসা করুন'),
                        ),
                        if (featuredArticle != null)
                          OutlinedButton.icon(
                            onPressed: onOpenArticle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.menu_book_rounded,
                              size: 17,
                            ),
                            label: const Text('বিস্তারিত পড়ুন'),
                          ),
                      ],
                    ),
                  ],
                );

                final visualBadge = Container(
                  width: isWide ? 210 : double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: AppColors.emerald,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Clinical Reference',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'IEDCR • DGHS • WHO',
                        style: TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: leftContent),
                      const SizedBox(width: 24),
                      visualBadge,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftContent,
                    const SizedBox(height: 18),
                    visualBadge,
                  ],
                );
              },
            ),
          ),
          // Bottom Ticker Strip matching video 00:01-00:02
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.black.withValues(alpha: 0.38),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _TickerChip(text: 'IEDCR VERIFIED'),
                  _TickerDot(),
                  _TickerChip(text: 'BANGLA & BANGLISH AI'),
                  _TickerDot(),
                  _TickerChip(text: 'EMERGENCY WARNING DETECTION'),
                  _TickerDot(),
                  _TickerChip(text: 'ZERO PRESCRIPTION HALLUCINATION'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerChip extends StatelessWidget {
  const _TickerChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFDDD6FE),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _TickerDot extends StatelessWidget {
  const _TickerDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Icon(Icons.circle, size: 5, color: AppColors.emerald),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.eyebrow,
    required this.title,
    this.count,
  });

  final String eyebrow;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.forestSurface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.forestBorder),
            ),
            child: Text(
              '$count টি নিবন্ধ',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _RecommendedBentoRow extends StatelessWidget {
  const _RecommendedBentoRow({
    required this.articles,
    required this.onTapArticle,
  });

  final List<HealthArticle> articles;
  final ValueChanged<String> onTapArticle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 600 ? 2 : 1);
        return GridView.builder(
          itemCount: articles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 295,
          ),
          itemBuilder: (context, index) {
            final article = articles[index];
            return _BentoArticleCard(
              article: article,
              variantIndex: index,
              onTap: () => onTapArticle(article.slug),
            );
          },
        );
      },
    );
  }
}

class _BentoArticleCard extends StatelessWidget {
  const _BentoArticleCard({
    required this.article,
    required this.variantIndex,
    required this.onTap,
  });

  final HealthArticle article;
  final int variantIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _cardVisualStyle(variantIndex);
    final title =
        article.titleBn.isEmpty ? article.titleEn : article.titleBn;
    final summary =
        article.summaryBn.isEmpty ? article.summaryEn : article.summaryBn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.forestSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.forestBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: style.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          style.tag,
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Visual Illustration Panel at Bottom (matching Video 00:04-00:05)
            Container(
              height: 104,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: style.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: style.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style.visualHeadline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          style.visualSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: style.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CardVisualSpec _cardVisualStyle(int index) {
    final mod = index % 3;
    if (mod == 0) {
      return const _CardVisualSpec(
        tag: 'CLINICAL GUIDE',
        accent: AppColors.emerald,
        gradient: [Color(0xFF2B185E), Color(0xFF160E30)],
        icon: Icons.favorite_rounded,
        visualHeadline: 'লক্ষণ ও প্রতিরোধ',
        visualSub: 'বিস্তারিত নির্দেশিকা পড়ুন',
      );
    }
    if (mod == 1) {
      return const _CardVisualSpec(
        tag: 'PUBLIC HEALTH',
        accent: AppColors.cyan,
        gradient: [Color(0xFF0C3442), Color(0xFF081D26)],
        icon: Icons.shield_outlined,
        visualHeadline: 'সতর্কতা ও করণীয়',
        visualSub: 'বিশেষজ্ঞ পর্যালোচিত তথ্য',
      );
    }
    return const _CardVisualSpec(
      tag: 'SAFE CARE',
      accent: AppColors.warning,
      gradient: [Color(0xFF382A0E), Color(0xFF1F1708)],
      icon: Icons.health_and_safety_rounded,
      visualHeadline: 'চিকিৎসকের পরামর্শ',
      visualSub: 'কখন জরুরি সেবা নেবেন',
    );
  }
}

class _CardVisualSpec {
  const _CardVisualSpec({
    required this.tag,
    required this.accent,
    required this.gradient,
    required this.icon,
    required this.visualHeadline,
    required this.visualSub,
  });

  final String tag;
  final Color accent;
  final List<Color> gradient;
  final IconData icon;
  final String visualHeadline;
  final String visualSub;
}

class _FeaturedVisualPair extends StatelessWidget {
  const _FeaturedVisualPair({
    required this.articles,
    required this.onTapArticle,
  });

  final List<HealthArticle> articles;
  final ValueChanged<String> onTapArticle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final cards = articles.asMap().entries.map((entry) {
          final idx = entry.key;
          final article = entry.value;
          final isFirst = idx == 0;
          final title =
              article.titleBn.isEmpty ? article.titleEn : article.titleBn;
          final summary =
              article.summaryBn.isEmpty ? article.summaryEn : article.summaryBn;

          return InkWell(
            onTap: () => onTapArticle(article.slug),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isFirst
                      ? const [Color(0xFF331C70), Color(0xFF170F33)]
                      : const [Color(0xFF103B52), Color(0xFF091D29)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: (isFirst ? AppColors.emerald : AppColors.cyan)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          isFirst ? 'PRIORITY ADVISORY' : 'INFECTION CONTROL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isFirst
                            ? Icons.health_and_safety_rounded
                            : Icons.water_drop_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: const [
                      Text(
                        'সম্পূর্ণ নিবন্ধ পড়ুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList();

        if (isWide && cards.length == 2) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _QualityAssuranceStrip extends StatelessWidget {
  const _QualityAssuranceStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.forestSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.forestBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          const items = [
            _QualityItem(
              icon: Icons.verified_outlined,
              accent: AppColors.emerald,
              title: 'যাচাইকৃত চিকিৎসা সূত্র',
              subtitle: 'IEDCR, DGHS ও বিশ্ব স্বাস্থ্য সংস্থার তথ্যের ভিত্তিতে তৈরি।',
            ),
            _QualityItem(
              icon: Icons.notifications_active_outlined,
              accent: AppColors.cyan,
              title: 'জরুরি সতর্কতা শনাক্তকরণ',
              subtitle: 'বিপদজনক লক্ষণ দেখা দিলে দ্রুত ডাক্তারের পরামর্শের নির্দেশনা।',
            ),
            _QualityItem(
              icon: Icons.lock_outline_rounded,
              accent: AppColors.warning,
              title: 'নিরাপদ ও গোপনীয়',
              subtitle: 'কোনো অপ্রয়োজনীয় ব্যক্তিগত তথ্য সংরক্ষণ করা হয় না।',
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: item,
                        ),
                      ))
                  .toList(),
            );
          }
          return Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: item,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _QualityItem extends StatelessWidget {
  const _QualityItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AsymmetricBentoSection extends StatelessWidget {
  const _AsymmetricBentoSection({
    required this.articles,
    required this.onTapArticle,
  });

  final List<HealthArticle> articles;
  final ValueChanged<String> onTapArticle;

  @override
  Widget build(BuildContext context) {
    final topThree = articles.take(3).toList();
    final rest = articles.skip(3).toList();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 780;
            if (isWide && topThree.length >= 3) {
              return SizedBox(
                height: 310,
                child: Row(
                  children: [
                    // Tall Left Bento Card (Video 00:11)
                    Expanded(
                      flex: 5,
                      child: _TallBentoCard(
                        article: topThree[0],
                        onTap: () => onTapArticle(topThree[0].slug),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Two Stacked Right Bento Cards (Video 00:11)
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            child: _CompactBentoCard(
                              article: topThree[1],
                              accent: AppColors.warning,
                              onTap: () => onTapArticle(topThree[1].slug),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _CompactBentoCard(
                              article: topThree[2],
                              accent: AppColors.danger,
                              onTap: () => onTapArticle(topThree[2].slug),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: topThree
                  .map((article) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CompactBentoCard(
                          article: article,
                          accent: AppColors.emerald,
                          onTap: () => onTapArticle(article.slug),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RecommendedBentoRow(
            articles: rest,
            onTapArticle: onTapArticle,
          ),
        ],
      ],
    );
  }
}

class _TallBentoCard extends StatelessWidget {
  const _TallBentoCard({required this.article, required this.onTap});

  final HealthArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        article.titleBn.isEmpty ? article.titleEn : article.titleBn;
    final summary =
        article.summaryBn.isEmpty ? article.summaryEn : article.summaryBn;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F183D), Color(0xFF110D24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emerald,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const Text(
                'ESSENTIAL GUIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const Spacer(),
            Row(
              children: const [
                Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.emerald,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'বিস্তারিত গাইড দেখুন',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.emerald,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBentoCard extends StatelessWidget {
  const _CompactBentoCard({
    required this.article,
    required this.accent,
    required this.onTap,
  });

  final HealthArticle article;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        article.titleBn.isEmpty ? article.titleEn : article.titleBn;
    final summary =
        article.summaryBn.isEmpty ? article.summaryEn : article.summaryBn;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.forestSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.forestBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'HEALTH ALERT',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                color: accent,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}