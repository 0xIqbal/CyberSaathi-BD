import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../data/models/incident_event.dart';
import '../viewmodels/evidence_provider.dart';
import 'add_evidence_screen.dart';

class IncidentDetailsScreen extends ConsumerStatefulWidget {
  const IncidentDetailsScreen({required this.incidentId, super.key});

  final int incidentId;

  @override
  ConsumerState<IncidentDetailsScreen> createState() =>
      _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends ConsumerState<IncidentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(evidenceProvider.notifier).loadIncident(widget.incidentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceProvider);
    final incident = state.selected;
    return Scaffold(
      appBar: AppBar(title: Text(incident?.title ?? 'Incident')),
      floatingActionButton: incident == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEvidenceScreen(incidentId: incident.id),
                ),
              ),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Add evidence'),
            ),
      body: state.loading && incident == null
          ? const Center(child: CircularProgressIndicator())
          : incident == null
              ? AppErrorState(
                  title: 'Unable to load incident',
                  message: state.errorMessage,
                  onRetry: () => ref
                      .read(evidenceProvider.notifier)
                      .loadIncident(widget.incidentId),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(evidenceProvider.notifier)
                      .loadIncident(widget.incidentId),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(incident.category.replaceAll('_', ' '),
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: AppSpacing.xs),
                              Text(incident.description),
                              const SizedBox(height: AppSpacing.sm),
                              Chip(label: Text(incident.status)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Evidence',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      if (incident.evidenceItems.isEmpty)
                        const Text('No evidence added yet.')
                      else
                        ...incident.evidenceItems.map(
                          (item) => Card(
                            child: ListTile(
                              leading: Icon(_iconFor(item.type)),
                              title: Text(item.originalName ?? item.type),
                              subtitle: Text(
                                [
                                  if (item.description?.isNotEmpty ?? false)
                                    item.description!,
                                  if (item.sha256Hash?.isNotEmpty ?? false)
                                    'SHA-256: ${item.sha256Hash}',
                                ].join('\n'),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Timeline',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      if (incident.events.isEmpty)
                        const Text('No timeline events yet.')
                      else
                        ...incident.events.asMap().entries.map(
                              (entry) => _TimelineItem(
                                event: entry.value,
                                isLast: entry.key == incident.events.length - 1,
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'image' => Icons.image_outlined,
        'pdf' => Icons.picture_as_pdf_outlined,
        'url' => Icons.link_rounded,
        _ => Icons.notes_rounded,
      };
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.isLast});

  final IncidentEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const Icon(Icons.circle, size: 12),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.description),
                  subtitle: Text(
                    '${event.eventType.replaceAll('_', ' ')}'
                    '${event.occurredAt == null ? '' : ' · ${event.occurredAt}'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
