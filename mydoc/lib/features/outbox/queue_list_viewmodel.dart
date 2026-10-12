
import 'package:flutter/material.dart';
import '../../model/pending_consultation.dart';
import '../../utils/hive_storage.dart';
import '../../repository/Repository.dart'; // 🚩 Import your repository


class OutboxViewModel extends ChangeNotifier {
  final Repository _repo = Repository();
  List<MapEntry<dynamic, PendingConsultation>> _outboxItems = [];
  List<MapEntry<dynamic, PendingConsultation>> get outboxItems => _outboxItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic _checkingKey;
  dynamic get checkingKey => _checkingKey;

  Future<bool> isServerAvailable(dynamic key) async {
    _checkingKey = key;
    notifyListeners();
    bool result = await _repo.checkServerHealth();
    _checkingKey = null;
    notifyListeners();
    return result;
  }

  void fetchOutbox() {
    _isLoading = true;
    final Map<dynamic, PendingConsultation> map = HiveStorage.getOutboxMap();

    // 🚩 FIX: Removed the ".where((e) => !e.value.isSyncing)" filter.
    // This ensures that even if a sync was interrupted, it shows in the list.
    _outboxItems = map.entries.toList();

    // Sort by most recent first
    _outboxItems.sort((a, b) => b.value.startTime.compareTo(a.value.startTime));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteConsultation(dynamic key) async {
    await HiveStorage.removeFromOutbox(key);
    fetchOutbox();
  }
}



// import 'package:flutter/material.dart';
// import '../../model/pending_consultation.dart';
// import '../../utils/hive_storage.dart';
// import '../../repository/Repository.dart'; // 🚩 Import your repository
//
// class OutboxViewModel extends ChangeNotifier {
//   final Repository _repo = Repository(); // 🚩 Create instance
//
//   List<MapEntry<dynamic, PendingConsultation>> _outboxItems = [];
//   List<MapEntry<dynamic, PendingConsultation>> get outboxItems => _outboxItems;
//
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;
//
//   /// 🚩 Check if the server is healthy
//   Future<bool> isServerAvailable() async {
//     // We don't set global _isLoading to true here to avoid flickering the whole list.
//     // We just return the boolean result from the repo.
//     return await _repo.checkServerHealth();
//   }
//
//   void fetchOutbox() {
//     _isLoading = true;
//     final Map<dynamic, PendingConsultation> map = HiveStorage.getOutboxMap();
//     _outboxItems = map.entries.where((e) => !e.value.isSyncing).toList();
//     _outboxItems.sort((a, b) => b.value.startTime.compareTo(a.value.startTime));
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> deleteConsultation(dynamic key) async {
//     await HiveStorage.removeFromOutbox(key);
//     fetchOutbox();
//   }
// }
//
