import '../../../../core/network/api_service.dart';
import '../models/url_analysis.dart';

class UrlAnalysisRepository {
  UrlAnalysisRepository(this._api);

  final ApiService _api;

  Future<UrlAnalysis> analyze(String url) async {
    final response = await _api.post(
      '/url-analyses',
      body: {'url': url},
    );
    return UrlAnalysis.fromJson(response['data'] as Map<String, dynamic>);
  }
}
