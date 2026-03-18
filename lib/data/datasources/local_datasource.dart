import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_model.dart';

class LocalDataSource {
  static const String _historyKey = 'qr_scan_history';

  final SharedPreferences _prefs;

  LocalDataSource(this._prefs);

  List<ScanHistoryModel> getScanHistory() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      return ScanHistoryModel.decodeList(jsonString);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveScanResult(ScanHistoryModel model) async {
    final history = getScanHistory();
    // Avoid duplicate entries by content (within last minute)
    final isDuplicate = history.any((e) =>
        e.content == model.content &&
        model.scannedAt.difference(e.scannedAt).inMinutes.abs() < 1);
    if (isDuplicate) return;
    history.insert(0, model);
    await _prefs.setString(_historyKey, ScanHistoryModel.encodeList(history));
  }

  Future<void> deleteScanResult(String id) async {
    final history = getScanHistory()..removeWhere((e) => e.id == id);
    await _prefs.setString(_historyKey, ScanHistoryModel.encodeList(history));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
