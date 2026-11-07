import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../viewmodels/evidence_provider.dart';
import 'create_incident_screen.dart';
import 'incident_details_screen.dart';

class EvidenceHomeScreen extends ConsumerStatefulWidget {
  const EvidenceHomeScreen({super.key});

  @override
  ConsumerState<EvidenceHomeScreen> createState() => _EvidenceHomeScreenState();
}

class _EvidenceHomeScreenState extends ConsumerState<EvidenceHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(evidenceProvider.notifier).loadIncidents());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence vault')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateIncidentScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New incident'),
      ),
      body: state.loading && state.incidents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.incidents.isEmpty
              ? AppErrorState(
                  title: 'Unable to load incidents',
                  message: state.errorMessage,
                  onRetry: () =>
                      ref.read(evidenceProvider.notifier).loadIncidents(),
                )
              : state.incidents.isEmpty
                  ? const Center(child: Text('No incidents recorded yet.'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(evidenceProvider.notifier).loadIncidents(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.incidents.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          final incident = state.incidents[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.all(AppSpacing.md),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.evidenceIndigoBackground,
                                foregroundColor: AppColors.evidenceIndigo,
                                child: const Icon(Icons.folder_outlined),
                              ),
                              title: Text(
                                incident.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                '${incident.category.replaceAll('_', ' ')} · '
                                '${incident.evidenceItemsCount} evidence item(s)\n'
                                '${_formatDate(incident.createdAt)}',
                              ),
                              trailing: Chip(
                                avatar: const Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                ),
                                label: Text(incident.status),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailsScreen(
                                    incidentId: incident.id,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
