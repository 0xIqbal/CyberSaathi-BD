class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.type,
    this.originalName,
    this.sha256Hash,
    this.description,
    this.createdAt,
  });

  final int id;
  final String type;
  final String? originalName;
  final String? sha256Hash;
  final String? description;
  final DateTime? createdAt;

  factory EvidenceItem.fromJson(Map<String, dynamic> source) {
    final json = _unwrap(source);
    return EvidenceItem(
      id: _int(json['id']),
      type: json['type'] is String ? json['type'] as String : 'note',
      originalName: json['original_name'] as String?,
      sha256Hash: json['sha256_hash'] as String?,
      description: json['description'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : json;
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
