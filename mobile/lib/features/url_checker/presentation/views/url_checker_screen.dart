import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/url_analysis.dart';
import '../viewmodels/url_analysis_provider.dart';

class UrlCheckerScreen extends ConsumerStatefulWidget {
  const UrlCheckerScreen({super.key});

  @override
  ConsumerState<UrlCheckerScreen> createState() => _UrlCheckerScreenState();
}

class _UrlCheckerScreenState extends ConsumerState<UrlCheckerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(urlAnalysisProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('URL Checker')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Check a suspicious link',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('The URL is analyzed without opening or visiting it.'),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
            onSubmitted: (_) => _analyze(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _analyze,
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.security_rounded),
            label: Text(state.isLoading ? 'Analyzing...' : 'Analyze URL'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _MessageCard(
              icon: Icons.error_outline,
              message: state.errorMessage!,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
          if (!state.isLoading &&
              state.errorMessage == null &&
              state.analysis == null) ...[
            const SizedBox(height: AppSpacing.xl),
            const _MessageCard(
              icon: Icons.link_rounded,
              message: 'Enter a URL above to view its risk indicators.',
            ),
          ],
          if (state.analysis != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _AnalysisResult(analysis: state.analysis!),
          ],
        ],
      ),
    );
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    ref.read(urlAnalysisProvider.notifier).analyze(_controller.text);
  }
}

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.analysis});

  final UrlAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final color = switch (analysis.riskLevel) {
      'high' => Theme.of(context).colorScheme.error,
      'medium' => Colors.orange.shade800,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analysis status',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${analysis.riskLevel.toUpperCase()} RISK · ${analysis.riskScore}/100',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(analysis.normalizedUrl),
              ],
            ),
          ),
        ),
        if (analysis.aiExplanation != null &&
            analysis.aiExplanation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'এআই নিরাপত্তা বিশ্লেষণ (AI Insight)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  Text(
                    analysis.aiExplanation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (analysis.indicators.isEmpty)
          const _MessageCard(
            icon: Icons.check_circle_outline,
            message: 'No structural warning indicators were found.',
          )
        else
          ...analysis.indicators.map(
            (indicator) => Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(indicator.code.replaceAll('_', ' ')),
                subtitle: Text(
                  '${indicator.description}\n'
                  'Severity: ${indicator.severity} · Confidence: ${indicator.confidence}',
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Limitations',
                    style: Theme.of(context).textTheme.titleMedium),
                ...analysis.limitations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('• $item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}