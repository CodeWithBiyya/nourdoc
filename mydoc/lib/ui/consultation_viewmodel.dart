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
  final String doctorId = HiveStorage.getEmail() ?? "";

  // Authentication token
  final String token = HiveStorage.getToken() ?? "";

  try {
    final value = await _myRepo.fetchBookedListApi(
      doctorId,
      token,
    );

    debugPrint(
      "BOOKED PATIENTS FROM API: "
      "${value.map((e) => e.bookingId).toList()}",
    );

    // ============================================================
    // REMOVE ALREADY COMPLETED BOOKINGS
    // ============================================================

    final completedBookingIds =
        HiveStorage.getCompletedBookingIds().toSet();

    debugPrint(
      "COMPLETED BOOKING IDS: $completedBookingIds",
    );

    final filteredList = value.where((patient) {
      final bookingId = patient.bookingId.toString().trim();

      final alreadyCompleted =
          completedBookingIds.contains(bookingId);

      if (alreadyCompleted) {
        debugPrint(
          "FILTERING COMPLETED BOOKING: $bookingId",
        );
      }

      return !alreadyCompleted;
    }).toList();

    debugPrint(
      "BOOKED PATIENTS AFTER FILTER: "
      "${filteredList.map((e) => e.bookingId).toList()}",
    );

    if (_isDisposed) return;

    setBookedList(
      ApiResponse.completed(filteredList),
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

