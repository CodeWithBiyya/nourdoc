// import 'package:flutter/cupertino.dart';

// import '../data/response/api_response.dart';
// import '../model/BookedPatientData.dart';
// import '../repository/Repository.dart';
// import '../utils/hive_storage.dart';
// import '../utils/noInternet.dart';

// class ConsultationViewModel with ChangeNotifier {
//   final _myRepo = Repository();

//   ApiResponse<List<BookedPatientData>> bookedPatientList = ApiResponse.loading();

//   // 🚩 STEP 1: Track disposal status
//   bool _isDisposed = false;

//   @override
//   void dispose() {
//     _isDisposed = true; // Mark as disposed
//     super.dispose();
//   }

//   // 🚩 STEP 2: Logic to prevent notifying after dispose
//   setBookedList(ApiResponse<List<BookedPatientData>> response) {
//     if (_isDisposed) return; // ✅ Exit if disposed to prevent crash
//     bookedPatientList = response;
//     notifyListeners();
//   }

//   // Logic to fetch the list
//   // Logic to fetch the list
//   Future<void> getBookedPatients() async {
//     if (_isDisposed) return;
//     setBookedList(ApiResponse.loading());

//     // 1. Get the Doctor's Email (this is your doctor_id for the API)
//     String doctorId = HiveStorage.getEmail() ?? "";

//     // 2. Get the Token
//     String token = HiveStorage.getToken() ?? "";

//     // 🚩 FIX: Pass doctorId and token (Both are Strings)
//     // Remove the "20" because the new API doesn't use a limit integer here
//     _myRepo.fetchBookedListApi(doctorId, token).then((value) {

//         debugPrint(
//     "BOOKED PATIENTS AFTER API CALL: "
//     "${value.map((e) => e.bookingId).toList()}",
//   );
//       if (_isDisposed) return;
//       setBookedList(ApiResponse.completed(value));
//     }).onError((error, stackTrace) {
//       if (_isDisposed) return;
//       setBookedList(ApiResponse.error(error.toString()));
//     });
//   }
//     void removeBookedPatient(String bookingId) {
//     if (_isDisposed) return;

//     final currentList = bookedPatientList.data;

//     if (currentList == null) return;

//     currentList.removeWhere(
//       (patient) =>
//           patient.bookingId.toString() == bookingId.toString(),
//     );

//     bookedPatientList = ApiResponse.completed(currentList);

//     notifyListeners();
//   }

//   // Logic to post the booking
//   Future<dynamic> saveNewBooking(Map<String, dynamic> data) async {
//     String token = HiveStorage.getToken() ?? "";

//     try {
//       final response = await _myRepo.createBookingApi(data, token);

//       return {
//         "custom_status": 200,
//         "message": "Success",
//         "data": response
//       };

//     } catch (e) {
//       String errorStr = e.toString().toLowerCase();

//       if (errorStr.contains('401')) {
//         return {"custom_status": 401, "message": "Session expired. Please login again."};
//       }

//       bool hasNet = await hasInternet();
//       if (!hasNet) {
//         return {
//           "custom_status": 503,
//           "message": "No internet connection."
//         };
//       }

//       if (errorStr.contains("timeout") || errorStr.contains("server") || errorStr.contains("502")) {
//         return {
//           "custom_status": 500,
//           "message": "Service upgrade in progress. Try again later."
//         };
//       }

//       return {
//         "custom_status": 400,
//         "message": "Unable to save. Please try again."
//       };
//     }
//   }
// }

// // import 'package:flutter/cupertino.dart';
// //
// // import '../data/response/api_response.dart';
// // import '../model/BookedPatientData.dart';
// // import '../repository/Repository.dart';
// // import '../utils/hive_storage.dart';
// // import '../utils/noInternet.dart';
// //
// // class ConsultationViewModel with ChangeNotifier {
// //   final _myRepo = Repository();
// //
// //   ApiResponse<List<BookedPatientData>> bookedPatientList = ApiResponse.loading();
// //
// //   setBookedList(ApiResponse<List<BookedPatientData>> response) {
// //     bookedPatientList = response;
// //     notifyListeners();
// //   }
// //
// //   // Logic to fetch the list
// //   Future<void> getBookedPatients() async {
// //     setBookedList(ApiResponse.loading());
// //
// //     String token = HiveStorage.getToken() ?? "";
// //
// //     _myRepo.fetchBookedListApi(token, 20).then((value) {
// //       setBookedList(ApiResponse.completed(value));
// //     }).onError((error, stackTrace) {
// //       setBookedList(ApiResponse.error(error.toString()));
// //     });
// //   }
// //
// //   // // Logic to post the booking (called from NewEncounter screen)
// //   // Future<dynamic> saveNewBooking(Map<String, String> data) async {
// //   //   String token = HiveStorage.getToken() ?? "";
// //   //   return await _myRepo.createBookingApi(data, token);
// //   // }
// //
// // // Inside ConsultationViewModel class:
// //   Future<dynamic> saveNewBooking(Map<String, dynamic> data) async {
// //     String token = HiveStorage.getToken() ?? "";
// //
// //     try {
// //       // return await _myRepo.createBookingApi(data, token);
// //
// //       final response = await _myRepo.createBookingApi(data, token);
// //
// //       // 🚩 FIX: Even if the server doesn't send "custom_status",
// //       // we add it here so the UI has a consistent way to check for success.
// //       return {
// //         "custom_status": 200,
// //         "message": "Success",
// //         "data": response // The actual server response (e.g., {"patient_id": 3})
// //       };
// //
// //     } catch (e) {
// //       String errorStr = e.toString().toLowerCase();
// //
// //       // 1. Check for Session Expiry
// //       if (errorStr.contains('401')) {
// //         return {"custom_status": 401, "message": "Session expired. Please login again."};
// //       }
// //
// //       // 2. Check for Internet
// //       bool hasNet = await hasInternet();
// //       if (!hasNet) {
// //         return {
// //           "custom_status": 503,
// //           "message": "No internet connection."
// //         };
// //       }
// //
// //       // 3. Check for Server/Timeout
// //       if (errorStr.contains("timeout") || errorStr.contains("server") || errorStr.contains("502")) {
// //         return {
// //           "custom_status": 500,
// //           "message": "Service upgrade in progress. Try again later."
// //         };
// //       }
// //
// //       // 4. Fallback
// //       return {
// //         "custom_status": 400,
// //         "message": "Unable to save. Please try again."
// //       };
// //     }
// //   }
// // }


import 'package:flutter/cupertino.dart';

import '../data/response/api_response.dart';
import '../model/BookedPatientData.dart';
import '../repository/Repository.dart';
import '../utils/hive_storage.dart';
import '../utils/noInternet.dart';


class ConsultationViewModel with ChangeNotifier {
  final _myRepo = Repository();

  ApiResponse<List<BookedPatientData>> bookedPatientList =
      ApiResponse.loading();

  // ============================================================
  // DISPOSE PROTECTION
  // ============================================================

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  setBookedList(ApiResponse<List<BookedPatientData>> response) {
    if (_isDisposed) return;

    bookedPatientList = response;
    notifyListeners();
  }

  // ============================================================
  // GET BOOKED PATIENTS
  // ============================================================

  Future<void> getBookedPatients() async {
    if (_isDisposed) return;

    setBookedList(ApiResponse.loading());

    // Doctor email is used as doctor_id
    String doctorId = HiveStorage.getEmail() ?? "";

    // Authentication token
    String token = HiveStorage.getToken() ?? "";

    try {
      final value = await _myRepo.fetchBookedListApi(
        doctorId,
        token,
      );

      debugPrint(
        "BOOKED PATIENTS AFTER API CALL: "
        "${value.map((e) => e.bookingId).toList()}",
      );

      if (_isDisposed) return;

      setBookedList(
        ApiResponse.completed(value),
      );
    } catch (error) {
      if (_isDisposed) return;

      setBookedList(
        ApiResponse.error(error.toString()),
      );
    }
  }

  // ============================================================
  // REMOVE BOOKING FROM LOCAL UI LIST
  // ============================================================

  void removeBookedPatient(String bookingId) {
  debugPrint("========================================");
  debugPrint("REMOVE BOOKING FROM UI");
  debugPrint("Booking ID to remove: $bookingId");

  if (_isDisposed) {
    debugPrint("ERROR: ViewModel is disposed");
    return;
  }

  final currentList = bookedPatientList.data;

  if (currentList == null) {
    debugPrint("ERROR: bookedPatientList.data is NULL");
    return;
  }

  debugPrint(
    "UI LIST BEFORE: "
    "${currentList.map((e) => e.bookingId).toList()}",
  );

  final updatedList = List<BookedPatientData>.from(currentList);

  final beforeCount = updatedList.length;

  updatedList.removeWhere(
    (patient) =>
        patient.bookingId.toString().trim() ==
        bookingId.toString().trim(),
  );

  final afterCount = updatedList.length;

  debugPrint("BEFORE COUNT: $beforeCount");
  debugPrint("AFTER COUNT: $afterCount");
  debugPrint("REMOVED COUNT: ${beforeCount - afterCount}");

  debugPrint(
    "UI LIST AFTER: "
    "${updatedList.map((e) => e.bookingId).toList()}",
  );

  if (beforeCount == afterCount) {
    debugPrint(
      "WARNING: Booking ID $bookingId was NOT FOUND in UI list!",
    );
  }

  bookedPatientList = ApiResponse.completed(updatedList);

  debugPrint("Calling notifyListeners()");

  notifyListeners();

  debugPrint("UI LIST UPDATED");
  debugPrint("========================================");
}

  // ============================================================
  // DELETE BOOKED PATIENT
  // ============================================================

  Future<bool> deleteBookedPatient(String bookingId) async {
    if (_isDisposed) return false;

    final token = HiveStorage.getToken() ?? "";

    try {
      debugPrint("=================================");
      debugPrint("DELETE BOOKING STARTED");
      debugPrint("Booking ID: $bookingId");
      debugPrint("Token exists: ${token.isNotEmpty}");

      // ----------------------------------------------------------
      // CALL DELETE API
      // ----------------------------------------------------------

      await _myRepo.deleteBookedPatientApi(
        bookingId,
        token,
      );

      debugPrint("DELETE API SUCCESS");

      // ----------------------------------------------------------
      // REMOVE FROM LOCAL PROVIDER LIST
      // ----------------------------------------------------------

      removeBookedPatient(bookingId);

      debugPrint(
        "BOOKING REMOVED SUCCESSFULLY: $bookingId",
      );
      debugPrint("=================================");

      return true;
    } catch (e, stackTrace) {
      debugPrint("=================================");
      debugPrint("DELETE BOOKING FAILED");
      debugPrint("Booking ID: $bookingId");
      debugPrint("ERROR: $e");
      debugPrint("STACK: $stackTrace");
      debugPrint("=================================");

      return false;
    }
  }

  // ============================================================
  // SAVE NEW BOOKING
  // ============================================================

  Future<dynamic> saveNewBooking(
    Map<String, dynamic> data,
  ) async {
    String token = HiveStorage.getToken() ?? "";

    try {
      final response = await _myRepo.createBookingApi(
        data,
        token,
      );

      return {
        "custom_status": 200,
        "message": "Success",
        "data": response,
      };
    } catch (e) {
      String errorStr = e.toString().toLowerCase();

      // ----------------------------------------------------------
      // SESSION EXPIRED
      // ----------------------------------------------------------

      if (errorStr.contains('401')) {
        return {
          "custom_status": 401,
          "message": "Session expired. Please login again.",
        };
      }

      // ----------------------------------------------------------
      // NO INTERNET
      // ----------------------------------------------------------

      bool hasNet = await hasInternet();

      if (!hasNet) {
        return {
          "custom_status": 503,
          "message": "No internet connection.",
        };
      }

      // ----------------------------------------------------------
      // SERVER / TIMEOUT ERROR
      // ----------------------------------------------------------

      if (errorStr.contains("timeout") ||
          errorStr.contains("server") ||
          errorStr.contains("502")) {
        return {
          "custom_status": 500,
          "message": "Service upgrade in progress. Try again later.",
        };
      }

      // ----------------------------------------------------------
      // OTHER ERROR
      // ----------------------------------------------------------

      return {
        "custom_status": 400,
        "message": "Unable to save. Please try again.",
      };
    }
  }
}

