import '../../../../core/network/api_service.dart';
import '../models/health_answer.dart';
import '../models/health_article.dart';

class HealthRepository {
  HealthRepository(this._api);

  final ApiService _api;

  Future<List<String>> getTopics() async {
    final response = await _api.get('/health-navigator/topics');
    final data = response['data'];
    final topics = data is Map<String, dynamic> ? data['topics'] : data;
    return topics is List
        ? topics.whereType<String>().toList(growable: false)
        : const [];
  }

  Future<List<HealthArticle>> getArticles({String? category}) async {
    final path = category == null || category.isEmpty
        ? '/health-navigator/articles'
        : '/health-navigator/articles?category=${Uri.encodeQueryComponent(category)}';
    final response = await _api.get(path);
    final data = response['data'];
    return data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(HealthArticle.fromJson)
            .toList(growable: false)
        : const [];
  }

  Future<HealthArticle> getArticleDetail(String slug) async {
    final response = await _api.get(
      '/health-navigator/articles/${Uri.encodeComponent(slug)}',
    );
    return HealthArticle.fromJson(response);
  }

  Future<HealthAnswer> askQuestion(
    String question, {
    String language = 'bn',
  }) async {
    final response = await _api.post(
      '/health-navigator/ask',
      body: {'question': question, 'language': language},
    );
    return HealthAnswer.fromJson(response);
  }
}
