import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/local_datasource.dart';
import '../models/scan_history_model.dart';

class QrRepositoryImpl implements QrRepository {
  final LocalDataSource localDataSource;

  const QrRepositoryImpl(this.localDataSource);

  @override
  Future<List<ScanResult>> getScanHistory() async {
    return localDataSource.getScanHistory();
  }

  @override
  Future<void> saveScanResult(ScanResult result) async {
    final model = ScanHistoryModel.fromEntity(result);
    await localDataSource.saveScanResult(model);
  }

  @override
  Future<void> deleteScanResult(String id) async {
    await localDataSource.deleteScanResult(id);
  }

  @override
  Future<void> clearHistory() async {
    await localDataSource.clearHistory();
  }
}
