import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/incident.dart';
import '../../data/repositories/evidence_repository.dart';

final evidenceRepositoryProvider = Provider<EvidenceRepository>(
  (ref) => EvidenceRepository(ApiService()),
);

final evidenceProvider =
    NotifierProvider<EvidenceNotifier, EvidenceState>(EvidenceNotifier.new);

class EvidenceState {
  const EvidenceState({
    this.incidents = const [],
    this.selected,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
  });

  final List<Incident> incidents;
  final Incident? selected;
  final bool loading;
  final bool saving;
  final String? errorMessage;

  EvidenceState copyWith({
    List<Incident>? incidents,
    Incident? selected,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      EvidenceState(
        incidents: incidents ?? this.incidents,
        selected: selected ?? this.selected,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

class EvidenceNotifier extends Notifier<EvidenceState> {
  @override
  EvidenceState build() => const EvidenceState();

  EvidenceRepository get _repository => ref.read(evidenceRepositoryProvider);

  Future<void> loadIncidents() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(
        incidents: await _repository.getIncidents(),
        loading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Unable to load your evidence vault.',
      );
    }
  }

  Future<bool> createIncident({
    required String title,
    required String category,
    required String description,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final incident = await _repository.createIncident(
        title: title,
        category: category,
        description: description,
      );
      state = state.copyWith(
        incidents: [incident, ...state.incidents],
        selected: incident,
        saving: false,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(saving: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Unable to create the incident.',
      );
    }
    return false;
  }

  Future<void> loadIncident(int id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(
        selected: await _repository.getIncidentDetails(id),
        loading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Unable to load this incident.',
      );
    }
  }

  Future<bool> addEvidence({
    required int incidentId,
    required String type,
    String? description,
    String? filename,
    Uint8List? bytes,
    String? path,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final file = PlatformFile(
        name: filename ?? 'evidence',
        size: bytes?.length ?? 0,
        bytes: bytes,
        path: path,
      );
      await _repository.uploadEvidence(
        incidentId,
        file,
        type,
        description,
        onSendProgress: onSendProgress,
      );
      final refreshedIncident =
          await _repository.getIncidentDetails(incidentId);
      state = state.copyWith(
        selected: refreshedIncident,
        saving: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(saving: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Unable to add this evidence.',
      );
    }
    return false;
  }
}
