import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/url_analysis.dart';
import '../../data/repositories/url_analysis_repository.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final urlAnalysisRepositoryProvider = Provider<UrlAnalysisRepository>((ref) {
  return UrlAnalysisRepository(ref.watch(apiServiceProvider));
});

final urlAnalysisProvider =
    NotifierProvider<UrlAnalysisNotifier, UrlAnalysisState>(
  UrlAnalysisNotifier.new,
);

class UrlAnalysisState {
  const UrlAnalysisState({
    this.isLoading = false,
    this.analysis,
    this.errorMessage,
  });

  final bool isLoading;
  final UrlAnalysis? analysis;
  final String? errorMessage;

  UrlAnalysisState copyWith({
    bool? isLoading,
    UrlAnalysis? analysis,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UrlAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      analysis: analysis ?? this.analysis,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class UrlAnalysisNotifier extends Notifier<UrlAnalysisState> {
  @override
  UrlAnalysisState build() => const UrlAnalysisState();

  Future<void> analyze(String url) async {
    final value = url.trim();
    if (value.isEmpty) {
      state = const UrlAnalysisState(errorMessage: 'Enter a URL to analyze.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final analysis =
          await ref.read(urlAnalysisRepositoryProvider).analyze(value);
      state = UrlAnalysisState(analysis: analysis);
    } on ApiException catch (error) {
      state = UrlAnalysisState(errorMessage: error.message);
    } catch (_) {
      state = const UrlAnalysisState(
        errorMessage: 'Unable to analyze the URL right now.',
      );
    }
  }

  void clear() {
    state = const UrlAnalysisState();
  }
}
