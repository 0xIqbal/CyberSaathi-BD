class IncidentEvent {
  const IncidentEvent({
    required this.id,
    required this.eventType,
    required this.description,
    this.occurredAt,
  });

  final int id;
  final String eventType;
  final String description;
  final DateTime? occurredAt;

  factory IncidentEvent.fromJson(Map<String, dynamic> source) {
    final json = _unwrap(source);
    return IncidentEvent(
      id: _int(json['id']),
      eventType:
          json['event_type'] is String ? json['event_type'] as String : 'event',
      description:
          json['description'] is String ? json['description'] as String : '',
      occurredAt: _date(json['occurred_at']),
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
