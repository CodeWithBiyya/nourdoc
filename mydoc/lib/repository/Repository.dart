import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:medicalai/model/encounter_information_model.dart';

import '../data/network/Network_api_service.dart';
import '../data/network/base_api_services.dart';
import '../model/BookedPatientData.dart';
import '../model/EncounterListModel.dart';
import '../services/app_url.dart';
import '../utils/hive_storage.dart';

class Repository {
  final BaseApiService _apiService = NetworkApiService();


  // Inside Repository.dart
  Future<bool> checkServerHealth() async {
    String token = HiveStorage.getToken() ?? "";
    try {
      _log("📡 [REPO] Pinging Server Health: ${AppUrls.health}");

      // Hum sirf ye dekhna chahte hain ke server respond kar raha hai ya nahi
      final response = await _apiService.getGetResponse(AppUrls.health, token)
          .timeout(const Duration(seconds: 15));

      return true; // Agar response aa gaya (200 OK)
    } catch (e) {
      _log("📡 [REPO] Health check encounter: $e");

      // 🚩 KEY FIX: Agar error message mein "404" likha hai,
      // iska matlab server reachable hai, bas endpoint nahi mila.
      if (e.toString().contains('404')) {
        _log("📡 [REPO] Server responded with 404. Server is UP.");
        return true;
      }

      return false; // Real failure (Timeout, No Internet, 500 Server Error)
    }
  }
  void _log(String message) {
    final time = DateTime.now().toIso8601String();
    print("[$time][SYNC-SERVICE] $message");
  }

  // Future<bool> checkServerHealth() async {
  //   String token = HiveStorage.getToken() ?? "";
  //
  //   try {
  //     if (kDebugMode) {
  //       print("📡 [REPO] Pinging Server Health: ${AppUrls.health}");
  //     }
  //     await _apiService.getGetResponse(AppUrls.health, token);
  //
  //     // If getGetResponse reached here without throwing an error,
  //     // it means returnResponse got a 200 or 201.
  //     return true;
  //
  //   } catch (e) {
  //     // Catching SocketException, TimeoutException, or FetchDataException
  //     if (kDebugMode) {
  //       print("📡 [REPO] Health Check failed: $e");
  //     }
  //     return false;
  //   }
  // }

  // Future<dynamic> createBookingApi(
  //   Map<String, String> data,
  //   String token,
  // ) async {
  //   try {
  //     // Uses your existing getPostApiResponse which handles form-data
  //     dynamic response = await _apiService.getPostApiResponse(
  //       AppUrls.postBooking,
  //       data,
  //       token,
  //     );
  //     return response;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  // Inside Repository.dart
  Future<dynamic> createBookingApi(dynamic data, String token) async {
    // 🚩 FIX: Changed from getPostApiResponse to getPostApiResponseRaw
    // This ensures the Map is converted to a JSON string before sending to AWS.
    return await _apiService.getPostApiResponseRaw(AppUrls.postBooking, data, token);
  }

  // 2. GET: Get list of booked patients
  Future<List<BookedPatientData>> fetchBookedListApi(String doctorId, String token) async {
    String url = "${AppUrls.getBookedList}$doctorId";

    // 1. Get the raw response (List of Maps)
    final response = await _apiService.getGetResponse(url, token);

    // 2. 🚩 FIX: Map the JSON list to your Model list
    if (response is List) {
      return response.map((e) => BookedPatientData.fromJson(e)).toList();
    } else {
      // In case the API returns an empty object or error
      return [];
    }
  }

  Future<dynamic> postLoginCall(Map<String, String> datamap) async {
    try {
      if (kDebugMode) {
        print(AppUrls.login);
      }

      dynamic response =
          // await _apiService.getPostApiResponse(AppUrls.login, datamap, null);
          await _apiService.getPostApiResponseRaw(
            AppUrls.login,
            datamap,
            null,
          ); //changed becuse , we want to send the role also , and the without raw is not accepting it in correct format ,

      //  ShopDetailsModel shopDetailsModel = ShopDetailsModel.fromJson(response);
      if (kDebugMode) {
        print(response);
      }
      return response;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<dynamic> postRegisterCall(Map<String, dynamic> datamap, String token) async {
    try {
      // getPostApiResponseRaw sends 'application/json'
      dynamic response = await _apiService.getPostApiResponseRaw(
          AppUrls.register_user,
          datamap,
          token
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Future<EncounterListModel> getEncounterList(String token) async {
  //   try {
  //     print('api hit');
  //     dynamic response = await _apiService.getGetResponse(
  //       AppUrls.EncounterList,
  //       token,
  //     );
  //
  //     var encounterList = EncounterListModel.fromRawJson(response);
  //
  //     return encounterList;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }



// aws implementationky sath hai yehh
  Future<EncounterListModel> getEncounterList(String doctorId, String token) async {
    try {
      String url = AppUrls.consultationsEndpoint + doctorId;
      dynamic response = await _apiService.getGetResponse(url, token);

      // 🚩 Agar response direct List hai (Jo ke ab hai)
      if (response is List) {
        return EncounterListModel.fromRawJsonList(response);
      } else {
        // Purana tarika agar Map aata hai
        return EncounterListModel.fromJson(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  /*  Future<ShopDetailsModel> getShopDetails(int shopid) async {
    try {
      dynamic response =
          await _apiService.getGetResponse(AppUrls.getShopDetails + "$shopid");

      ShopDetailsModel shopDetailsModel = ShopDetailsModel.fromJson(response);

      return shopDetailsModel;
    } catch (e) {
      rethrow;
    }
  }*/

//aws implmentation ky sath
  Future<EncounterInformationModel> getEncounterDetials(String encounterId, String token) async {
    try {
      // 🚩 Purane URL ki jagah AWS wala URL use karein
      String url = AppUrls.encounterDetailsApi + encounterId;

      // getGetResponse use karein jo BaseApiService mein hai
      dynamic response = await _apiService.getGetResponse(url, token);

      return EncounterInformationModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }


  // Future<EncounterInformationModel> getEncounterDetials(
  //   String enconterId,
  //   String token,
  // ) async {
  //   try {
  //     print('api hit');
  //     print(
  //       "🚀 DEBUG: Actual URL being called: ${AppUrls.session_info + enconterId}",
  //     );
  //
  //     dynamic response = await _apiService.getGetResponse(
  //       AppUrls.session_info + enconterId,
  //       token,
  //     );
  //
  //     // var encounterList = EncounterInformationModel.fromRawJson(response);
  //     var encounterList = EncounterInformationModel.fromJson(response);
  //
  //     return encounterList;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  Future<dynamic> putSessionUpdate(
    String token,
    dynamic datamap,
    String SessionID,
  ) async {
    try {
      print('api hit');
      dynamic response = await _apiService.putApiResponseRaw(
        AppUrls.session_edit + SessionID,
        datamap,
        token,
      );

      // var encounterList = EncounterInformationModel.fromRawJson(response) ;

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDocProfile(String token) async {
    try {
      dynamic response = await _apiService.getGetResponse(
        AppUrls.get_doctor_profile,
        token,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> putUpdateDoctorProfile(String email, dynamic datamap, String token) async {
    try {
      // Ab hum AppUrls ka function call kar rahe hain
      String url = AppUrls.update_doctor_profile + email;

      print('📡 [REPO] PUT Request to: $url');

      dynamic response = await _apiService.putApiResponseRaw(
        url,
        datamap,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> postBatchFeedback(dynamic data, String token) async {
    try {
      // 🚩 You will need to add 'feedback_batch' to your AppUrls file
      dynamic response = await _apiService.getPostApiResponseRaw(
        AppUrls.feedback,
        data,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // --- Pricing & Entitlements ---

  Future<dynamic> activateTrialApi(Map<String, dynamic> data, String token) async {
    try {
      return await _apiService.getPostApiResponseRaw(
        AppUrls.activateTrial,
        data,
        token,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getEntitlementStatusApi(String doctorId, String token) async {
    try {
      final url = "${AppUrls.entitlementStatus}?doctor_id=$doctorId";
      return await _apiService.getGetResponse(url, token);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> requestPaidPlanApi(Map<String, dynamic> data, String token) async {
    try {
      return await _apiService.getPostApiResponseRaw(
        AppUrls.planRequests,
        data,
        token,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> initiateConsultationApi(Map<String, dynamic> data, String token, String idempotencyKey) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
      "X-Idempotency-Key": idempotencyKey,
    };
    final response = await http.post(
      Uri.parse(AppUrls.initiateConsultation),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Initiate Error: ${response.statusCode} - ${response.body}");
    }
  }

 Future<bool> deleteBookedPatientApi(
  String bookingId,
  String token,
) async {
  final url = Uri.parse(
    AppUrls.deleteBooking,
  ).replace(
    queryParameters: {
      "booking_id": bookingId,
    },
  );

  debugPrint("DELETE BOOKING URL: $url");
  debugPrint("DELETE BOOKING ID: $bookingId");

  final response = await http.delete(
    url,
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  debugPrint("DELETE BOOKING STATUS: ${response.statusCode}");
  debugPrint("DELETE BOOKING RESPONSE: ${response.body}");

  if (response.statusCode == 200 ||
      response.statusCode == 204) {
    return true;
  }

  throw Exception(
    "Failed to delete booking: "
    "${response.statusCode} - ${response.body}",
  );
}


  Future<dynamic> startConsultationApi(String jobId, Map<String, dynamic> data, String token) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    final url = "${AppUrls.startConsultation}$jobId/start";
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Start Error: ${response.statusCode} - ${response.body}");
    }
  }
}
