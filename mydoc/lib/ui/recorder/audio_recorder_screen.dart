import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:medicalai/ui/consultation_viewmodel.dart';
import 'package:record/record.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/services/upload_service.dart'; // 🚩 Ensure this import is correct
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../main.dart';
import '../../model/pending_consultation.dart';
import '../../repository/Repository.dart';
import '../../utils/appDialog.dart';
import '../../utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioRecorder _recorder = AudioRecorder();
  final RecorderController _waveController = RecorderController();
  final AudioPlayer _beepPlayer = AudioPlayer(playerId: 'nourdoc_beep_player');
  final AudioPlayer _warningPlayer = AudioPlayer(playerId: 'nourdoc_warning_player');
  final Repository _repository = Repository();
  final SyncService _syncService = SyncService(); // 🚩 Updated SyncService instance

  int? _currentConsultationKey;
  bool _waitingForLimitExtension = false;
  bool _isHandlingLimit = false;
  int _maxDurationMinutes = 5;
  bool _isRecording = false;
  bool _isPaused = false;
  String filename = '${utils.generatePincode()}.m4a';
  bool _isVerifying = false;

  String _patientName = "", _bookingId = "", _patientPhone = "", _patientId = "", _age = "", _dob = "", _gender = "", _visitType = "";
  String _vitalsTemp = "", _vitalsPulse = "", _vitalsResp = "", _vitalsBP = "", _vitalsSugar = "";
  bool _argsLoaded = false;
  DateTime? _recordingStartTime;
  DateTime? _recordingEndTime;

  Map<String, dynamic> _getVitalsMap() {
    return {
      "Temperature": _vitalsTemp,
      "Pulse": _vitalsPulse,
      "Respiration": _vitalsResp,
      "Blood Pressure": _vitalsBP,
      "Sugar": _vitalsSugar,
    };
  }

  bool _isLoading = false;
  bool _isRecorderControl = false;
  bool _consultationFinished = false;
  double _uploadProgress = 0.0;
  bool _isUploadingRightNow = false;

  int _seconds = 0, _minutes = 0, _hours = 0;
  Timer? _timer;
  int _remainingSeconds = 300;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showMicReminder = false;
  bool _reminderLoopActive = false;
  bool _cancelReminderLoop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _setupAudio();
    Timer(const Duration(seconds: 10), () {
      if (!_isRecording && !_isRecorderControl && mounted) _runReminderLoop();
    });
  }

  void _log(String msg) => print("[AUDIO-UI ${DateTime.now().toIso8601String()}] $msg");

  String formatDurationReadable(int h, int m, int s) {
    if (h > 0) return "$h hr $m min";
    if (m > 0) return "$m min $s sec";
    return "$s sec";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map) {
        _patientPhone = args["patient_phone"]?.toString() ?? "";
        _bookingId = args["booking_id"]?.toString() ?? "";
        _patientName = args["name_patient"]?.toString() ?? "";
        _patientId = args["patient_id"]?.toString() ?? "";
        _gender = args["gender"]?.toString() ?? "";
        _age = args["age"]?.toString() ?? "";
        _dob = args["dob"]?.toString() ?? "";
        _visitType = args["visit_type"]?.toString() ?? "";

        debugPrint("========================================");
debugPrint("BOOKED PATIENT RECORDER ARGUMENTS");
debugPrint("Patient Name: $_patientName");
debugPrint("Booking ID: $_bookingId");
debugPrint("Patient ID: $_patientId");
debugPrint("Phone: $_patientPhone");
debugPrint("Age: $_age");
debugPrint("Gender: $_gender");
debugPrint("========================================");

        String clean(dynamic val) {
          String s = val?.toString() ?? "";
          return (s.toLowerCase() == "null" || s.isEmpty) ? "" : s;
        }

        if (args.containsKey("vitals") && args["vitals"] is Map) {
          final vMap = args["vitals"] as Map;
          _vitalsTemp = clean(vMap["Temperature"]);
          _vitalsPulse = clean(vMap["Pulse"]);
          _vitalsResp = clean(vMap["Respiration"]);
          _vitalsBP = clean(vMap["Blood Pressure"]);
          _vitalsSugar = clean(vMap["Sugar"]);
        } else {
          _vitalsTemp = clean(args["temp"]);
          _vitalsPulse = clean(args["pulse"]);
          _vitalsResp = clean(args["resp_rate"]);
          _vitalsBP = clean(args["bp"]);
          _vitalsSugar = clean(args["sugar"]);
        }
        _argsLoaded = true;
      }
    }
  }

  void _setupAudio() async {
    final audioContext = AudioContext(iOS: AudioContextIOS(category: AVAudioSessionCategory.playback), android: AudioContextAndroid(usageType: AndroidUsageType.media));
    AudioPlayer.global.setAudioContext(audioContext);
    await _beepPlayer.setVolume(0.4);
    await _warningPlayer.setVolume(0.8);
  }

  Future<void> _runReminderLoop() async {
    if (_reminderLoopActive || _isRecording || _isRecorderControl || !mounted) return;
    _reminderLoopActive = true;
    while (!_cancelReminderLoop && !_isRecording && !_isRecorderControl && mounted) {
      setState(() => _showMicReminder = true);
      _pulseController.repeat(reverse: true);
      _beepPlayer.play(AssetSource('sounds/beep.mp3'));
      await Future.delayed(const Duration(seconds: 3));
      if (_cancelReminderLoop || !mounted) break;
      setState(() => _showMicReminder = false);
      _pulseController.stop();
      await Future.delayed(const Duration(seconds: 7));
    }
    _reminderLoopActive = false;
  }

 Future<void> _startManualSync(int hiveKey) async {
  final task = HiveStorage.getConsultationByKey(hiveKey);

  if (task == null) {
    _log("❌ Consultation task not found for Hive key: $hiveKey");
    return;
  }

  try {
    setState(() {
      _isVerifying = true;
      _uploadProgress = 0.0;
    });

    final String doctorEmail =
        (HiveStorage.getUserEmail() ?? "").trim().toLowerCase();

    // ============================================================
    // STEP 1: INITIATE CONSULTATION
    // ============================================================

    _log("========== STEP 1: INITIATE ==========");
    _log("Doctor ID: $doctorEmail");
    _log("Booking ID: $_bookingId");

    final apiData = await _syncService.getPresignedData(
      fileName: filename,
      doctorId: doctorEmail,
      patientName: _patientName,
      patientPhone: _patientPhone,
      patientAge: _age,
      patientGender: _gender,
      patientId: _patientId,
      bookingId: _bookingId,
      vitals: _getVitalsMap(),
      durationSeconds: task.durationSeconds,
    );


    if (apiData == null) {
      throw Exception("Step 1 failed");
    }

    _log("✅ STEP 1 SUCCESS");
    _log("Job ID: ${apiData['job_id']}");
    _log("S3 Key: ${apiData['audio_s3_key']}");

    // ============================================================
    // STEP 2: UPLOAD AUDIO TO S3
    // ============================================================

    _log("========== STEP 2: S3 UPLOAD ==========");

    final bool uploadSuccess = await _syncService.startUpload(
      task: task,
      uploadUrl: apiData['uploadUrl'],
      headers: apiData['requiredHeaders'],
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      },
    );

    if (!uploadSuccess) {
      throw Exception("S3 Upload failed");
    }

    _log("✅ STEP 2 SUCCESS");

    // ============================================================
    // CALCULATE AUDIO DURATION
    // ============================================================

    final int duration =
        task.endTime.difference(task.startTime).inSeconds;

    _log("Audio duration: $duration seconds");

    // ============================================================
    // STEP 3: COMPLETE CONSULTATION
    // ============================================================

    _log("========== STEP 3: COMPLETE ==========");

    final bool processingStarted =
        await _syncService.completeConsultation(
      jobId: apiData['job_id'],
      doctorId: doctorEmail,
      s3Key: apiData['audio_s3_key'],
      durationSeconds: duration,
      patientName: _patientName,
      patientPhone: _patientPhone,
      bookingId: _bookingId,
    );

    if (!processingStarted) {
      throw Exception("Step 3 failed");
    }

    _log("✅ STEP 3 SUCCESS");
    _log("Consultation processing started");
    _log("Booking ID: $_bookingId");

    // ============================================================
    // STEP 4: DELETE BOOKING FROM BACKEND
    // ============================================================

    _log("========== STEP 4: DELETE BOOKING ==========");

    final String token = HiveStorage.getToken() ?? "";

    if (token.isEmpty) {
      throw Exception("Authentication token is empty");
    }

    _log("Calling DELETE booking API...");
    _log("Booking ID: $_bookingId");

    final bool bookingDeleted =
        await _repository.deleteBookedPatientApi(
      _bookingId,
      token,
    );

    if (!bookingDeleted) {
      throw Exception("Booking deletion failed");
    }

    _log("✅ BOOKING DELETED FROM BACKEND");

    // ============================================================
    // STEP 5: DELETE LOCAL HIVE OUTBOX ITEM
    // ============================================================

    _log("========== STEP 5: DELETE OUTBOX ==========");

    await task.delete();

    _log("✅ Outbox item deleted");

    // ============================================================
    // STEP 6: UPDATE SERVER BATCH
    // ============================================================

    await HiveStorage.incrementServerBatch();

    _log("✅ Server batch incremented");

    // ============================================================
    // STEP 7: REMOVE FROM CURRENT PROVIDER UI LIST
    // ============================================================

    if (mounted) {
      try {
        final viewModel =
            Provider.of<ConsultationViewModel>(
          context,
          listen: false,
        );

        _log(
          "Removing booking from Provider UI list: $_bookingId",
        );

        viewModel.removeBookedPatient(_bookingId);

        _log("✅ Booking removed from Provider UI list");
      } catch (e) {
        _log(
          "⚠️ Provider UI removal skipped: $e",
        );
      }
    }

    // ============================================================
    // STEP 8: NAVIGATE TO ACKNOWLEDGEMENT
    // ============================================================

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isVerifying = false;
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.acknowledgment_screen,
        (route) =>
            route.settings.name == RouteNames.dashboard,
        arguments: {
          "name_patient": _patientName,
          "duration": formatDurationReadable(
            _hours,
            _minutes,
            _seconds,
          ),
        },
      );
    }
  } catch (e, stackTrace) {
    _log("=================================");
    _log("❌ SYNC FAILED");
    _log("Error: $e");
    _log("StackTrace: $stackTrace");
    _log("=================================");

    await HiveStorage.setSyncingStatus(
      hiveKey,
      false,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isVerifying = false;
      });

      utils.toastMessage(
        "Upload failed. Check Outbox.",
      );
    }
  } finally {
    _isUploadingRightNow = false;
  }
}


  Future<void> _finalizeRecordingAndUpload() async {
    if (_isUploadingRightNow || _isLoading || _isVerifying) return;
    _isUploadingRightNow = true;

    try {
      _consultationFinished = true;
      _cancelReminderLoop = true;
      await _beepPlayer.stop();

      String? audioFullPath;
      if (_isRecording) {
        audioFullPath = await _recorder.stop();
        _waveController.stop(true);
        _timer?.cancel();
        _recordingEndTime = DateTime.now();
        setState(() { _isRecording = false; _isPaused = false; });
      }

      audioFullPath ??= await utils.getFilePath(filename);

      // Hardware flush check
      File audioFile = File(audioFullPath);
      int retries = 0;
      while (retries < 5 && (!await audioFile.exists() || await audioFile.length() < 100)) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      // 1. Always Save to Hive First
      final pending = PendingConsultation(
        patientName: _patientName,
        patientId: _patientId,
        bookingId: _bookingId,
        gender: _gender, age: _age, patientPhone: _patientPhone, dob: _dob, visitType: _visitType,
        audioPath: audioFullPath, startTime: _recordingStartTime ?? DateTime.now(), endTime: DateTime.now(),
        temp: _vitalsTemp, pulse: _vitalsPulse, resp: _vitalsResp, bp: _vitalsBP, sugar: _vitalsSugar,
        token: HiveStorage.getToken() ?? "", isSyncing: false,
      );
      int hiveKey = await HiveStorage.addToOutbox(pending);

      // 2. Network Check
      if (await _repository.checkServerHealth()) {
        setState(() { _isLoading = true; _uploadProgress = 0.0; });
        _showExitGuardDialog();
        await _startManualSync(hiveKey);
      } else {
        _showOfflineDialog();
      }
    } catch (e) {
      _log("Finalize Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
        if (_seconds >= 60) { _seconds = 0; _minutes++; }
        if (_minutes >= 60) { _minutes = 0; _hours++; }
        if (_remainingSeconds > 0) { _remainingSeconds--; }
        else { _timer?.cancel(); _handleLimitReached(); }
      });
    });
  }

  Future<void> _handleLimitReached() async {
    if (_isHandlingLimit) return;
    _isHandlingLimit = true;
    _warningPlayer.play(AssetSource('sounds/beep.mp3'));
    if (_isRecording && !_isPaused) {
      _recorder.pause();
      _waveController.pause();
      setState(() { _isPaused = true; _waitingForLimitExtension = true; });
    }
    _showLimitReachedDialog();
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Column(children: [Icon(Icons.timer_off_outlined, size: 55, color: Colorprimary), SizedBox(height: 15), Text("Limit Reached", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colorprimary))]),
          content: Text(_maxDurationMinutes < 15 ? "You've reached the $_maxDurationMinutes min limit. Add more time or save now." : "Maximum limit reached. Please save now.", textAlign: TextAlign.center),
          actions: [
            Row(children: [
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: () { _warningPlayer.stop(); Navigator.pop(context); _finalizeRecordingAndUpload(); }, child: const Text("Save Now"))),
              if (_maxDurationMinutes < 15) const SizedBox(width: 10),
              if (_maxDurationMinutes < 15) Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: _handleExceedLimit, child: const Text("Exceed 5 Min"))),
            ])
          ],
        ),
      ),
    );
  }

  Future<void> _handleExceedLimit() async {
    _warningPlayer.stop();
    _isHandlingLimit = false;
    setState(() { _maxDurationMinutes += 5; _remainingSeconds = 300; _isPaused = false; _waitingForLimitExtension = false; });
    await _recorder.resume();
    _waveController.record();
    _startTimer();
    Navigator.pop(context);
  }

  Future<void> _pauseRecording() async {
    if (!_isRecording || _isLoading) return;
    if (!_isPaused) {
      await _recorder.pause(); _waveController.pause();
      setState(() { _isPaused = true; _timer?.cancel(); });
    } else {
      await _recorder.resume(); _waveController.record();
      setState(() { _isPaused = false; _startTimer(); });
    }
  }

  @override
  void dispose() {
    _consultationFinished = true;
    _timer?.cancel();
    _recorder.dispose();
    _waveController.dispose();
    _beepPlayer.dispose();
    _warningPlayer.dispose();
    _pulseController.dispose();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    _remainingSeconds = _maxDurationMinutes * 60;
    _isRecording = true;
    _cancelReminderLoop = true;
    setState(() { _showMicReminder = false; _isRecorderControl = true; });
    _recordingStartTime = DateTime.now();
    final String path = await utils.getFilePath(filename);
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000), path: path);
    _waveController.record();
    _startTimer();
  }

  // --- UI Build Section (Design Unchanged) ---
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isRecording && !_isLoading,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_isLoading) _showExitGuardDialog();
          else if (_isRecording || _isRecorderControl) _showRecordingExitWarning();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark),
          iconTheme: const IconThemeData(color: Colorprimary),
          backgroundColor: Colors.white, centerTitle: true, elevation: 0,
          title: const Text("NourDoc", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(_patientName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colorprimary), overflow: TextOverflow.ellipsis)),
                      const Text("'s Consultation", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colorprimary)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(_gender.toLowerCase() == 'male' ? Icons.male : Icons.female, size: 16, color: Colorprimary),
                      const SizedBox(width: 4),
                      Text("• Age: $_age", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  ],
                ),
              ),
              _buildVitalsRow(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!_isRecorderControl) const SizedBox(height: 60),
                      GestureDetector(
                        onTap: _handleMicAction,
                        child: Column(
                          children: [
                            if (_showMicReminder && !_isRecorderControl)
                              const Text("When ready, tap to start recording.", style: TextStyle(color: Colorprimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_showMicReminder && !_isRecording && !_isRecorderControl)
                                  ScaleTransition(scale: _pulseAnimation, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colorprimary, width: 8)))),
                                if (_isRecorderControl)
                                  SizedBox(width: 215, height: 215, child: CustomPaint(painter: TimerProgressPainter(remainingSeconds: _remainingSeconds, totalSeconds: _maxDurationMinutes * 60, color: Colors.black))),
                                Container(
                                  width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: _isRecording ? Colorprimary : Colors.white, border: !_isRecording ? Border.all(color: Colorprimary, width: 8) : null),
                                  child: Center(child: Image.asset("assets/icons/icon_mic.png", height: 244, width: 244, color: _isRecording ? Colors.white : Colorprimary)),
                                ),
                              ],
                            ),
                            if (!_isRecorderControl)
                              const Padding(padding: EdgeInsets.only(top: 24), child: Column(children: [Text("Tap to record now", style: TextStyle(color: Colorprimary, fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text("NourDoc will securely capture the conversation.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13))])),
                          ],
                        ),
                      ),
                      if (_isRecorderControl)
                        Column(children: [
                          Text('${formatTime(_hours)}:${formatTime(_minutes)}:${formatTime(_seconds)}', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colorprimary)),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            IconButton(icon: Icon(Icons.remove_circle_outline, color: (_maxDurationMinutes > 5 && _minutes < (_maxDurationMinutes - 5)) ? Colorprimary : Colors.grey),
                                onPressed: (_maxDurationMinutes > 5 && _minutes < (_maxDurationMinutes - 5)) ? () => setState(() { _maxDurationMinutes -= 5; _remainingSeconds -= 300; }) : null),
                            Text("Limit: $_maxDurationMinutes min", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: Icon(Icons.add_circle_outline, color: _maxDurationMinutes < 15 ? Colorprimary : Colors.grey),
                                onPressed: _maxDurationMinutes < 15 ? () => setState(() { _maxDurationMinutes += 5; _remainingSeconds += 300; _waitingForLimitExtension = false; }) : null),
                          ]),
                        ]),
                      AudioWaveforms(size: Size(MediaQuery.of(context).size.width / 2, 120.0), recorderController: _waveController, waveStyle: const WaveStyle(waveColor: Colors.black, extendWaveform: true, showMiddleLine: false)),
                      Visibility(
                        visible: _isRecorderControl,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                            Container(margin: const EdgeInsets.symmetric(horizontal: 15), height: 95, decoration: BoxDecoration(color: Colorprimary, borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Padding(padding: const EdgeInsets.only(left: 20), child: GestureDetector(onTap: () => _showRecordingExitWarning(), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(backgroundColor: Colors.white, child: Text('X', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))), Text("Discard", style: TextStyle(color: Colors.white, fontSize: 11))]))),
                                Padding(padding: const EdgeInsets.only(right: 20), child: GestureDetector(onTap: _finalizeRecordingAndUpload, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  CircleAvatar(backgroundColor: Colors.white, child: _isVerifying || _isLoading ? const CupertinoActivityIndicator() : const Icon(Icons.check, color: Colors.black)),
                                  Text(_isVerifying ? "Wait..." : "Save", style: const TextStyle(color: Colors.white, fontSize: 11))
                                ]))),
                              ]),
                            ),
                            Positioned(
                              top: -15,
                              child: Column(
                                children: [
                                  Container(
                                    height: 75,
                                    width: 75,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black, // Outer border/padding area
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white, // Circle color is white
                                        foregroundColor: Colors.black, // Icon color is black
                                        shape: const CircleBorder(),
                                        elevation: 5,
                                        padding: EdgeInsets.zero,
                                      ),
                                      // Logic: Disable if loading or waiting for limit extension
                                      onPressed: (_isRecording && !_isLoading && !_waitingForLimitExtension)
                                          ? _pauseRecording
                                          : null,
                                      child: Icon(
                                        _isPaused ? Icons.play_arrow : Icons.pause,
                                        size: 35,
                                        color: Colors.black, // Ensures icon is black
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isPaused ? "Resume" : "Pause",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold, // Text is now Bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper UI Widgets (Unchanged) ---
  Widget _buildVitalsRow() {
    if (_vitalsTemp.isEmpty && _vitalsSugar.isEmpty && _vitalsPulse.isEmpty && _vitalsResp.isEmpty && _vitalsBP.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      if (_vitalsTemp.isNotEmpty) _vitalsChip("Temp", "$_vitalsTemp°F", Icons.thermostat, Colors.black),
      if (_vitalsBP.isNotEmpty) _vitalsChip("BP", "$_vitalsBP mmHg", Icons.speed, Colors.black),
      if (_vitalsPulse.isNotEmpty) _vitalsChip("Pulse", "$_vitalsPulse bpm", Icons.favorite, Colors.black),
      if (_vitalsResp.isNotEmpty) _vitalsChip("Resp", "$_vitalsResp bpm", Icons.air, Colors.black),
      if (_vitalsSugar.isNotEmpty) _vitalsChip("Sugar", "$_vitalsSugar mg/dL", Icons.water_drop, Colors.black),
    ])));
  }

  Widget _vitalsChip(String label, String value, IconData icon, Color color) {
    return Container(margin: const EdgeInsets.only(right: 2), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 2), Text(value, style: const TextStyle(fontSize: 11, color: Colors.black))]));
  }

  void _showExitGuardDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      title: const Column(children: [Icon(Icons.cloud_upload_outlined, size: 55, color: Colorprimary), Text("Uploading", style: TextStyle(color: Colorprimary))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        LinearProgressIndicator(value: _uploadProgress, color: Colorprimary),
        const SizedBox(height: 10), Text("${(_uploadProgress * 100).toInt()}% Uploaded")
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Wait"))],
    ));
  }

  void _showOfflineDialog() => showAppDialog(context: context, icon: Icons.wifi_off, title: "Saved Locally", content: "Consultation saved in Outbox. Send later.", primaryText: "Okay", onPrimary: () => Navigator.pop(context));
  void _showRecordingExitWarning() => showAppDialog(context: context, icon: Icons.delete, title: "Discard?", content: "Leave and delete audio?", secondaryText: "No", primaryText: "Discard", onPrimary: () => Navigator.popAndPushNamed(context, RouteNames.dashboard));
  String formatTime(int value) => value.toString().padLeft(2, '0');
  Future<void> _handleMicAction() async { if (await Permission.microphone.request().isGranted) _startRecording(); }
}

class TimerProgressPainter extends CustomPainter {
  final int remainingSeconds, totalSeconds; final Color color;
  TimerProgressPainter({required this.remainingSeconds, required this.totalSeconds, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint bg = Paint()..color = color.withOpacity(0.15)..strokeWidth = 14..style = PaintingStyle.stroke;
    Paint pg = Paint()..color = color..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    double radius = (size.width / 2) - 7;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, bg);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius), -math.pi / 2, 2 * math.pi * (remainingSeconds / totalSeconds), false, pg);
  }
  @override
  bool shouldRepaint(TimerProgressPainter old) => old.remainingSeconds != remainingSeconds;
}
