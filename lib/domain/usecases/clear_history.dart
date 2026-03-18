import '../repositories/qr_repository.dart';

class ClearHistory {
  final QrRepository repository;

  const ClearHistory(this.repository);

  Future<void> call() => repository.clearHistory();
}
