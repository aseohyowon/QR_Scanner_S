import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/scan_result.dart';
import '../../core/utils/qr_type_detector.dart';
import 'history_provider.dart';
import 'ad_provider.dart';
import 'package:uuid/uuid.dart';

enum ScanState { idle, scanning, result, error }

class QrScannerProvider extends ChangeNotifier {
  final HistoryProvider _historyProvider;
  final AdProvider _adProvider;
  final _uuid = const Uuid();

  ScanState _state = ScanState.idle;
  ScanResult? _lastResult;
  String? _errorMessage;
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  MobileScannerController? _controller;
  DateTime? _lastScanTime; // 중복 스캔 방지용 디바운스

  QrScannerProvider({
    required HistoryProvider historyProvider,
    required AdProvider adProvider,
  })  : _historyProvider = historyProvider,
        _adProvider = adProvider;

  ScanState get state => _state;
  ScanResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  bool get torchEnabled => _torchEnabled;
  CameraFacing get cameraFacing => _cameraFacing;
  MobileScannerController? get controller => _controller;

  void initController() {
    _controller = MobileScannerController(
      facing: _cameraFacing,
      torchEnabled: _torchEnabled,
    );
    _state = ScanState.scanning;
    notifyListeners();
  }

  void disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> onBarcodeDetected(BarcodeCapture capture) async {
    if (_state != ScanState.scanning) return;

    // 1.5초 내 중복 감지 무시 (debounce)
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
      return;
    }

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _lastScanTime = now;

    // 진동 피드백 (iOS: 햅틱, Android: 진동)
    await HapticFeedback.mediumImpact();

    final content = barcode.rawValue!;
    final type = QrTypeDetector.detect(content);
    final result = ScanResult(
      id: _uuid.v4(),
      content: content,
      type: type,
      scannedAt: DateTime.now(),
    );

    // 결과 즉시 표시 후 저장
    _lastResult = result;
    _state = ScanState.result;
    notifyListeners();

    await _historyProvider.addResult(result);
    await _adProvider.incrementScanCount(); // 3회마다 전면 광고 노출
  }

  void resetScan() {
    _lastResult = null;
    _errorMessage = null;
    _lastScanTime = null; // 디바운스 초기화
    _state = ScanState.scanning;
    notifyListeners();
  }

  Future<void> toggleTorch() async {
    _torchEnabled = !_torchEnabled;
    await _controller?.toggleTorch();
    notifyListeners();
  }

  Future<void> flipCamera() async {
    _cameraFacing = _cameraFacing == CameraFacing.back
        ? CameraFacing.front
        : CameraFacing.back;
    await _controller?.switchCamera();
    notifyListeners();
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}
