import '../entities/scan_result.dart';
import '../repositories/qr_repository.dart';

class SaveScanResult {
  final QrRepository repository;

  const SaveScanResult(this.repository);

  Future<void> call(ScanResult result) => repository.saveScanResult(result);
}
