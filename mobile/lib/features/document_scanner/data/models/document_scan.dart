class DocumentScan {
  const DocumentScan({
    required this.id,
    required this.originalName,
    required this.documentType,
    required this.fileSize,
    required this.sha256Hash,
    required this.status,
    required this.extractedTextBytes,
    required this.findings,
    required this.createdAt,
    this.aiExplanation,
  });

  factory DocumentScan.fromJson(Map<String, dynamic> json) {
    // Unnest "data" key if returned from Laravel API wrapper
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return DocumentScan(
      id: data['id'] as int? ?? 0,
      originalName: data['original_name'] as String? ?? data['file_name'] as String? ?? '',
      documentType: data['document_type'] as String? ?? 'pdf',
      fileSize: data['file_size'] as int? ?? 0,
      sha256Hash: data['sha256_hash'] as String? ?? '',
      status: data['status'] as String? ?? 'completed',
      extractedTextBytes: data['extracted_text_bytes'] as int? ?? 0,
      findings: (data['findings'] as List<dynamic>?)
              ?.map((item) => DocumentFinding.fromJson(item as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      createdAt: data['created_at'] as String?,
      aiExplanation: data['ai_explanation'] as String?,
    );
  }

  final int id;
  final String originalName;
  final String documentType;
  final int fileSize;
  final String sha256Hash;
  final String status;
  final int extractedTextBytes;
  final List<DocumentFinding> findings;
  final String? createdAt;
  final String? aiExplanation;
}

class DocumentFinding {
  const DocumentFinding({
    required this.category,
    required this.maskedText,
    required this.start,
    required this.end,
  });

  factory DocumentFinding.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>? ?? {};
    return DocumentFinding(
      category: json['category'] as String? ?? 'unknown',
      maskedText: json['text'] as String? ?? '',
      start: position['start'] as int? ?? 0,
      end: position['end'] as int? ?? 0,
    );
  }

  final String category;
  final String maskedText;
  final int start;
  final int end;
}