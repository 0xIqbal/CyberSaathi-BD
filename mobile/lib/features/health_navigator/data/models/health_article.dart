import 'health_source.dart';

class HealthArticle {
  const HealthArticle({
    this.id,
    required this.slug,
    required this.titleBn,
    required this.titleEn,
    this.summaryBn = '',
    this.summaryEn = '',
    this.contentBn = '',
    this.contentEn = '',
    this.category = '',
    this.keywords = const [],
    this.sources = const [],
  });

  final int? id;
  final String slug;
  final String titleBn;
  final String titleEn;
  final String summaryBn;
  final String summaryEn;
  final String contentBn;
  final String contentEn;
  final String category;
  final List<String> keywords;
  final List<HealthSource> sources;

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final article = data is Map<String, dynamic> ? data : json;
    return HealthArticle(
      id: _int(article['id']),
      slug: _string(article['slug']),
      titleBn: _string(article['title_bn']),
      titleEn: _string(article['title_en']),
      summaryBn: _string(article['summary_bn']),
      summaryEn: _string(article['summary_en']),
      contentBn: _string(article['content_bn']),
      contentEn: _string(article['content_en']),
      category: _string(article['category']),
      keywords: _strings(article['keywords']),
      sources: _maps(article['sources']).map(HealthSource.fromJson).toList(
            growable: false,
          ),
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static String _string(dynamic value) => value is String ? value.trim() : '';

  static List<String> _strings(dynamic value) => value is List
      ? value
          .whereType<String>()
          .map((item) => item.trim())
          .where(
            (item) => item.isNotEmpty,
          )
          .toList(growable: false)
      : const [];

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];
}
