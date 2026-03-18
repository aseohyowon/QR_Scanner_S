import '../entities/scan_result.dart';

abstract class QrRepository {
  Future<List<ScanResult>> getScanHistory();
  Future<void> saveScanResult(ScanResult result);
  Future<void> deleteScanResult(String id);
  Future<void> clearHistory();
}
