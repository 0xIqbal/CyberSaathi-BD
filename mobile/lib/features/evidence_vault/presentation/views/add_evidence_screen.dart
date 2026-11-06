import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../viewmodels/evidence_provider.dart';

class AddEvidenceScreen extends ConsumerStatefulWidget {
  const AddEvidenceScreen({required this.incidentId, super.key});

  final int incidentId;

  @override
  ConsumerState<AddEvidenceScreen> createState() => _AddEvidenceScreenState();
}

class _AddEvidenceScreenState extends ConsumerState<AddEvidenceScreen> {
  final _description = TextEditingController();
  String _type = 'note';
  PlatformFile? _file;
  double _progress = 0;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add evidence')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Evidence type'),
            items: const ['image', 'pdf', 'url', 'note']
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _type = value!;
              _file = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_type == 'image' || _type == 'pdf')
            OutlinedButton.icon(
              onPressed: state.saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(_file?.name ?? 'Choose file'),
            ),
          if (_file != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${_file!.name} · ${_file!.size} bytes'),
          ],
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: _type == 'url' ? 'URL' : 'Description or note',
            ),
          ),
          if (state.saving) ...[
            const SizedBox(height: AppSpacing.lg),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: state.saving ? null : _submit,
            child: const Text('Save evidence'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _type == 'pdf' ? ['pdf'] : ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.single);
    }
  }

  Future<void> _submit() async {
    if ((_type == 'image' || _type == 'pdf') && _file == null) {
      _showMessage('Choose a file first.');
      return;
    }
    if (_type == 'url' && !_description.text.trim().startsWith('http')) {
      _showMessage('Enter a valid URL beginning with http or https.');
      return;
    }
    final file = _file;
    final saved = await ref.read(evidenceProvider.notifier).addEvidence(
          incidentId: widget.incidentId,
          type: _type,
          description: _description.text,
          filename: file?.name,
          bytes: file?.bytes,
          path: file?.path,
          onSendProgress: (sent, total) {
            if (total > 0 && mounted) setState(() => _progress = sent / total);
          },
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
