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