class ScanResult {
  final String id;
  final String content;
  final String type;
  final DateTime scannedAt;
  final bool isGenerated;

  const ScanResult({
    required this.id,
    required this.content,
    required this.type,
    required this.scannedAt,
    this.isGenerated = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
