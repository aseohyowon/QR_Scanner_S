import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/scan_result.dart';
import '../../core/utils/qr_type_detector.dart';
import 'history_provider.dart';

enum GeneratorState { idle, generated }

class QrGeneratorProvider extends ChangeNotifier {
  final HistoryProvider _historyProvider;
  final _uuid = const Uuid();

  String _inputText = '';
  String _qrData = '';
  GeneratorState _state = GeneratorState.idle;

  QrGeneratorProvider({required HistoryProvider historyProvider})
      : _historyProvider = historyProvider;

  String get inputText => _inputText;
  String get qrData => _qrData;
  GeneratorState get state => _state;
  bool get hasQr => _state == GeneratorState.generated && _qrData.isNotEmpty;

  void updateInput(String value) {
    _inputText = value;
    if (_state == GeneratorState.generated) {
      _state = GeneratorState.idle;
      _qrData = '';
    }
    notifyListeners();
  }

  Future<void> generate() async {
    final text = _inputText.trim();
    if (text.isEmpty) return;

    _qrData = text;
    _state = GeneratorState.generated;
    notifyListeners();

    final type = QrTypeDetector.detect(text);
    final result = ScanResult(
      id: _uuid.v4(),
      content: text,
      type: type,
      scannedAt: DateTime.now(),
      isGenerated: true,
    );
    await _historyProvider.addResult(result);
  }

  void clear() {
    _inputText = '';
    _qrData = '';
    _state = GeneratorState.idle;
    notifyListeners();
  }
}
