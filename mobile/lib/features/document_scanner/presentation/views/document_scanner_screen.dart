import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_motion.dart';
import '../../data/models/document_scan.dart';
import '../viewmodels/document_scan_provider.dart';

class DocumentScannerScreen extends ConsumerWidget {
  const DocumentScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentScanProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Document Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const PremiumReveal(child: _DocumentIntro()),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Check document privacy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'PDF and DOCX files are scanned for masked sensitive findings.',
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumReveal(
            delay: const Duration(milliseconds: 100),
            child: OutlinedButton.icon(
              onPressed: state.isBusy ? null : () => _pickFile(ref),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Select PDF or DOCX'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.file != null) _SelectedFile(file: state.file!),
          if (state.file == null)
            const _MessageCard(
              message: 'Select a private PDF or DOCX file to begin.',
            ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _MessageCard(
              message: state.errorMessage!,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: state.isBusy || state.file == null
                ? null
                : () => ref.read(documentScanProvider.notifier).scan(),
            icon: state.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined),
            label: Text(
              state.isUploading
                  ? 'Uploading ${(state.uploadProgress * 100).round()}%'
                  : state.isScanning
                      ? 'Scanning...'
                      : 'Scan document',
            ),
          ),
          if (state.isUploading) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: state.uploadProgress),
          ],
          if (state.isScanning) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
          if (state.scan != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _ScanResult(scan: state.scan!),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.path != null || file.bytes != null) {
      ref.read(documentScanProvider.notifier).selectFile(file);
    }
  }
}

class _DocumentIntro extends StatelessWidget {
  const _DocumentIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.documentAmberBackground, Color(0xFFFFFBEB)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: AppColors.documentAmber.withValues(alpha: 0.16),
        ),
      ),
      child: const Row(
        children: [
          PulseIcon(
            icon: Icons.description_rounded,
            color: AppColors.documentAmber,
            size: 34,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Review sensitive content before sharing.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedFile extends StatelessWidget {
  const _SelectedFile({required this.file});

  final PlatformFile file;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(file.name),
        subtitle: Text(_formatBytes(file.size)),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ScanResult extends StatelessWidget {
  const _ScanResult({required this.scan});

  final DocumentScan scan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Scan result', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(scan.status.toUpperCase()),
            subtitle: Text(
              '${scan.documentType.toUpperCase()} · '
              '${scan.extractedTextBytes} extracted bytes',
            ),
          ),
        ),
        if (scan.aiExplanation != null && scan.aiExplanation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'প্রাইভেসি বিশ্লেষণ (AI Advisory)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  Text(
                    scan.aiExplanation!,
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
        if (scan.findings.isEmpty)
          const _MessageCard(
            message: 'No configured sensitive findings were detected.',
          )
        else
          ...scan.findings.map((finding) => _FindingCard(finding: finding)),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final DocumentFinding finding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(finding.category.replaceAll('_', ' ')),
        subtitle: Text(
          '${finding.maskedText}\nPosition: ${finding.start}-${finding.end}',
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
