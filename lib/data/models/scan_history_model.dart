import 'dart:convert';
import '../../domain/entities/scan_result.dart';

class ScanHistoryModel extends ScanResult {
  const ScanHistoryModel({
    required super.id,
    required super.content,
    required super.type,
    required super.scannedAt,
    super.isGenerated,
  });

  factory ScanHistoryModel.fromEntity(ScanResult entity) {
    return ScanHistoryModel(
      id: entity.id,
      content: entity.content,
      type: entity.type,
      scannedAt: entity.scannedAt,
      isGenerated: entity.isGenerated,
    );
  }

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScanHistoryModel(
      id: json['id'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      isGenerated: json['isGenerated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type,
        'scannedAt': scannedAt.toIso8601String(),
        'isGenerated': isGenerated,
      };

  static String encodeList(List<ScanHistoryModel> models) =>
      jsonEncode(models.map((m) => m.toJson()).toList());

  static List<ScanHistoryModel> decodeList(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((item) => ScanHistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
