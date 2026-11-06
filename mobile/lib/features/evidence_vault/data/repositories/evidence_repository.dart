import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_service.dart';
import '../models/evidence_item.dart';
import '../models/incident.dart';

class EvidenceRepository {
  EvidenceRepository(this._api);

  final ApiService _api;

  Future<List<Incident>> getIncidents() async {
    final response = await _api.get('/incidents');
    final data = response['data'];
    final items = data is Map<String, dynamic> ? data['items'] : data;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Incident.fromJson)
        .toList(growable: false);
  }

  Future<Incident> createIncident({
    required String title,
    required String category,
    required String description,
  }) async {
    final response = await _api.post(
      '/incidents',
      body: {
        'title': title,
        'category': category,
        'description': description,
      },
    );
    return Incident.fromJson(response);
  }

  Future<Incident> getIncidentDetails(int id) async {
    final response = await _api.get('/incidents/$id');
    return Incident.fromJson(response);
  }

  Future<EvidenceItem> uploadEvidence(
    int incidentId,
    PlatformFile file,
    String type,
    String description, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final multipartFile = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : file.path != null
            ? MultipartFile.fromFileSync(file.path!, filename: file.name)
            : null;

    if (multipartFile == null && (type == 'image' || type == 'pdf')) {
      throw StateError('The selected file has no readable bytes or path.');
    }

    final response = await _api.multipart(
      '/incidents/$incidentId/evidence',
      fields: {
        'type': type,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        if (multipartFile != null) 'file': multipartFile,
      },
      onSendProgress: onSendProgress,
    );
    return EvidenceItem.fromJson(response);
  }

  Future<List<Incident>> listIncidents() => getIncidents();

  Future<Incident> getIncident(int id) => getIncidentDetails(id);
}
