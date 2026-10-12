import 'package:flutter/foundation.dart';
import 'package:medicalai/data/response/api_response.dart';
import 'package:medicalai/model/encounter_information_model.dart';

import '../../repository/Repository.dart';
import '../../utils/hive_storage.dart';
import '../../utils/noInternet.dart';
import '../../utils/utils.dart';

class ClinicalFindingsViewModel with ChangeNotifier {
  final _myrepo = Repository();
  ApiResponse<EncounterInformationModel> encounterInfo = ApiResponse.loading();

  // Unified setter to update UI
  void EnconterData(ApiResponse<EncounterInformationModel> response) {
    encounterInfo = response;
    notifyListeners();
  }

//aws implementation
  Future<void> getEncounterDetals(String encounterId) async {
    EnconterData(ApiResponse.loading());

    if (!await hasInternet()) {
      EnconterData(ApiResponse.error("NO_INTERNET"));
      return;
    }

    // Server health check agar aapne repository mein implement kiya hua hai
    bool isHealthy = await _myrepo.checkServerHealth();
    if (!isHealthy) {
      EnconterData(ApiResponse.error("SERVER_ERROR"));
      return;
    }

    String? token = HiveStorage.getToken();

    // Repository call
    _myrepo.getEncounterDetials(encounterId, token ?? "").then((value) {
      EnconterData(ApiResponse.completed(value));
      if (kDebugMode) print("✅ AWS Data Fetched: ${value.toString()}");
    }).onError((error, stackTrace) {
      // Error handling logic (Jo aapne likhi hai wo bilkul sahi hai)
      String errorStr = error.toString().toLowerCase();
      if (errorStr.contains("timeout")) {
        EnconterData(ApiResponse.error("TIMEOUT"));
      } else {
        EnconterData(ApiResponse.error(error.toString()));
      }
    });
  }


  // Future<void> getEncounterDetals(String encounterId) async {
  //   EnconterData(ApiResponse.loading());
  //
  //   // 1. Internet Check
  //   // This calls your global hasInternet() utility
  //   if (!await hasInternet()) {
  //     EnconterData(ApiResponse.error("NO_INTERNET"));
  //     return;
  //   }
  //
  //   // 2. Server Health Check
  //   // If server is down/upgrading, we catch it before making the heavy data call
  //   bool isHealthy = await _myrepo.checkServerHealth();
  //   if (!isHealthy) {
  //     EnconterData(ApiResponse.error("SERVER_ERROR"));
  //     return;
  //   }
  //
  //   String? token = HiveStorage.getToken();
  //
  //   _myrepo.getEncounterDetials(encounterId, token ?? "").then((value) {
  //     // SUCCESS
  //     EnconterData(ApiResponse.completed(value));
  //
  //     if (kDebugMode) print("✅ Data Fetched: ${value.toString()}");
  //
  //   }).onError((error, stackTrace) {
  //     // 🚩 3. Categorize Technical Errors for the Screen UI
  //     String errorStr = error.toString().toLowerCase();
  //
  //     if (errorStr.contains("timeout")) {
  //       EnconterData(ApiResponse.error("TIMEOUT"));
  //     } else if (errorStr.contains("socketexception") || errorStr.contains("no internet")) {
  //       EnconterData(ApiResponse.error("NO_INTERNET"));
  //     } else {
  //       // Pass the actual error message for any other case
  //       EnconterData(ApiResponse.error(error.toString()));
  //     }
  //
  //     if (kDebugMode) print("❌ API Error: $error");
  //   });
  // }

  Future <dynamic> updateEncounter(dynamic datamap, String sessionId)async {

    String? token ="";

    if (HiveStorage.getToken()!.isNotEmpty){
      token = (HiveStorage.getToken());
    }

    dynamic response;
    response = await _myrepo.putSessionUpdate(token!,datamap, sessionId).then((value) {
      if (kDebugMode) {
        print(value.toString());
      }
      return value;
    }).onError((error, stackTrace) {
      utils.toastMessage(error.toString());
      if (kDebugMode) {

        print(error.toString());
      }
    });

    return response;

  }
}

