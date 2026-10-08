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
  print("========== HIVE TASK DEBUG ==========");
  print("Hive Key: $_hiveKey");
  print("Patient Name: '${_task!.patientName}'");
  print("Patient Phone: '${_task!.patientPhone}'");
  print("Patient ID: '${_task!.patientId}'");
  print("Age: '${_task!.age}'");
  print("Gender: '${_task!.gender}'");
  print("Booking ID: '${_task!.bookingId}'");
  print("Duration: ${_task!.durationSeconds}");
  print("====================================");
}

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
 
  bool serverAccepted = false; // true once Step 3 succeeds
 
  try {
    if (mounted) setState(() => _isVerifying = true);
 
    final String bookingId = (_task!.bookingId ?? "").toString().trim();
    final String patientId = (_task!.patientId ?? "").toString().trim();
    final bool isWalkIn = bookingId.isEmpty;
 
    _log("MANUAL UPLOAD: ${_task!.patientName} booking='$bookingId' walkIn=$isWalkIn");
 
    // 1. Connectivity
    if (!await hasInternet() || !await _repository.checkServerHealth()) {
      await _handleAbort("Network error.");
      return;
    }
 
    // FIX: no "1" fallback
    final String doctorEmail =
        (HiveStorage.getUserEmail() ?? "").trim().toLowerCase();
    if (doctorEmail.isEmpty) {
      await _handleAbort("Session expired. Please log in again.");
      return;
    }
 
    final String fileName =
        _task!.audioPath.split(Platform.pathSeparator).last;
 
    // FIX: real duration from Hive, fallback to start/end (no fake 60)
    int duration = _task!.durationSeconds;
    if (duration <= 0) {
      duration = _task!.endTime.difference(_task!.startTime).inSeconds;
    }
    if (duration < 0) duration = 0;
 
    final vitals = {
      "temperature": _task!.temp,
      "pulse": _task!.pulse,
      "respiration": _task!.resp,
      "blood pressure": _task!.bp,
      "sugar": _task!.sugar,
    };
 
    // STEP 1
    final apiData = await _syncService.getPresignedData(
      fileName: fileName,
      doctorId: doctorEmail,
      patientName: _task!.patientName,
      patientPhone: _task!.patientPhone,
      patientAge: _task!.age,
      patientGender: _task!.gender,
      patientId: patientId,
      bookingId: bookingId,
      durationSeconds: duration,
      vitals: vitals,
    );
 
    if (apiData == null) {
      await _handleAbort("Failed to get secure link.");
      return;
    }
 
    if (mounted) setState(() { _isVerifying = false; _progress = 0.0; });
 
    // STEP 2
    final ok = await _syncService.startUpload(
      task: _task!,
      uploadUrl: apiData['uploadUrl'],
      headers: apiData['requiredHeaders'] ?? {},
      onProgress: (p) { if (mounted) setState(() => _progress = p); },
    );
    if (!ok) {
      await _handleAbort("Upload failed. Try again later.");
      return;
    }
 
    // STEP 3
    final step3 = await _syncService.completeConsultation(
      jobId: apiData['job_id'],
      doctorId: doctorEmail,
      s3Key: apiData['audio_s3_key'],
      durationSeconds: duration,
      patientName: _task!.patientName,
      patientPhone: _task!.patientPhone,
      bookingId: bookingId,
    );
    if (!step3) {
      await _handleAbort("Server was busy. Audio saved in Outbox.");
      return;
    }
    serverAccepted = true;
 
    // ---- From here the server HAS the consultation. Nothing below may
    // ---- cause a retry, or the consultation would be uploaded twice.
 
    // STEP 4: delete booking (booked patients only, failure is non-fatal)
    if (!isWalkIn) {
      try {
        final token = HiveStorage.getToken() ?? "";
        await _repository.deleteBookedPatientApi(bookingId, token);
      } catch (e) {
        _log("⚠️ Booking delete failed (non-fatal): $e");
      }
      try {
        await HiveStorage.markBookingCompleted(bookingId); // blocks re-consult
      } catch (e) {
        _log("⚠️ markBookingCompleted failed: $e");
      }
    }
 
    // STEP 5: clear outbox
    try {
      await HiveStorage.removeFromOutbox(_hiveKey);
      await HiveStorage.incrementServerBatch();
    } catch (e) {
      _log("⚠️ Outbox cleanup failed: $e");
    }
 
    if (mounted) {
      utils.toastMessage("Upload Successful!");
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.acknowledgment_screen,
        (r) => r.settings.name == RouteNames.dashboard,
        arguments: {"name_patient": _task!.patientName, "duration": "Saved"},
      );
    }
  } catch (e, st) {
    _log("❌ GENERAL ERROR: $e\n$st");
    if (serverAccepted) {
      // server has it; don't leave a duplicate in the outbox
      try { await HiveStorage.removeFromOutbox(_hiveKey); } catch (_) {}
    } else {
      await HiveStorage.setSyncingStatus(_hiveKey, false);
    }
    if (mounted) {
      utils.toastMessage(serverAccepted
          ? "Uploaded successfully."
          : "Upload failed. Audio saved in Outbox.");
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