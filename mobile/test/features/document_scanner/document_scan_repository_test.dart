import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_saathi_bd/core/network/api_service.dart';
import 'package:cyber_saathi_bd/features/document_scanner/data/repositories/document_scan_repository.dart';

void main() {
  test('uploads with the document field and retrieves the scan', () async {
    final api = _FakeApiService();
    final repository = DocumentScanRepository(api);

    final result = await repository.upload(
      name: 'sample.pdf',
      path: null,
      bytes: Uint8List.fromList([1, 2, 3]),
      onSendProgress: (_, __) {},
    );

    expect(api.uploadedField, 'document');
    expect(api.uploadedFileName, 'sample.pdf');
    expect(result.id, 12);
    expect(result.findings.single.maskedText, 'te***@example.com');
  });
}

class _FakeApiService extends ApiService {
  String? uploadedField;
  String? uploadedFileName;

  @override
  Future<Map<String, dynamic>> upload(
    String path, {
    required MultipartFile file,
    required String fieldName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    uploadedField = fieldName;
    uploadedFileName = file.filename;
    return {'data': _payload};
  }

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    return {'data': _payload};
  }

  static const _payload = {
    'id': 12,
    'original_name': 'sample.pdf',
    'document_type': 'pdf',
    'file_size': 3,
    'sha256_hash': 'hash',
    'status': 'completed',
    'extracted_text_bytes': 3,
    'findings': [
      {
        'category': 'email',
        'text': 'te***@example.com',
        'position': {'start': 0, 'end': 18},
      },
    ],
    'created_at': null,
  };
}
