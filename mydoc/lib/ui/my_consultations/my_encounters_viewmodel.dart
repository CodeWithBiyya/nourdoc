import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../data/response/api_response.dart';
import '../../model/EncounterListModel.dart';
import '../../repository/Repository.dart';
import '../../utils/hive_storage.dart';

class MyEncounterViewModel with ChangeNotifier {
  final _myrepo = Repository();
  ApiResponse<EncounterListModel> apiEncounterList = ApiResponse.loading();

  bool _isDisposed = false; // ✅ Track disposal

  @override
  void dispose() {
    _isDisposed = true; // ✅ Mark as disposed
    super.dispose();
  }

  void setEncounterList(ApiResponse<EncounterListModel> response) {
    if (_isDisposed) return; // ✅ Disposed ho to kuch mat karo
    apiEncounterList = response;
    notifyListeners();
  }

  Future<dynamic> postBatchFeedback(dynamic data, String token) async {
    try {
      final response = await _myrepo.postBatchFeedback(data, token);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getEncounters() async {
    if (_isDisposed) return; // ✅ Early exit
    setEncounterList(ApiResponse.loading());

    // 1. Internet Check
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setEncounterList(ApiResponse.error("No internet connection"));
      return;
    }

    // 2. Token aur DoctorID hasil karo
    String? token = HiveStorage.getToken();
    String? doctorId = HiveStorage.getUserEmail();

    if (token == null || token.isEmpty) {
      setEncounterList(ApiResponse.error("Token not found"));
      return;
    }

    if (doctorId == null || doctorId.isEmpty) {
      setEncounterList(ApiResponse.error("Doctor ID not found"));
      return;
    }

    // 3. API call
    _myrepo
        .getEncounterList(doctorId, token)
        .then((value) {
      if (_isDisposed) return; // ✅ Response aane se pehle disposed check
      setEncounterList(ApiResponse.completed(value));
    })
        .onError((error, stackTrace) {
      if (_isDisposed) return; // ✅ Error aane se pehle disposed check
      setEncounterList(ApiResponse.error(error.toString()));
      if (kDebugMode) print("getEncounters error: $error");
    });
  }
}