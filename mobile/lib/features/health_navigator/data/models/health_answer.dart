import 'health_article.dart';
import 'health_source.dart';

class HealthAnswer {
  const HealthAnswer({
    required this.answer,
    required this.isEmergency,
    this.language = 'bn',
    this.responseType = 'health',
    this.sources = const [],
    this.relatedArticles = const [],
    this.warnings = const [],
    this.nextSteps = const [],
  });

  final String answer;
  final bool isEmergency;
  final String language;
  final String responseType;
  final List<HealthSource> sources;
  final List<HealthArticle> relatedArticles;
  final List<String> warnings;
  final List<String> nextSteps;

  factory HealthAnswer.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final answer = data is Map<String, dynamic> ? data : json;
    return HealthAnswer(
      answer: answer['answer'] is String ? answer['answer'] as String : '',
      isEmergency: answer['is_emergency'] == true,
      language:
          answer['language'] is String ? answer['language'] as String : 'bn',
      responseType: answer['response_type'] is String
          ? answer['response_type'] as String
          : 'health',
      sources: _maps(answer['sources']).map(HealthSource.fromJson).toList(
            growable: false,
          ),
      relatedArticles: _maps(answer['related_articles'])
          .map(HealthArticle.fromJson)
          .toList(growable: false),
      warnings: _strings(answer['warnings']),
      nextSteps: _strings(answer['next_steps']),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
