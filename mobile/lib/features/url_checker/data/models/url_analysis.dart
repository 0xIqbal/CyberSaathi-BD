class UrlAnalysis {
  const UrlAnalysis({
    required this.originalUrl,
    required this.normalizedUrl,
    required this.riskLevel,
    required this.riskScore,
    required this.indicators,
    required this.limitations,
    this.aiExplanation,
  });

  factory UrlAnalysis.fromJson(Map<String, dynamic> json) {
    return UrlAnalysis(
      originalUrl: json['original_url'] as String,
      normalizedUrl: json['normalized_url'] as String,
      riskLevel: json['risk_level'] as String,
      riskScore: json['risk_score'] as int,
      indicators: (json['indicators'] as List<dynamic>)
          .map((item) => UrlIndicator.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      limitations: (json['limitations'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      aiExplanation: json['ai_explanation'] as String?,
    );
  }

  final String originalUrl;
  final String normalizedUrl;
  final String riskLevel;
  final int riskScore;
  final List<UrlIndicator> indicators;
  final List<String> limitations;
  final String? aiExplanation;
}

class UrlIndicator {
  const UrlIndicator({
    required this.code,
    required this.severity,
    required this.confidence,
    required this.description,
  });

  factory UrlIndicator.fromJson(Map<String, dynamic> json) {
    return UrlIndicator(
      code: json['code'] as String,
      severity: json['severity'] as String,
      confidence: json['confidence'] as String,
      description: json['description'] as String,
    );
  }

  final String code;
  final String severity;
  final String confidence;
  final String description;
}