import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/document_scan.dart';
import '../../data/repositories/document_scan_repository.dart';

final documentScanRepositoryProvider = Provider<DocumentScanRepository>((ref) {
  return DocumentScanRepository(ApiService());
});

final documentScanProvider =
    NotifierProvider<DocumentScanNotifier, DocumentScanState>(
  DocumentScanNotifier.new,
);

class DocumentScanState {
  const DocumentScanState({
    this.file,
    this.isUploading = false,
    this.isScanning = false,
    this.uploadProgress = 0,
    this.scan,
    this.errorMessage,
  });

  final PlatformFile? file;
  final bool isUploading;
  final bool isScanning;
  final double uploadProgress;
  final DocumentScan? scan;
  final String? errorMessage;

  bool get isBusy => isUploading || isScanning;

  DocumentScanState copyWith({
    PlatformFile? file,
    bool? isUploading,
    bool? isScanning,
    double? uploadProgress,
    DocumentScan? scan,
    String? errorMessage,
    bool clearError = false,
    bool clearScan = false,
  }) {
    return DocumentScanState(
      file: file ?? this.file,
      isUploading: isUploading ?? this.isUploading,
      isScanning: isScanning ?? this.isScanning,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      scan: clearScan ? null : scan ?? this.scan,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DocumentScanNotifier extends Notifier<DocumentScanState> {
  @override
  DocumentScanState build() => const DocumentScanState();

  void selectFile(PlatformFile file) {
    state = DocumentScanState(file: file);
  }

  Future<void> scan() async {
    final file = state.file;
    if (file == null) {
      state = const DocumentScanState(
        errorMessage: 'Select a PDF or DOCX file first.',
      );
      return;
    }

    final extension = file.extension?.toLowerCase();
    if (extension != 'pdf' && extension != 'docx') {
      state = state.copyWith(
        errorMessage: 'Only PDF and DOCX files are supported.',
      );
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      state = state.copyWith(
        errorMessage: 'The document must be smaller than 10 MB.',
      );
      return;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0,
      clearError: true,
      clearScan: true,
    );

    try {
      final repository = ref.read(documentScanRepositoryProvider);
      final uploadedScan = await repository.upload(
        name: file.name,
        path: file.path,
        bytes: file.bytes,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      state = state.copyWith(isUploading: false, isScanning: true);
      state = state.copyWith(
        isUploading: false,
        isScanning: false,
        uploadProgress: 1,
        scan: uploadedScan,
      );
    } on ApiException catch (error, stackTrace) {
      print(error);
      print(error.statusCode);
      print(error.code);
      print(error.errors);
      print(stackTrace);
      state = DocumentScanState(file: file, errorMessage: error.message);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
      state = DocumentScanState(
        file: file,
        errorMessage: 'Unable to scan this document right now.',
      );
    }
  }

  void clear() {
    state = const DocumentScanState();
  }
}
