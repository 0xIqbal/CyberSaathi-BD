import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../models/document_scan.dart';

class DocumentScanRepository {
  DocumentScanRepository(this._api);

  final ApiService _api;

  Future<DocumentScan> upload({
    required String name,
    required String? path,
    required Uint8List? bytes,
    required void Function(int sent, int total) onSendProgress,
  }) async {
    try {
      final multipartFile = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: name)
          : MultipartFile.fromFileSync(path!, filename: name);
      final response = await _api.upload(
        '/document-scans',
        fieldName: 'document',
        file: multipartFile,
        onSendProgress: onSendProgress,
      );
      final data = response['data'] as Map<String, dynamic>;
      return DocumentScan.fromJson(data);
    } on ApiException catch (error) {
      print(error.toString());
      print(error.errors);
      rethrow;
    } on DioException catch (error) {
      print(error.toString());
      print(error.response?.data);
      rethrow;
    }
  }

  Future<DocumentScan> get(int id) async {
    final response = await _api.get('/document-scans/$id');
    return DocumentScan.fromJson(response['data'] as Map<String, dynamic>);
  }
}
