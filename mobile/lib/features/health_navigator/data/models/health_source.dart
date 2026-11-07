class HealthSource {
  const HealthSource({
    this.id,
    required this.name,
    required this.url,
    this.sourceType,
    this.publisher,
  });

  final int? id;
  final String name;
  final String url;
  final String? sourceType;
  final String? publisher;

  factory HealthSource.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    return HealthSource(
      id: _int(source['id']),
      name: _string(source['name'], 'Official source'),
      url: _string(source['url']),
      sourceType: _nullable(source['source_type']),
      publisher: _nullable(source['publisher']),
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static String _string(dynamic value, [String fallback = '']) =>
      value is String ? value.trim() : fallback;

  static String? _nullable(dynamic value) {
    final result = _string(value);
    return result.isEmpty ? null : result;
  }
}
