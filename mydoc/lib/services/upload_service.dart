// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:math';
// // import 'package:http/http.dart' as http;
// // import '../model/pending_consultation.dart';
// // import '../utils/hive_storage.dart';
// // import 'app_url.dart';

// // class SyncService {
// //   void _log(String message) {
// //     print("[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $message");
// //   }

// //   String _generateUuid() {
// //     final random = Random.secure();
// //     final values = List<int>.generate(16, (i) => random.nextInt(256));
// //     values[6] = (values[6] & 0x0f) | 0x40;
// //     values[8] = (values[8] & 0x3f) | 0x80;
// //     final buffer = StringBuffer();
// //     for (int i = 0; i < 16; i++) {
// //       if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
// //       buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
// //     }
// //     return buffer.toString();
// //   }

// //   Future<Map<String, dynamic>?> getPresignedData({
// //     required String fileName,
// //     required String doctorId,
// //     required String patientName,
// //     required String patientPhone,
// //     required String patientAge,
// //     required String patientGender,
// //     required String patientId,
// //     required String bookingId,
// //     Map<String, dynamic>? vitals,
// //   }) async {
// //     try {
// //       final token = HiveStorage.getToken() ?? "";
// //       final idempotencyKey = _generateUuid();
// //       _log("Step 1: Initiating Job -> ${AppUrls.initiateConsultation}");

// //       final response = await http.post(
// //         Uri.parse(AppUrls.initiateConsultation),
// //         headers: {
// //           "Content-Type": "application/json",
// //           "X-Idempotency-Key": idempotencyKey,
// //           "Authorization": "Bearer $token",
// //         },
// //         body: jsonEncode({
// //           "doctor_id": doctorId,
// //           "file_name": fileName,
// //           "audio-format": "audio/m4a",
// //           "patient_name": patientName,
// //           "patient_phone": patientPhone,
// //           "patient_age": patientAge,
// //           "patient_gender": patientGender,
// //         }),
// //       );

// //       // Status 200, 201 aur 409 teeno ko accept karein Step 1 mein
// //       if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
// //         final resData = jsonDecode(response.body);
// //         Map<String, String> headers = {};
// //         var rawHeaders = resData['requiredHeaders'] ?? resData['required_headers'];
// //         if (rawHeaders != null && rawHeaders is Map) {
// //           rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
// //         }
// //         return {
// //           "uploadUrl": resData['upload_url'] ?? resData['uploadUrl'],
// //           "job_id": resData['job_id'],
// //           "audio_s3_key": resData['audio_s3_key'],
// //           "requiredHeaders": headers,
// //         };
// //       }
// //       return null;
// //     } catch (e) {
// //       _log("Error Step 1: $e");
// //       return null;
// //     }
// //   }

// //   Future<bool> startUpload({
// //     required PendingConsultation task,
// //     required String uploadUrl,
// //     required Map<String, dynamic> headers,
// //     required Function(double) onProgress,
// //   }) async {
// //     try {
// //       _log("Step 2: Uploading to S3...");
// //       final file = File(task.audioPath);
// //       final int totalBytes = await file.length();
// //       final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
// //       request.contentLength = totalBytes;

// //       headers.forEach((key, value) => request.headers[key.toString()] = value.toString());
// //       request.headers['Content-Type'] = 'audio/m4a';

// //       int bytesSent = 0;
// //       file.openRead().listen(
// //             (chunk) {
// //           bytesSent += chunk.length;
// //           onProgress(bytesSent / totalBytes);
// //           request.sink.add(chunk);
// //         },
// //         onDone: () => request.sink.close(),
// //         cancelOnError: true,
// //       );

// //       final streamedResponse = await request.send();
// //       return (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201);
// //     } catch (e) {
// //       _log("Error Step 2: $e");
// //       return false;
// //     }
// //   }

// //   Future<bool> completeConsultation({
// //     required String jobId,
// //     required String doctorId,
// //     required String s3Key,
// //     required int durationSeconds,
// //   }) async {
// //     try {
// //       final token = HiveStorage.getToken() ?? "";
// //       final response = await http.post(
// //         Uri.parse("${AppUrls.startConsultation}$jobId/start"),
// //         headers: {
// //           "Content-Type": "application/json",
// //           "Authorization": "Bearer $token",
// //         },
// //         body: jsonEncode({
// //           "doctor_id": doctorId,
// //           "audio_duration_seconds": durationSeconds,
// //           "audio_s3_key": s3Key
// //         }),
// //       );

// //       _log("Step 3 Status: ${response.statusCode}");

// //       // 🚩 FIX: Agar status 200, 201 ya 409 hai, to true return karein
// //       if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
// //         if (response.statusCode == 409) {
// //           _log("Backend says: Job already exists and is processing. Treating as success.");
// //         }
// //         return true; // Ab ye true return karega to UI isay delete kar degi
// //       }

// //       return false;
// //     } catch (e) {
// //       return false;
// //     }
// //   }
// // }
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';

// import 'package:http/http.dart' as http;

// import '../model/pending_consultation.dart';
// import '../utils/hive_storage.dart';
// import 'app_url.dart';

// class SyncService {
//   // ============================================================
//   // LOGGING
//   // ============================================================

//   void _log(String message) {
//     print(
//       "[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $message",
//     );
//   }

//   // ============================================================
//   // UUID GENERATOR
//   // ============================================================

//   String _generateUuid() {
//     final random = Random.secure();

//     final values = List<int>.generate(
//       16,
//       (i) => random.nextInt(256),
//     );

//     values[6] = (values[6] & 0x0f) | 0x40;
//     values[8] = (values[8] & 0x3f) | 0x80;

//     final buffer = StringBuffer();

//     for (int i = 0; i < 16; i++) {
//       if (i == 4 || i == 6 || i == 8 || i == 10) {
//         buffer.write('-');
//       }

//       buffer.write(
//         values[i].toRadixString(16).padLeft(2, '0'),
//       );
//     }

//     return buffer.toString();
//   }

//   // ============================================================
//   // STEP 1
//   // INITIATE CONSULTATION
//   // ============================================================

//   Future<Map<String, dynamic>?> getPresignedData({
//     required String fileName,
//     required String doctorId,
//     required String patientName,
//     required String patientPhone,
//     required String patientAge,
//     required String patientGender,
//     required String patientId,
//     required String bookingId,
//     Map<String, dynamic>? vitals,
//   }) async {
//     try {
//       final token = HiveStorage.getToken() ?? "";

//       final idempotencyKey = _generateUuid();

//       _log(
//         "Step 1: Initiating Job -> "
//         "${AppUrls.initiateConsultation}",
//       );

//       _log(
//         "Booking ID being sent: $bookingId",
//       );

//       // ==========================================================
//       // REQUEST BODY
//       // ==========================================================

//       final Map<String, dynamic> requestBody = {
//         "doctor_id": doctorId,
//         "file_name": fileName,
//         "audio-format": "audio/m4a",

//         "patient_name": patientName,
//         "patient_phone": patientPhone,
//         "patient_age": patientAge,
//         "patient_gender": patientGender,

//         // IMPORTANT:
//         // Send the actual booking ID to backend.
//         "booking_id": bookingId,
//       };

//       // Add vitals if available
//       if (vitals != null && vitals.isNotEmpty) {
//         requestBody["vitals"] = vitals;
//       }

//       _log(
//         "Step 1 Request Body: "
//         "${jsonEncode(requestBody)}",
//       );

//       // ==========================================================
//       // API CALL
//       // ==========================================================

//       final response = await http.post(
//         Uri.parse(
//           AppUrls.initiateConsultation,
//         ),
//         headers: {
//           "Content-Type": "application/json",
//           "X-Idempotency-Key": idempotencyKey,
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(requestBody),
//       );

//       // ==========================================================
//       // RESPONSE LOG
//       // ==========================================================

//       _log(
//         "Step 1 Status: ${response.statusCode}",
//       );

//       _log(
//         "Step 1 Response: ${response.body}",
//       );

//       // ==========================================================
//       // SUCCESS
//       // ==========================================================

//       if (response.statusCode == 200 ||
//           response.statusCode == 201 ||
//           response.statusCode == 409) {
//         final resData = jsonDecode(response.body);

//         // ========================================================
//         // REQUIRED HEADERS
//         // ========================================================

//         Map<String, String> headers = {};

//         final rawHeaders =
//             resData['requiredHeaders'] ??
//             resData['required_headers'];

//         if (rawHeaders != null && rawHeaders is Map) {
//           rawHeaders.forEach(
//             (key, value) {
//               headers[key.toString()] = value.toString();
//             },
//           );
//         }

//         // ========================================================
//         // RETURN DATA
//         // ========================================================

//         return {
//           "uploadUrl":
//               resData['upload_url'] ??
//               resData['uploadUrl'],

//           "job_id":
//               resData['job_id'],

//           "audio_s3_key":
//               resData['audio_s3_key'],

//           "requiredHeaders":
//               headers,

//           // Keep booking ID available
//           // for the next step.
//           "booking_id":
//               bookingId,
//         };
//       }

//       // ==========================================================
//       // FAILURE
//       // ==========================================================

//       _log(
//         "Step 1 failed: "
//         "${response.statusCode}",
//       );

//       return null;
//     } catch (e) {
//       _log(
//         "Error Step 1: $e",
//       );

//       return null;
//     }
//   }

//   // ============================================================
//   // STEP 2
//   // UPLOAD AUDIO TO S3
//   // ============================================================

//   Future<bool> startUpload({
//     required PendingConsultation task,
//     required String uploadUrl,
//     required Map<String, dynamic> headers,
//     required Function(double) onProgress,
//   }) async {
//     try {
//       _log(
//         "Step 2: Uploading to S3...",
//       );

//       final file = File(task.audioPath);

//       final int totalBytes = await file.length();

//       if (totalBytes <= 0) {
//         _log(
//           "Step 2 failed: Audio file is empty.",
//         );

//         return false;
//       }

//       final request = http.StreamedRequest(
//         'PUT',
//         Uri.parse(uploadUrl),
//       );

//       request.contentLength = totalBytes;

//       // ==========================================================
//       // S3 HEADERS
//       // ==========================================================

//       headers.forEach(
//         (key, value) {
//           request.headers[key.toString()] =
//               value.toString();
//         },
//       );

//       request.headers['Content-Type'] =
//           'audio/m4a';

//       // ==========================================================
//       // UPLOAD PROGRESS
//       // ==========================================================

//       int bytesSent = 0;

//       file.openRead().listen(
//         (chunk) {
//           bytesSent += chunk.length;

//           final progress =
//               bytesSent / totalBytes;

//           onProgress(
//             progress.clamp(
//               0.0,
//               1.0,
//             ),
//           );

//           request.sink.add(chunk);
//         },
//         onDone: () {
//           request.sink.close();
//         },
//         cancelOnError: true,
//       );

//       // ==========================================================
//       // SEND REQUEST
//       // ==========================================================

//       final streamedResponse =
//           await request.send();

//       _log(
//         "Step 2 Status: "
//         "${streamedResponse.statusCode}",
//       );

//       return streamedResponse.statusCode == 200 ||
//           streamedResponse.statusCode == 201;
//     } catch (e) {
//       _log(
//         "Error Step 2: $e",
//       );

//       return false;
//     }
//   }

//   // ============================================================
//   // STEP 3
//   // START / COMPLETE CONSULTATION
//   // ============================================================

//   Future<bool> completeConsultation({
//     required String jobId,
//     required String doctorId,
//     required String s3Key,
//     required int durationSeconds,

//     // IMPORTANT:
//     // Booking ID is optional so older/offline calls
//     // don't immediately break.
//     String? bookingId,
//   }) async {
//     try {
//       final token =
//           HiveStorage.getToken() ?? "";

//       // ==========================================================
//       // REQUEST BODY
//       // ==========================================================

//       final Map<String, dynamic> requestBody = {
//         "doctor_id": doctorId,
//         "audio_duration_seconds":
//             durationSeconds,
//         "audio_s3_key":
//             s3Key,
//       };

//       // ==========================================================
//       // ADD BOOKING ID
//       // ==========================================================

//       if (bookingId != null &&
//           bookingId.trim().isNotEmpty) {
//         requestBody["booking_id"] =
//             bookingId.trim();
//       }

//       _log(
//         "Step 3 Booking ID: "
//         "${bookingId ?? "Not provided"}",
//       );

//       _log(
//         "Step 3 Request Body: "
//         "${jsonEncode(requestBody)}",
//       );

//       // ==========================================================
//       // API CALL
//       // ==========================================================

//       final response = await http.post(
//         Uri.parse(
//           "${AppUrls.startConsultation}"
//           "$jobId/start",
//         ),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(requestBody),
//       );

//       // ==========================================================
//       // RESPONSE LOG
//       // ==========================================================

//       _log(
//         "Step 3 Status: "
//         "${response.statusCode}",
//       );

//       _log(
//         "Step 3 Response: "
//         "${response.body}",
//       );

//       // ==========================================================
//       // SUCCESS
//       // ==========================================================

//       if (response.statusCode == 200 ||
//           response.statusCode == 201 ||
//           response.statusCode == 409) {
//         if (response.statusCode == 409) {
//           _log(
//             "Backend says: Job already exists "
//             "and is processing. Treating as success.",
//           );
//         }

//         return true;
//       }

//       // ==========================================================
//       // FAILURE
//       // ==========================================================

//       _log(
//         "Step 3 failed.",
//       );

//       return false;
//     } catch (e) {
//       _log(
//         "Error Step 3: $e",
//       );

//       return false;
//     }
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../model/pending_consultation.dart';
import '../utils/hive_storage.dart';
import 'app_url.dart';

class SyncService {
  void _log(String message) {
    print("[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $message");
  }

  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<Map<String, dynamic>?> getPresignedData({
    required String fileName,
    required String doctorId,
    required String patientName,
    required String patientPhone,
    required String patientAge,
    required String patientGender,
    required String patientId,
    required String bookingId,
    Map<String, dynamic>? vitals,
  }) async {
    try {
      final token = HiveStorage.getToken() ?? "";
      final idempotencyKey = _generateUuid();
      _log("Step 1: Initiating Job -> ${AppUrls.initiateConsultation}");

      final response = await http.post(
        Uri.parse(AppUrls.initiateConsultation),
        headers: {
          "Content-Type": "application/json",
          "X-Idempotency-Key": idempotencyKey,
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctor_id": doctorId,
          "file_name": fileName,
          "audio-format": "audio/m4a",
          "patient_name": patientName,
          "patient_phone": patientPhone,
          "patient_age": patientAge,
          "patient_gender": patientGender,
          "booking_id": bookingId,
        }),
      );

      // Status 200, 201 aur 409 teeno ko accept karein Step 1 mein
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
        final resData = jsonDecode(response.body);
        Map<String, String> headers = {};
        var rawHeaders = resData['requiredHeaders'] ?? resData['required_headers'];
        if (rawHeaders != null && rawHeaders is Map) {
          rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
        }
        return {
          "uploadUrl": resData['upload_url'] ?? resData['uploadUrl'],
          "job_id": resData['job_id'],
          "audio_s3_key": resData['audio_s3_key'],
          "requiredHeaders": headers,
        };
      }
      return null;
    } catch (e) {
      _log("Error Step 1: $e");
      return null;
    }
  }

  Future<bool> startUpload({
    required PendingConsultation task,
    required String uploadUrl,
    required Map<String, dynamic> headers,
    required Function(double) onProgress,
  }) async {
    try {
      _log("Step 2: Uploading to S3...");
      final file = File(task.audioPath);
      final int totalBytes = await file.length();
      final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
      request.contentLength = totalBytes;

      headers.forEach((key, value) => request.headers[key.toString()] = value.toString());
      request.headers['Content-Type'] = 'audio/m4a';

      int bytesSent = 0;
      file.openRead().listen(
            (chunk) {
          bytesSent += chunk.length;
          onProgress(bytesSent / totalBytes);
          request.sink.add(chunk);
        },
        onDone: () => request.sink.close(),
        cancelOnError: true,
      );

      final streamedResponse = await request.send();
      return (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201);
    } catch (e) {
      _log("Error Step 2: $e");
      return false;
    }
  }

  Future<bool> completeConsultation({
    required String jobId,
    required String doctorId,
    required String s3Key,
    required int durationSeconds,
    required String bookingId,
  }) async {
    try {
      final token = HiveStorage.getToken() ?? "";
      final response = await http.post(
        Uri.parse("${AppUrls.startConsultation}$jobId/start"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctor_id": doctorId,
          "audio_duration_seconds": durationSeconds,
          "audio_s3_key": s3Key,
          "booking_id": bookingId,
        }),
      );

      _log("Step 3 Status: ${response.statusCode}");

      // 🚩 FIX: Agar status 200, 201 ya 409 hai, to true return karein
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
        if (response.statusCode == 409) {
          _log("Backend says: Job already exists and is processing. Treating as success.");
        }
        return true; // Ab ye true return karega to UI isay delete kar degi
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}