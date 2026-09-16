import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/model/pending_consultation.dart';
import 'package:medicalai/repository/Repository.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/services/upload_service.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../utils/noInternet.dart';

class ManualUploadProgressScreen extends StatefulWidget {
  const ManualUploadProgressScreen({super.key});

  @override
  State<ManualUploadProgressScreen> createState() =>
      _ManualUploadProgressScreenState();
}

class _ManualUploadProgressScreenState
    extends State<ManualUploadProgressScreen> {
  final SyncService _syncService = SyncService();
  final Repository _repository = Repository();

  PendingConsultation? _task;
  dynamic _hiveKey;

  double _progress = 0.0;

  bool _isStarted = false;
  bool _isVerifying = true;

  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isStarted) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      _hiveKey = args['hiveKey'];

      _task = HiveStorage.getConsultationByKey(_hiveKey);

      if (_task != null) {
        _startSyncProcess();
      } else {
        Navigator.pop(context);
      }

      _isStarted = true;
    }
  }

  void _log(String msg) {
    print("[MANUAL-SYNC-UI] $msg");
  }

  Future<void> _handleAbort(String message) async {
    await HiveStorage.setSyncingStatus(_hiveKey, false);

    if (mounted) {
      utils.toastMessage(message);
      Navigator.pop(context);
    }
  }

  Future<void> _startSyncProcess() async {
    if (_task == null) return;

    try {
      if (mounted) {
        setState(() {
          _isVerifying = true;
        });
      }

      // ============================================================
      // IMPORTANT: GET ACTUAL BOOKING ID
      // ============================================================

      final String bookingId = (_task!.bookingId ?? "").toString().trim();

      final String patientId =
          (_task!.patientId ?? "").toString().trim();

      _log("========================================");
      _log("MANUAL UPLOAD STARTED");
      _log("Patient Name: ${_task!.patientName}");
      _log("Patient ID: $patientId");
      _log("Booking ID: $bookingId");
      _log("Hive Key: $_hiveKey");
      _log("========================================");

      // Booking ID is required for booking deletion and backend
      // consultation association.
      if (bookingId.isEmpty) {
        _log("❌ BOOKING ID IS EMPTY");

        await _handleAbort(
          "Booking ID missing. Audio saved in Outbox.",
        );

        return;
      }

      // ============================================================
      // 1. CONNECTIVITY CHECK
      // ============================================================

      if (!await hasInternet() ||
          !await _repository.checkServerHealth()) {
        await _handleAbort("Network error.");
        return;
      }

      final String doctorEmail =
          (HiveStorage.getUserEmail() ?? "1").trim().toLowerCase();

      final String fileName =
          _task!.audioPath.split(Platform.pathSeparator).last;

      final Map<String, dynamic> vitalsMap = {
        "temperature": _task!.temp,
        "pulse": _task!.pulse,
        "respiration": _task!.resp,
        "blood pressure": _task!.bp,
        "sugar": _task!.sugar,
      };

      // ============================================================
      // STEP 1: INITIATE CONSULTATION
      // ============================================================

      _log("STEP 1: Initiating consultation...");
      _log("Booking ID sent: $bookingId");

      final apiData = await _syncService.getPresignedData(
        fileName: fileName,
        doctorId: doctorEmail,
        patientName: _task!.patientName,

        // IMPORTANT:
        // Use bookingId, NOT patientId.
        bookingId: bookingId,

        patientPhone: _task!.patientPhone,
        patientId: patientId,
        patientAge: _task!.age,
        patientGender: _task!.gender,
        vitals: vitalsMap,
      );

      if (apiData == null || apiData['uploadUrl'] == null) {
        _log("❌ Failed to get presigned upload URL.");

        await _handleAbort(
          "Failed to get secure link.",
        );

        return;
      }

      _log("✅ Presigned URL received.");
      _log("Job ID: ${apiData['job_id']}");
      _log("S3 Key: ${apiData['audio_s3_key']}");

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _progress = 0.0;
        });
      }

      // ============================================================
      // STEP 2: UPLOAD AUDIO TO S3
      // ============================================================

      _log("STEP 2: Starting S3 upload...");

      final bool uploadSuccess = await _syncService.startUpload(
        task: _task!,
        uploadUrl: apiData['uploadUrl'],
        headers: apiData['requiredHeaders'] ?? {},
        onProgress: (double p) {
          if (mounted) {
            setState(() {
              _progress = p;
            });
          }
        },
      );

      if (!uploadSuccess) {
        _log("❌ S3 upload failed.");

        await _handleAbort(
          "Upload failed. Try again later.",
        );

        return;
      }

      _log("✅ S3 upload successful.");

      // ============================================================
      // STEP 3: COMPLETE CONSULTATION
      // ============================================================

      _log("STEP 3: Notifying backend...");

      int duration =
          _task!.endTime.difference(_task!.startTime).inSeconds;

      if (duration <= 0) {
        duration = 60;
      }

      _log("Audio duration: $duration seconds");
      _log("Booking ID: $bookingId");

      final bool step3Success =
          await _syncService.completeConsultation(
        jobId: apiData['job_id'],
        doctorId: doctorEmail,
        s3Key: apiData['audio_s3_key'],
        durationSeconds: duration,

        // IMPORTANT:
        // Use actual booking ID here too.
        bookingId: bookingId,
      );

      if (!step3Success) {
        _log("❌ STEP 3 FAILED.");

        await _handleAbort(
          "Server was busy. Audio saved in Outbox.",
        );

        return;
      }

      _log("✅ STEP 3 SUCCESSFUL.");
      _log("Consultation processing completed.");

      // ============================================================
      // STEP 4: DELETE BOOKING
      // ============================================================

      _log("========================================");
      _log("STEP 4: DELETING BOOKING");
      _log("Booking ID: $bookingId");
      _log("========================================");

      final String token = HiveStorage.getToken() ?? "";

      if (token.isEmpty) {
        _log("❌ TOKEN IS EMPTY.");

        await _handleAbort(
          "Authentication token missing. Audio saved in Outbox.",
        );

        return;
      }

      final bool bookingDeleted =
          await _repository.deleteBookedPatientApi(
        bookingId,
        token,
      );

      if (!bookingDeleted) {
        _log("❌ BOOKING DELETE FAILED.");

        await _handleAbort(
          "Consultation uploaded, but booking could not be removed.",
        );

        return;
      }

      _log("✅ BOOKING DELETED SUCCESSFULLY.");
      _log("Deleted booking ID: $bookingId");

      // ============================================================
      // STEP 5: REMOVE FROM LOCAL OUTBOX
      // ============================================================

      _log("STEP 5: Removing consultation from Outbox...");

      await HiveStorage.removeFromOutbox(_hiveKey);

      await HiveStorage.incrementServerBatch();

      _log("✅ Outbox item removed.");
      _log("========================================");
      _log("UPLOAD + DELETE FLOW COMPLETED");
      _log("========================================");

      // ============================================================
      // STEP 6: GO TO ACKNOWLEDGEMENT SCREEN
      // ============================================================

      if (mounted) {
        utils.toastMessage("Upload Successful!");

        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.acknowledgment_screen,
          (route) =>
              route.settings.name == RouteNames.dashboard,
          arguments: {
            "name_patient": _task!.patientName,
            "duration": "Saved",
          },
        );
      }
    } catch (e, stackTrace) {
      _log("========================================");
      _log("❌ GENERAL ERROR");
      _log("$e");
      _log("$stackTrace");
      _log("========================================");

      await HiveStorage.setSyncingStatus(
        _hiveKey,
        false,
      );

      if (mounted) {
        utils.toastMessage(
          "Upload failed. Audio saved in Outbox.",
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isVerifying
                    ? const CupertinoActivityIndicator(
                        radius: 20,
                      )
                    : const Icon(
                        Icons.cloud_sync_outlined,
                        size: 80,
                        color: Colorprimary,
                      ),

                const SizedBox(height: 30),

                Text(
                  _isVerifying
                      ? "Verifying Connection"
                      : "Uploading Consultation",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colorprimary,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Patient: ${_task?.patientName ?? '...'}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                if (!_isVerifying)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 160,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade100,
                          color: Colorprimary,
                        ),
                      ),
                      Text(
                        "${(_progress * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colorprimary,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    "Preparing secure link...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 50),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blueGrey.shade100,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Keep NourDoc Open",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Text(
                        "Please stay on this screen while the consultation is being secured.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}