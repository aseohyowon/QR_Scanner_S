import '../repositories/qr_repository.dart';

class DeleteScanResult {
  final QrRepository repository;

  const DeleteScanResult(this.repository);

  Future<void> call(String id) => repository.deleteScanResult(id);
}
