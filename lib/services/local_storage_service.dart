import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/historical_record.dart';

class LocalStorageService {
  static const String historyKey = 'prediction_history';

  static Future<LocalStorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  final SharedPreferences _prefs;

  LocalStorageService._(this._prefs);

  Future<void> saveHistoricalRecord(HistoricalRecord record) async {
    List<String> history = _prefs.getStringList(historyKey) ?? [];
    history.insert(
        0, jsonEncode(record.toJson())); // Add new record at the beginning
    await _prefs.setStringList(historyKey, history);
  }

  Future<List<HistoricalRecord>> getHistory() async {
    final history = _prefs.getStringList(historyKey) ?? [];
    return history
        .map((record) => HistoricalRecord.fromJson(jsonDecode(record)))
        .toList();
  }

  Future<void> clearHistory() async {
    await _prefs.remove(historyKey);
  }

  static init() {}
}
