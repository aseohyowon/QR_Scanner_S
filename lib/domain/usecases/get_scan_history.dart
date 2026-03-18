import '../entities/scan_result.dart';
import '../repositories/qr_repository.dart';

class GetScanHistory {
  final QrRepository repository;

  const GetScanHistory(this.repository);

  Future<List<ScanResult>> call() => repository.getScanHistory();
}
