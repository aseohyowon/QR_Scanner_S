import 'package:flutter/foundation.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/usecases/get_scan_history.dart';
import '../../domain/usecases/save_scan_result.dart';
import '../../domain/usecases/delete_scan_result.dart';
import '../../domain/usecases/clear_history.dart';

enum HistoryFilter { all, scanned, generated }

class HistoryProvider extends ChangeNotifier {
  final GetScanHistory _getScanHistory;
  final SaveScanResult _saveScanResult;
  final DeleteScanResult _deleteScanResult;
  final ClearHistory _clearHistory;

  List<ScanResult> _history = [];
  bool _isLoading = false;
  String _searchQuery = '';
  HistoryFilter _filter = HistoryFilter.all;

  HistoryProvider({
    required GetScanHistory getScanHistory,
    required SaveScanResult saveScanResult,
    required DeleteScanResult deleteScanResult,
    required ClearHistory clearHistory,
  })  : _getScanHistory = getScanHistory,
        _saveScanResult = saveScanResult,
        _deleteScanResult = deleteScanResult,
        _clearHistory = clearHistory;

  List<ScanResult> get history => _history;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  HistoryFilter get filter => _filter;

  List<ScanResult> get filteredHistory {
    var list = _history;
    // 템 필터
    if (_filter == HistoryFilter.scanned) {
      list = list.where((e) => !e.isGenerated).toList();
    } else if (_filter == HistoryFilter.generated) {
      list = list.where((e) => e.isGenerated).toList();
    }
    // 검색
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.content.toLowerCase().contains(q) ||
              e.type.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilter(HistoryFilter f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await _getScanHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addResult(ScanResult result) async {
    await _saveScanResult(result);
    await loadHistory();
  }

  Future<void> deleteResult(String id) async {
    await _deleteScanResult(id);
    _history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clear() async {
    await _clearHistory();
    _history = [];
    notifyListeners();
  }
}
