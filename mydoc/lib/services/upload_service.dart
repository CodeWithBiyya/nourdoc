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

// //   // Future<Map<String, dynamic>?> getPresignedData({
// //   //   required String fileName,
// //   //   required String doctorId,
// //   //   required String patientName,
// //   //   required String patientPhone,
// //   //   required String patientAge,
// //   //   required String patientGender,
// //   //   required String patientId,
// //   //   required String bookingId,
// //   //   int durationSeconds = 0,
// //   //   Map<String, dynamic>? vitals,
// //   // }) async {
// //   //   try {
// //   //     final token = HiveStorage.getToken() ?? "";
// //   //     final idempotencyKey = _generateUuid();
// //   //     _log("Step 1: Initiating Job -> ${AppUrls.initiateConsultation}");

// //   //     final response = await http.post(
// //   //       Uri.parse(AppUrls.initiateConsultation),
// //   //       headers: {
// //   //         "Content-Type": "application/json",
// //   //         "X-Idempotency-Key": idempotencyKey,
// //   //         "Authorization": "Bearer $token",
// //   //       },
// //   //       body: jsonEncode({
// //   //         "doctor_id": doctorId,
// //   //         "file_name": fileName,
// //   //         "audio-format": "audio/m4a",
// //   //         "patient_name": patientName,
// //   //         "patient_phone": patientPhone,
// //   //         "patient_age": patientAge,
// //   //         "patient_gender": patientGender,
// //   //         "vitals": vitals ?? {},
// //   //         "audio_duration_seconds": durationSeconds,
// //   //         if (bookingId.isNotEmpty) "booking_id": bookingId,
// //   //       }),
// //   //     );

// //   //     // Status 200, 201 aur 409 teeno ko accept karein Step 1 mein
// //   //     if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
// //   //       final resData = jsonDecode(response.body);
// //   //       Map<String, String> headers = {};
// //   //       var rawHeaders = resData['requiredHeaders'] ?? resData['required_headers'];
// //   //       if (rawHeaders != null && rawHeaders is Map) {
// //   //         rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
// //   //       }
// //   //       return {
// //   //         "uploadUrl": resData['upload_url'] ?? resData['uploadUrl'],
// //   //         "job_id": resData['job_id'],
// //   //         "audio_s3_key": resData['audio_s3_key'],
// //   //         "requiredHeaders": headers,
// //   //       };
// //   //     }
// //   //     return null;
// //   //   } catch (e) {
// //   //     _log("Error Step 1: $e");
// //   //     return null;
// //   //   }
// //   // }
// //   // Future<Map<String, dynamic>?> getPresignedData({
// //   //   required String fileName,
// //   //   required String doctorId,
// //   //   required String patientName,
// //   //   required String patientPhone,
// //   //   required String patientAge,
// //   //   required String patientGender,
// //   //   required String patientId,
// //   //   required String bookingId,
// //   //   int durationSeconds = 0,
// //   //   Map<String, dynamic>? vitals,
// //   // }) async {
// //   //   try {
// //   //     final token = HiveStorage.getToken() ?? "";
// //   //     final idempotencyKey = _generateUuid();
// //   //     _log("Step 1: Uploading -> ${AppUrls.upload}");

// //   //     _log("Step 1 sending: name='$patientName' phone='$patientPhone' booking='$bookingId'");

// //   //     final response = await http.post(
// //   //       Uri.parse(AppUrls.upload),
// //   //       headers: {
// //   //         "Content-Type": "application/json",
// //   //         "idempotency-key": idempotencyKey,
// //   //         "Authorization": "Bearer $token",
// //   //       },
// //   //       body: jsonEncode({
// //   //         "file-name": fileName,
// //   //         "doctor-id": doctorId,
// //   //         "audio-format": "audio/m4a",
// //   //         "patient_name": patientName,
// //   //         "patient_phone": patientPhone,
// //   //         "patient_age": patientAge,
// //   //         "patient_gender": patientGender,
// //   //         "vitals": vitals ?? {},
// //   //         "audio_duration_seconds": durationSeconds,
// //   //         if (bookingId.isNotEmpty) "booking_id": bookingId,
// //   //       }),
// //   //     );

// //   //     _log("Step 1 Status: ${response.statusCode}");
// //   //     _log("Step 1 Response: ${response.body}");

// //   //     if (response.statusCode == 200 ||
// //   //         response.statusCode == 201 ||
// //   //         response.statusCode == 409) {
// //   //       final decoded = jsonDecode(response.body);
// //   //       final Map data = decoded is Map
// //   //           ? (decoded['response'] is Map ? decoded['response'] : decoded)
// //   //           : {};

// //   //       String? pick(List<String> keys) {
// //   //         for (final k in keys) {
// //   //           if (data[k] != null) return data[k].toString();
// //   //         }
// //   //         return null;
// //   //       }

// //   //       final Map<String, String> headers = {};
// //   //       final rawHeaders = data['requiredHeaders'] ?? data['required_headers'];
// //   //       if (rawHeaders is Map) {
// //   //         rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
// //   //       }

// //   //       return {
// //   //         "uploadUrl": pick(['upload_url', 'uploadUrl', 'presigned_url', 'presignedUrl', 'url']),
// //   //         "job_id": pick(['job_id', 'jobId', 'consultation_id', 'id']),
// //   //         "audio_s3_key": pick(['audio_s3_key', 's3_key', 'key']),
// //   //         "requiredHeaders": headers,
// //   //       };
// //   //     }
// //   //     return null;
// //   //   } catch (e) {
// //   //     _log("Error Step 1: $e");
// //   //     return null;
// //   //   }
// //   // }
  

// //   Future<Map<String, dynamic>?> getPresignedData({
// //   required String fileName,
// //   required String doctorId,
// //   required String patientName,
// //   required String patientPhone,
// //   required String patientAge,
// //   required String patientGender,
// //   required String patientId,
// //   required String bookingId,
// //   int durationSeconds = 0,
// //   Map<String, dynamic>? vitals,
// // }) async {
// //   try {
// //     final token = HiveStorage.getToken() ?? "";
// //     final idempotencyKey = _generateUuid();

// //     final uri = Uri.parse(AppUrls.upload);

// //     _log("================================================");
// //     _log("STEP 1 - REQUEST PRESIGNED AUDIO URL");
// //     _log("URL: $uri");
// //     _log("Doctor ID: $doctorId");
// //     _log("Patient: $patientName");
// //     _log("Booking ID: $bookingId");
// //     _log("================================================");

// //     final Map<String, dynamic> body = {
// //       "file-name": fileName,
// //       "doctor-id": doctorId,
// //       "audio-format": "audio/m4a",
// //       "patient_name": patientName,
// //       "patient_phone": patientPhone,
// //       "patient_age": patientAge,
// //       "patient_gender": patientGender,
// //       "booking_id": bookingId,
// //       "audio-duration-seconds": durationSeconds,
// //       "vitals": vitals ?? {},
// //     };

// //     if (patientId.isNotEmpty) {
// //       body["patient_id"] = patientId;
// //     }

// //     if (bookingId.isNotEmpty) {
// //       body["booking_id"] = bookingId;
// //     }

// //     _log("REQUEST BODY: ${jsonEncode(body)}");

// //     final response = await http
// //         .post(
// //           uri,
// //           headers: {
// //             "Content-Type": "application/json",
// //             "Accept": "application/json",
// //             "Authorization": "Bearer $token",
// //             "Idempotency-Key": idempotencyKey,
// //           },
// //           body: jsonEncode(body),
// //         )
// //         .timeout(
// //           const Duration(seconds: 30),
// //         );

// //     _log("STEP 1 STATUS: ${response.statusCode}");
// //     _log("STEP 1 RESPONSE: ${response.body}");

// //     if (response.statusCode != 200 &&
// //         response.statusCode != 201 &&
// //         response.statusCode != 409) {
// //       _log(
// //         "❌ Upload API failed: "
// //         "${response.statusCode} ${response.body}",
// //       );
// //       return null;
// //     }

// //     if (response.body.trim().isEmpty) {
// //       _log("❌ Upload API returned empty response.");
// //       return null;
// //     }

// //     final decoded = jsonDecode(response.body);

// //     final Map<String, dynamic> data =
// //         decoded is Map<String, dynamic>
// //             ? (
// //                 decoded["response"] is Map
// //                     ? Map<String, dynamic>.from(
// //                         decoded["response"],
// //                       )
// //                     : decoded
// //               )
// //             : {};

// //     String? pick(List<String> keys) {
// //       for (final key in keys) {
// //         final value = data[key];

// //         if (value != null &&
// //             value.toString().trim().isNotEmpty) {
// //           return value.toString();
// //         }
// //       }

// //       return null;
// //     }

// //     final String? uploadUrl = pick([
// //       "upload_url",
// //       "uploadUrl",
// //       "presigned_url",
// //       "presignedUrl",
// //       "url",
// //     ]);

// //     final String? jobId = pick([
// //       "job_id",
// //       "jobId",
// //       "consultation_id",
// //       "consultationId",
// //       "id",
// //     ]);

// //     final String? s3Key = pick([
// //       "audio_s3_key",
// //       "s3_key",
// //       "s3Key",
// //       "key",
// //     ]);

// //     final Map<String, String> requiredHeaders = {};

// //     final rawHeaders =
// //         data["requiredHeaders"] ??
// //         data["required_headers"];

// //     if (rawHeaders is Map) {
// //       rawHeaders.forEach((key, value) {
// //         requiredHeaders[key.toString()] =
// //             value.toString();
// //       });
// //     }

// //     _log("UPLOAD URL: $uploadUrl");
// //     _log("JOB ID: $jobId");
// //     _log("S3 KEY: $s3Key");
// //     _log("REQUIRED HEADERS: $requiredHeaders");

// //     if (uploadUrl == null || uploadUrl.isEmpty) {
// //       _log("❌ upload_url missing from backend response.");
// //       return null;
// //     }

// //     if (jobId == null || jobId.isEmpty) {
// //       _log("❌ job_id missing from backend response.");
// //       return null;
// //     }

// //     if (s3Key == null || s3Key.isEmpty) {
// //       _log("❌ audio_s3_key missing from backend response.");
// //       return null;
// //     }

// //     return {
// //       "uploadUrl": uploadUrl,
// //       "job_id": jobId,
// //       "audio_s3_key": s3Key,
// //       "requiredHeaders": requiredHeaders,
// //     };
// //   } catch (e, stackTrace) {
// //     _log("❌ ERROR GETTING PRESIGNED URL: $e");
// //     _log(stackTrace.toString());
// //     return null;
// //   }
// // }
  
// //   // Future<bool> startUpload({
// //   //   required PendingConsultation task,
// //   //   required String uploadUrl,
// //   //   required Map<String, dynamic> headers,
// //   //   required Function(double) onProgress,
// //   // }) async {
// //   //   try {
// //   //     _log("Step 2: Uploading to S3...");
// //   //     final file = File(task.audioPath);
// //   //     final int totalBytes = await file.length();
// //   //     final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
// //   //     request.contentLength = totalBytes;

// //   //     headers.forEach((key, value) => request.headers[key.toString()] = value.toString());
// //   //     request.headers['Content-Type'] = 'audio/m4a';

// //   //     int bytesSent = 0;
// //   //     file.openRead().listen(
// //   //           (chunk) {
// //   //         bytesSent += chunk.length;
// //   //         onProgress(bytesSent / totalBytes);
// //   //         request.sink.add(chunk);
// //   //       },
// //   //       onDone: () => request.sink.close(),
// //   //       cancelOnError: true,
// //   //     );

// //   //     final streamedResponse = await request.send();
// //   //     return (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201);
// //   //   } catch (e) {
// //   //     _log("Error Step 2: $e");
// //   //     return false;
// //   //   }
// //   // }

// // Future<bool> startUpload({
// //   required PendingConsultation task,
// //   required String uploadUrl,
// //   required Map<String, dynamic> headers,
// //   required Function(double) onProgress,
// // }) async {
// //   try {
// //     final file = File(task.audioPath);

// //     if (!await file.exists()) {
// //       _log("❌ Audio file does not exist: ${task.audioPath}");
// //       return false;
// //     }

// //     final int totalBytes = await file.length();

// //     if (totalBytes <= 0) {
// //       _log("❌ Audio file is empty.");
// //       return false;
// //     }

// //     _log("================================================");
// //     _log("STEP 2 - S3 AUDIO UPLOAD");
// //     _log("S3 URL: $uploadUrl");
// //     _log("File: ${task.audioPath}");
// //     _log("Size: $totalBytes bytes");
// //     _log("Headers: $headers");
// //     _log("================================================");

// //     final request = http.StreamedRequest(
// //       "PUT",
// //       Uri.parse(uploadUrl),
// //     );

// //     request.contentLength = totalBytes;

// //     // IMPORTANT:
// //     // Use the headers returned by the backend.
// //     // Do not overwrite Content-Type afterward.
// //     headers.forEach((key, value) {
// //       request.headers[key.toString()] = value.toString();
// //     });

// //     int bytesSent = 0;

// //     final uploadFuture = request.send();

// //     await for (final chunk in file.openRead()) {
// //       bytesSent += chunk.length;

// //       if (totalBytes > 0) {
// //         final progress =
// //             bytesSent / totalBytes;

// //         onProgress(
// //           progress.clamp(0.0, 1.0),
// //         );
// //       }

// //       request.sink.add(chunk);
// //     }

// //     await request.sink.close();

// //     final response = await uploadFuture;

// //     _log(
// //       "S3 STATUS: ${response.statusCode}",
// //     );

// //     final responseBody =
// //         await response.stream.bytesToString();

// //     _log(
// //       "S3 RESPONSE: $responseBody",
// //     );

// //     if (response.statusCode == 200 ||
// //         response.statusCode == 201 ||
// //         response.statusCode == 204) {
// //       onProgress(1.0);
// //       _log("✅ S3 UPLOAD SUCCESS");
// //       return true;
// //     }

// //     _log(
// //       "❌ S3 UPLOAD FAILED: "
// //       "${response.statusCode}",
// //     );

// //     return false;
// //   } catch (e, stackTrace) {
// //     _log("❌ S3 UPLOAD ERROR: $e");
// //     _log(stackTrace.toString());

// //     return false;
// //   }
// // }

// // Future<bool> completeConsultation({
// //   required String jobId,
// //   required String doctorId,
// //   required String s3Key,
// //   required int durationSeconds,
// //   required String bookingId,
// // }) async {
// //   _log("STEP 3 - No separate backend endpoint");
// //   _log("Job ID: $jobId");
// //   _log("S3 Key: $s3Key");
// //   _log("Audio already uploaded successfully to S3.");

// //   return true;
// // }

// //   // Future<bool> completeConsultation({
// //   //   required String jobId,
// //   //   required String doctorId,
// //   //   required String s3Key,
// //   //   required int durationSeconds,
// //   //   required String bookingId,
// //   // }) async {
// //   //   try {
// //   //     final token = HiveStorage.getToken() ?? "";
// //   //     final response = await http.post(
// //   //       Uri.parse("${AppUrls.upload}/$jobId"),
// //   //       headers: {
// //   //         "Content-Type": "application/json",
// //   //         "Authorization": "Bearer $token",
// //   //       },
// //   //       body: jsonEncode({
// //   //         "doctor_id": doctorId,
// //   //         "audio-duration-seconds": durationSeconds,
// //   //         "audio_s3_key": s3Key,
// //   //         "booking_id": bookingId,
// //   //       }),
// //   //     );

// //   //     _log("Step 3 Status: ${response.statusCode}");

// //   //     // 🚩 FIX: Agar status 200, 201 ya 409 hai, to true return karein
// //   //     if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
// //   //       if (response.statusCode == 409) {
// //   //         _log("Backend says: Job already exists and is processing. Treating as success.");
// //   //       }
// //   //       return true; // Ab ye true return karega to UI isay delete kar degi
// //   //     }

// //   //     return false;
// //   //   } catch (e) {
// //   //     return false;
// //   //   }
// //   // }
// //   // Future<bool> completeConsultation({
// //   //   required String jobId,
// //   //   required String doctorId,
// //   //   required String s3Key,
// //   //   required int durationSeconds,
// //   //   required String bookingId,
// //   // }) async {
// //   //   // /upload already received audio_duration_seconds in Step 1,
// //   //   // so there is no separate "start" call on this backend.
// //   //   _log("Step 3 skipped: duration was sent with /upload "
// //   //       "($durationSeconds sec, job $jobId).");
// //   //   return true;
// //   // }

// // }

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
// //       _log("Step 1: Initiating Job -> ${AppUrls.upload}");

// //      final response = await http.post(
// //   Uri.parse(AppUrls.upload),
// //   headers: {
// //     "Content-Type": "application/json",
// //     "X-Idempotency-Key": idempotencyKey,
// //     "Authorization": "Bearer $token",
// //   },
// //   body: jsonEncode({
// //     "doctor-id": doctorId,
// //     "file-name": fileName,
// //     "audio-format": "audio/m4a",
// //     "patient_name": patientName,
// //     "patient_phone": patientPhone,
// //     "patient_age": patientAge,
// //     "patient_gender": patientGender,
// //     "booking_id": bookingId,
// //     "duration_seconds": durationSeconds,
// //   }),
// // );

// // _log("========================================");
// // _log("STEP 1 RESPONSE");
// // _log("Status Code: ${response.statusCode}");
// // _log("Response Body: ${response.body}");
// // _log("========================================");
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
// //     required String bookingId,
// //     required int durationSeconds,
// //   }) async {
// //     try {
// //       final token = HiveStorage.getToken() ?? "";
// //       final response = await http.post(
// //         Uri.parse("${AppUrls.upload}$jobId"),
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
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:math';

// // import 'package:http/http.dart' as http;

// // import '../model/pending_consultation.dart';
// // import '../utils/hive_storage.dart';
// // import 'app_url.dart';

// // class SyncService {
// //   // ============================================================
// //   // LOGGING
// //   // ============================================================

// //   void _log(String message) {
// //     print(
// //       "[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $message",
// //     );
// //   }

// //   // ============================================================
// //   // UUID GENERATOR
// //   // ============================================================

// //   String _generateUuid() {
// //     final random = Random.secure();

// //     final values = List<int>.generate(
// //       16,
// //       (i) => random.nextInt(256),
// //     );

// //     values[6] = (values[6] & 0x0f) | 0x40;
// //     values[8] = (values[8] & 0x3f) | 0x80;

// //     final buffer = StringBuffer();

// //     for (int i = 0; i < 16; i++) {
// //       if (i == 4 || i == 6 || i == 8 || i == 10) {
// //         buffer.write('-');
// //       }

// //       buffer.write(
// //         values[i].toRadixString(16).padLeft(2, '0'),
// //       );
// //     }

// //     return buffer.toString();
// //   }

// //   // ============================================================
// //   // STEP 1
// //   // INITIATE CONSULTATION
// //   // ============================================================

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

// //       _log(
// //         "Step 1: Initiating Job -> "
// //         "${AppUrls.initiateConsultation}",
// //       );

// //       _log(
// //         "Booking ID being sent: $bookingId",
// //       );

// //       // ==========================================================
// //       // REQUEST BODY
// //       // ==========================================================

// //       final Map<String, dynamic> requestBody = {
// //         "doctor_id": doctorId,
// //         "file_name": fileName,
// //         "audio-format": "audio/m4a",

// //         "patient_name": patientName,
// //         "patient_phone": patientPhone,
// //         "patient_age": patientAge,
// //         "patient_gender": patientGender,

// //         // IMPORTANT:
// //         // Send the actual booking ID to backend.
// //         "booking_id": bookingId,
// //       };

// //       // Add vitals if available
// //       if (vitals != null && vitals.isNotEmpty) {
// //         requestBody["vitals"] = vitals;
// //       }

// //       _log(
// //         "Step 1 Request Body: "
// //         "${jsonEncode(requestBody)}",
// //       );

// //       // ==========================================================
// //       // API CALL
// //       // ==========================================================

// //       final response = await http.post(
// //         Uri.parse(
// //           AppUrls.initiateConsultation,
// //         ),
// //         headers: {
// //           "Content-Type": "application/json",
// //           "X-Idempotency-Key": idempotencyKey,
// //           "Authorization": "Bearer $token",
// //         },
// //         body: jsonEncode(requestBody),
// //       );

// //       // ==========================================================
// //       // RESPONSE LOG
// //       // ==========================================================

// //       _log(
// //         "Step 1 Status: ${response.statusCode}",
// //       );

// //       _log(
// //         "Step 1 Response: ${response.body}",
// //       );

// //       // ==========================================================
// //       // SUCCESS
// //       // ==========================================================

// //       if (response.statusCode == 200 ||
// //           response.statusCode == 201 ||
// //           response.statusCode == 409) {
// //         final resData = jsonDecode(response.body);

// //         // ========================================================
// //         // REQUIRED HEADERS
// //         // ========================================================

// //         Map<String, String> headers = {};

// //         final rawHeaders =
// //             resData['requiredHeaders'] ??
// //             resData['required_headers'];

// //         if (rawHeaders != null && rawHeaders is Map) {
// //           rawHeaders.forEach(
// //             (key, value) {
// //               headers[key.toString()] = value.toString();
// //             },
// //           );
// //         }

// //         // ========================================================
// //         // RETURN DATA
// //         // ========================================================

// //         return {
// //           "uploadUrl":
// //               resData['upload_url'] ??
// //               resData['uploadUrl'],

// //           "job_id":
// //               resData['job_id'],

// //           "audio_s3_key":
// //               resData['audio_s3_key'],

// //           "requiredHeaders":
// //               headers,

// //           // Keep booking ID available
// //           // for the next step.
// //           "booking_id":
// //               bookingId,
// //         };
// //       }

// //       // ==========================================================
// //       // FAILURE
// //       // ==========================================================

// //       _log(
// //         "Step 1 failed: "
// //         "${response.statusCode}",
// //       );

// //       return null;
// //     } catch (e) {
// //       _log(
// //         "Error Step 1: $e",
// //       );

// //       return null;
// //     }
// //   }

// //   // ============================================================
// //   // STEP 2
// //   // UPLOAD AUDIO TO S3
// //   // ============================================================

// //   Future<bool> startUpload({
// //     required PendingConsultation task,
// //     required String uploadUrl,
// //     required Map<String, dynamic> headers,
// //     required Function(double) onProgress,
// //   }) async {
// //     try {
// //       _log(
// //         "Step 2: Uploading to S3...",
// //       );

// //       final file = File(task.audioPath);

// //       final int totalBytes = await file.length();

// //       if (totalBytes <= 0) {
// //         _log(
// //           "Step 2 failed: Audio file is empty.",
// //         );

// //         return false;
// //       }

// //       final request = http.StreamedRequest(
// //         'PUT',
// //         Uri.parse(uploadUrl),
// //       );

// //       request.contentLength = totalBytes;

// //       // ==========================================================
// //       // S3 HEADERS
// //       // ==========================================================

// //       headers.forEach(
// //         (key, value) {
// //           request.headers[key.toString()] =
// //               value.toString();
// //         },
// //       );

// //       request.headers['Content-Type'] =
// //           'audio/m4a';

// //       // ==========================================================
// //       // UPLOAD PROGRESS
// //       // ==========================================================

// //       int bytesSent = 0;

// //       file.openRead().listen(
// //         (chunk) {
// //           bytesSent += chunk.length;

// //           final progress =
// //               bytesSent / totalBytes;

// //           onProgress(
// //             progress.clamp(
// //               0.0,
// //               1.0,
// //             ),
// //           );

// //           request.sink.add(chunk);
// //         },
// //         onDone: () {
// //           request.sink.close();
// //         },
// //         cancelOnError: true,
// //       );

// //       // ==========================================================
// //       // SEND REQUEST
// //       // ==========================================================

// //       final streamedResponse =
// //           await request.send();

// //       _log(
// //         "Step 2 Status: "
// //         "${streamedResponse.statusCode}",
// //       );

// //       return streamedResponse.statusCode == 200 ||
// //           streamedResponse.statusCode == 201;
// //     } catch (e) {
// //       _log(
// //         "Error Step 2: $e",
// //       );

// //       return false;
// //     }
// //   }

// //   // ============================================================
// //   // STEP 3
// //   // START / COMPLETE CONSULTATION
// //   // ============================================================

// //   Future<bool> completeConsultation({
// //     required String jobId,
// //     required String doctorId,
// //     required String s3Key,
// //     required int durationSeconds,

// //     // IMPORTANT:
// //     // Booking ID is optional so older/offline calls
// //     // don't immediately break.
// //     String? bookingId,
// //   }) async {
// //     try {
// //       final token =
// //           HiveStorage.getToken() ?? "";

// //       // ==========================================================
// //       // REQUEST BODY
// //       // ==========================================================

// //       final Map<String, dynamic> requestBody = {
// //         "doctor_id": doctorId,
// //         "audio_duration_seconds":
// //             durationSeconds,
// //         "audio_s3_key":
// //             s3Key,
// //       };

// //       // ==========================================================
// //       // ADD BOOKING ID
// //       // ==========================================================

// //       if (bookingId != null &&
// //           bookingId.trim().isNotEmpty) {
// //         requestBody["booking_id"] =
// //             bookingId.trim();
// //       }

// //       _log(
// //         "Step 3 Booking ID: "
// //         "${bookingId ?? "Not provided"}",
// //       );

// //       _log(
// //         "Step 3 Request Body: "
// //         "${jsonEncode(requestBody)}",
// //       );

// //       // ==========================================================
// //       // API CALL
// //       // ==========================================================

// //       final response = await http.post(
// //         Uri.parse(
// //           "${AppUrls.startConsultation}"
// //           "$jobId/start",
// //         ),
// //         headers: {
// //           "Content-Type": "application/json",
// //           "Authorization": "Bearer $token",
// //         },
// //         body: jsonEncode(requestBody),
// //       );

// //       // ==========================================================
// //       // RESPONSE LOG
// //       // ==========================================================

// //       _log(
// //         "Step 3 Status: "
// //         "${response.statusCode}",
// //       );

// //       _log(
// //         "Step 3 Response: "
// //         "${response.body}",
// //       );

// //       // ==========================================================
// //       // SUCCESS
// //       // ==========================================================

// //       if (response.statusCode == 200 ||
// //           response.statusCode == 201 ||
// //           response.statusCode == 409) {
// //         if (response.statusCode == 409) {
// //           _log(
// //             "Backend says: Job already exists "
// //             "and is processing. Treating as success.",
// //           );
// //         }

// //         return true;
// //       }

// //       // ==========================================================
// //       // FAILURE
// //       // ==========================================================

// //       _log(
// //         "Step 3 failed.",
// //       );

// //       return false;
// //     } catch (e) {
// //       _log(
// //         "Error Step 3: $e",
// //       );

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
//   void _log(String message) {
//     print("[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $message");
//   }

//   String _generateUuid() {
//     final random = Random.secure();
//     final values = List<int>.generate(16, (i) => random.nextInt(256));
//     values[6] = (values[6] & 0x0f) | 0x40;
//     values[8] = (values[8] & 0x3f) | 0x80;
//     final buffer = StringBuffer();
//     for (int i = 0; i < 16; i++) {
//       if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
//       buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
//     }
//     return buffer.toString();
//   }

// Future<Map<String, dynamic>?> getPresignedData({
//   required String fileName,
//   required String doctorId,
//   required String patientName,
//   required String patientPhone,
//   required String patientAge,
//   required String patientGender,
//   required String patientId,
//   required String bookingId,
//   int durationSeconds = 0,
//   Map<String, dynamic>? vitals,
// }) async {
//   try {
//     final token = HiveStorage.getToken() ?? "";
//     final idempotencyKey = _generateUuid();

//     final uri = Uri.parse(AppUrls.upload);

//     _log("================================================");
//     _log("STEP 1 - INITIATE CONSULTATION");
//     _log("URL: $uri");
//     _log("Doctor ID: '$doctorId'");
//     _log("Patient Name: '$patientName'");
//     _log("Patient Phone: '$patientPhone'");
//     _log("Patient ID: '$patientId'");
//     _log("Patient Age: '$patientAge'");
//     _log("Patient Gender: '$patientGender'");
//     _log("Booking ID: '$bookingId'");
//     _log("Duration: $durationSeconds");
//     _log("================================================");

//     final Map<String, dynamic> requestBody = {
//       "doctor-id": doctorId,
//       "file-name": fileName,
//       "audio-format": "audio/m4a",

//       "patient_name": patientName,
//       "patient_phone": patientPhone,
//       "patient_age": patientAge,
//       "patient_gender": patientGender,

//       "booking_id": bookingId,

//       "duration_seconds": durationSeconds,

//       "vitals": vitals ?? {},
//     };

//     if (patientId.trim().isNotEmpty) {
//       requestBody["patient_id"] = patientId.trim();
//     }

//     _log("REQUEST BODY:");
//     _log(jsonEncode(requestBody));

//     final response = await http
//         .post(
//           uri,
//           headers: {
//             "Content-Type": "application/json",
//             "Accept": "application/json",
//             "X-Idempotency-Key": idempotencyKey,
//             "Authorization": "Bearer $token",
//           },
//           body: jsonEncode(requestBody),
//         )
//         .timeout(
//           const Duration(seconds: 30),
//         );

//     _log("================================================");
//     _log("STEP 1 RESPONSE");
//     _log("STATUS CODE: ${response.statusCode}");
//     _log("RESPONSE BODY: ${response.body}");
//     _log("================================================");

//     // SUCCESS
//     if (response.statusCode == 200 ||
//         response.statusCode == 201 ||
//         response.statusCode == 409) {
      
//       if (response.body.trim().isEmpty) {
//         _log("❌ Backend returned empty response.");
//         return null;
//       }

//       final decoded = jsonDecode(response.body);

//       final Map<String, dynamic> data =
//           decoded is Map<String, dynamic>
//               ? (
//                   decoded["response"] is Map
//                       ? Map<String, dynamic>.from(
//                           decoded["response"],
//                         )
//                       : decoded
//                 )
//               : {};

//       String? pick(List<String> keys) {
//         for (final key in keys) {
//           final value = data[key];

//           if (value != null &&
//               value.toString().trim().isNotEmpty) {
//             return value.toString();
//           }
//         }

//         return null;
//       }

//       final String? uploadUrl = pick([
//         "upload_url",
//         "uploadUrl",
//         "presigned_url",
//         "presignedUrl",
//         "url",
//       ]);

//       final String? jobId = pick([
//         "job_id",
//         "jobId",
//         "consultation_id",
//         "consultationId",
//         "id",
//       ]);

//       final String? s3Key = pick([
//         "audio_s3_key",
//         "s3_key",
//         "s3Key",
//         "key",
//       ]);

//       final Map<String, String> requiredHeaders = {};

//       final rawHeaders =
//           data["requiredHeaders"] ??
//           data["required_headers"];

//       if (rawHeaders is Map) {
//         rawHeaders.forEach((key, value) {
//           requiredHeaders[key.toString()] =
//               value.toString();
//         });
//       }

//       _log("UPLOAD URL: $uploadUrl");
//       _log("JOB ID: $jobId");
//       _log("S3 KEY: $s3Key");
//       _log("REQUIRED HEADERS: $requiredHeaders");

//       if (uploadUrl == null || uploadUrl.isEmpty) {
//         _log("❌ upload_url missing from backend response.");
//         return null;
//       }

//       if (jobId == null || jobId.isEmpty) {
//         _log("❌ job_id missing from backend response.");
//         return null;
//       }

//       if (s3Key == null || s3Key.isEmpty) {
//         _log("❌ audio_s3_key missing from backend response.");
//         return null;
//       }

//       return {
//         "uploadUrl": uploadUrl,
//         "job_id": jobId,
//         "audio_s3_key": s3Key,
//         "requiredHeaders": requiredHeaders,
//         "booking_id": bookingId,
//       };
//     }

//     // FAILURE
//     _log(
//       "❌ STEP 1 FAILED: "
//       "${response.statusCode}",
//     );

//     _log(
//       "❌ BACKEND ERROR BODY: "
//       "${response.body}",
//     );

//     return null;
//   } catch (e, stackTrace) {
//     _log("❌ ERROR GETTING PRESIGNED URL: $e");
//     _log(stackTrace.toString());

//     return null;
//   }
// }
//   Future<bool> startUpload({
//     required PendingConsultation task,
//     required String uploadUrl,
//     required Map<String, dynamic> headers,
//     required Function(double) onProgress,
//   }) async {
//     try {
//       _log("Step 2: Uploading to S3...");
//       final file = File(task.audioPath);
//       final int totalBytes = await file.length();
//       final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
//       request.contentLength = totalBytes;

//       headers.forEach((key, value) => request.headers[key.toString()] = value.toString());
//       request.headers['Content-Type'] = 'audio/m4a';

//       int bytesSent = 0;
//       file.openRead().listen(
//             (chunk) {
//           bytesSent += chunk.length;
//           onProgress(bytesSent / totalBytes);
//           request.sink.add(chunk);
//         },
//         onDone: () => request.sink.close(),
//         cancelOnError: true,
//       );

//       final streamedResponse = await request.send();
//       return (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201);
//     } catch (e) {
//       _log("Error Step 2: $e");
//       return false;
//     }
//   }

//   Future<bool> completeConsultation({
//     required String jobId,
//     required String doctorId,
//     required String s3Key,
//     required int durationSeconds,
//     required String bookingId,
//   }) async {
//     try {
//       final token = HiveStorage.getToken() ?? "";
//       final response = await http.post(
//         Uri.parse("${AppUrls.upload}$jobId/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({
//           "doctor_id": doctorId,
//           "audio_duration_seconds": durationSeconds,
//           "audio_s3_key": s3Key,
//           "booking_id": bookingId,
//         }),
//       );

//       _log("Step 3 Status: ${response.statusCode}");

//       // 🚩 FIX: Agar status 200, 201 ya 409 hai, to true return karein
//       if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
//         if (response.statusCode == 409) {
//           _log("Backend says: Job already exists and is processing. Treating as success.");
//         }
//         return true; // Ab ye true return karega to UI isay delete kar degi
//       }

//       return false;
//     } catch (e) {
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
  void _log(String m) =>
      print("[${DateTime.now().toIso8601String()}][SYNC-SERVICE] $m");

  String _generateUuid() {
    final r = Random.secure();
    final v = List<int>.generate(16, (_) => r.nextInt(256));
    v[6] = (v[6] & 0x0f) | 0x40;
    v[8] = (v[8] & 0x3f) | 0x80;
    final b = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) b.write('-');
      b.write(v[i].toRadixString(16).padLeft(2, '0'));
    }
    return b.toString();
  }

  // STEP 1
  Future<Map<String, dynamic>?> getPresignedData({
    required String fileName,
    required String doctorId,
    required String patientName,
    required String patientPhone,
    required String patientAge,
    required String patientGender,
    required String patientId,
    required String bookingId,
    int durationSeconds = 0,
    Map<String, dynamic>? vitals,
  }) async {
    try {
      final token = HiveStorage.getToken() ?? "";

      final body = <String, dynamic>{
        "doctor-id": doctorId,
        "file-name": fileName,
        "audio-format": "audio/m4a",
        "patient_name": patientName,
        "patient_phone": patientPhone,
        "patient_age": patientAge,
        "patient_gender": patientGender,
        "audio-duration-seconds": durationSeconds,
        "vitals": vitals ?? {},
      };
      // Only send IDs when they exist (walk-in patients have no booking).
      if (patientId.trim().isNotEmpty) body["patient_id"] = patientId.trim();
      if (bookingId.trim().isNotEmpty) body["booking_id"] = bookingId.trim();

      _log("STEP 1 body: ${jsonEncode(body)}");

      final response = await http
          .post(
            Uri.parse(AppUrls.upload),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Idempotency-Key": _generateUuid(),
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      _log("STEP 1 status: ${response.statusCode} body: ${response.body}");

      if (![200, 201, 409].contains(response.statusCode)) return null;
      if (response.body.trim().isEmpty) return null;

      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map
          ? (decoded["response"] is Map
              ? Map<String, dynamic>.from(decoded["response"])
              : Map<String, dynamic>.from(decoded))
          : {};

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = data[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return null;
      }

      final uploadUrl =
          pick(["upload_url", "uploadUrl", "presigned_url", "presignedUrl", "url"]);
      final jobId = pick(["job_id", "jobId", "consultation_id", "consultationId", "id"]);
      final s3Key = pick(["audio_s3_key", "s3_key", "s3Key", "key"]);

      final headers = <String, String>{};
      final raw = data["requiredHeaders"] ?? data["required_headers"];
      if (raw is Map) raw.forEach((k, v) => headers[k.toString()] = v.toString());

      if (uploadUrl == null || jobId == null || s3Key == null) {
        _log("❌ Missing upload_url / job_id / audio_s3_key");
        return null;
      }

      return {
        "uploadUrl": uploadUrl,
        "job_id": jobId,
        "audio_s3_key": s3Key,
        "requiredHeaders": headers,
        "booking_id": bookingId,
      };
    } catch (e, st) {
      _log("❌ Step 1 error: $e\n$st");
      return null;
    }
  }

  // STEP 2
Future<bool> startUpload({
  required PendingConsultation task,
  required String uploadUrl,
  required Map<String, dynamic> headers,
  required Function(double) onProgress,
}) async {
  try {
    _log("STEP 2.1: Starting S3 upload");

    final file = File(task.audioPath);

    if (!await file.exists()) {
      _log("❌ STEP 2.2: File does not exist");
      return false;
    }

    final int totalBytes = await file.length();

    if (totalBytes <= 0) {
      _log("❌ STEP 2.3: File is empty");
      return false;
    }

    _log("STEP 2.3: File size = $totalBytes");

    // Read the complete file.
    final bytes = await file.readAsBytes();

    _log("STEP 2.4: File loaded into memory");

    // Use ONLY headers returned by backend.
    final requestHeaders = <String, String>{};

    headers.forEach((key, value) {
      requestHeaders[key.toString()] = value.toString();
    });

    // Do NOT manually add Content-Type here unless
    // backend sends it in requiredHeaders.
    _log("STEP 2.5: Headers = $requestHeaders");

    final request = http.Request(
      'PUT',
      Uri.parse(uploadUrl),
    );

    request.headers.addAll(requestHeaders);

    // This explicitly gives S3 a fixed Content-Length
    // instead of Transfer-Encoding: chunked.
    request.headers['Content-Length'] = bytes.length.toString();

    request.bodyBytes = bytes;

    _log("STEP 2.6: Sending PUT to S3");
    _log("STEP 2.7: Content-Length = ${bytes.length}");

    onProgress(0.0);

    final streamedResponse = await request.send();

    _log(
      "STEP 2.8: S3 response = "
      "${streamedResponse.statusCode}",
    );

    final responseBody =
        await streamedResponse.stream.bytesToString();

    _log("STEP 2.9: S3 body = $responseBody");

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201 ||
        streamedResponse.statusCode == 204) {
      onProgress(1.0);

      _log("✅ STEP 2: S3 UPLOAD SUCCESS");

      return true;
    }

    _log(
      "❌ STEP 2: S3 UPLOAD FAILED "
      "${streamedResponse.statusCode}",
    );

    return false;
  } catch (e, st) {
    _log("❌ STEP 2 ERROR: $e");
    _log("STACK: $st");

    return false;
  }
}
  // STEP 3
//   Future<bool> completeConsultation({
//   required String jobId,
//   required String doctorId,
//   required String s3Key,
//   required int durationSeconds,
//   required String patientName,
//   required String patientPhone,
//   String bookingId = "",
// }) async {
//     try {
//       final token = HiveStorage.getToken() ?? "";
//       final body = <String, dynamic>{
//         "doctor_id": doctorId,
//         "audio-duration-seconds": durationSeconds,
//         "audio_s3_key": s3Key,
//         "patient_name": patientName,
//         "patient_phone": patientPhone,
//         if (bookingId.trim().isNotEmpty) "booking_id": bookingId.trim(),
//       };

//       final response = await http
//           .post(
// Uri.parse("${AppUrls.upload}"),
//             headers: {
//               "Content-Type": "application/json",
//               "Authorization": "Bearer $token",
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 30));

//       _log("Step 3 status: ${response.statusCode} ${response.body}");

//       // 409 = already processing -> treat as success
//       return [200, 201, 409].contains(response.statusCode);
//     } catch (e) {
//       _log("❌ Step 3 error: $e");
//       return false;
//     }
//   }

Future<bool> completeConsultation({
  required String jobId,
  required String doctorId,
  required String s3Key,
  required int durationSeconds,
  required String patientName,
  required String patientPhone,
  String bookingId = "",
}) async {
  _log("========================================");
  _log("STEP 3 - SKIPPED");
  _log("Job ID: $jobId");
  _log("S3 Key: $s3Key");
  _log("Duration: $durationSeconds");
  _log("Audio was already uploaded to S3 successfully.");
  _log("========================================");

  return true;
}


}