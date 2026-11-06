import 'evidence_item.dart';
import 'incident_event.dart';

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    this.evidenceItemsCount = 0,
    this.evidenceItems = const [],
    this.events = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String category;
  final String description;
  final String status;
  final int evidenceItemsCount;
  final List<EvidenceItem> evidenceItems;
  final List<IncidentEvent> events;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Incident.fromJson(Map<String, dynamic> source) {
    final json = _unwrap(source);
    return Incident(
      id: _int(json['id']),
      title: _string(json['title']),
      category: _string(json['category'], fallback: 'other'),
      description: _string(json['description']),
      status: _string(json['status'], fallback: 'open'),
      evidenceItemsCount: _int(json['evidence_items_count']),
      evidenceItems: _maps(json['evidence_items'])
          .map(EvidenceItem.fromJson)
          .toList(growable: false),
      events: _maps(json['incident_events'])
          .map(IncidentEvent.fromJson)
          .toList(growable: false),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : json;
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }
}
