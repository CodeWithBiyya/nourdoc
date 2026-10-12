import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:medicalai/data/response/status.dart';
import 'package:medicalai/ui/findings/clinical_findings_viewmodel.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../model/encounter_information_model.dart';
import '../../routes/routs_name.dart';
import '../../services/app_url.dart';
import '../../utils/generate_pdf.dart';

class ClinicalFindingsScreen extends StatefulWidget {
  const ClinicalFindingsScreen({super.key});

  @override
  State<ClinicalFindingsScreen> createState() => _ClinicalFindingsScreenState();
}

class _ClinicalFindingsScreenState extends State<ClinicalFindingsScreen> {
  int _selectedTabIndex = 0;
  double _sliderValue = 0.0;
  String _id = "";
  String _status = "FINISHED";

  // Risk Data Variables
  Map<String, dynamic>? _riskData;
  bool _isLoadingRisk = false;

  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _vitalsScrollController = ScrollController();
  bool _showVitalsArrow = false;

  ClinicalFindingsViewModel clinicalFindingsViewModel = ClinicalFindingsViewModel();
  AudioPlayer? _audioPlayer;
  String? soapValue;
  String? tarnscriptValue;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  late TextEditingController soapController;
  late TextEditingController transcriptController;
  bool _isEditable = true;
  bool _isAudioInitialized = false;
  bool _isDragging = false;
  bool _isLoadingAudio = false; // Add this line

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _editorFocusNode.dispose();
    _vitalsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route == null || route.settings.arguments == null) {
        utils.toastMessage("No consultation selected");
        Navigator.pop(context);
        return;
      }
      final args = route.settings.arguments as Map<String, dynamic>?;
      _id = args?["id"] ?? "";
      _status = args?["status"] ?? "FINISHED";

      clinicalFindingsViewModel.getEncounterDetals(_id);
      _fetchRiskFactors();

      _audioPlayer = AudioPlayer();

      // Listeners for audio
      _audioPlayer!.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _audioPlayer!.positionStream.listen((p) {
        if (mounted && !_isDragging) {
          setState(() {
            _position = p;
            if (_duration.inMilliseconds > 0) {
              _sliderValue = _position.inMilliseconds / _duration.inMilliseconds;
            }
          });
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            // Agar player loading ya buffering state mein hai toh loading true hogi
            _isLoadingAudio = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });
        }
      });

      // API fetch logic for audio link and metadata
      _preloadAudioMetadata();

      _vitalsScrollController.addListener(() {
        if (_vitalsScrollController.hasClients) {
          double maxScroll = _vitalsScrollController.position.maxScrollExtent;
          double currentScroll = _vitalsScrollController.position.pixels;
          setState(() => _showVitalsArrow = currentScroll < (maxScroll - 5));
        }
      });
    });
  }

  Future<void> _fetchRiskFactors() async {
  if (_id.isEmpty) {
    debugPrint("❌ Risk API: consultation ID is empty");
    return;
  }

  if (mounted) {
    setState(() {
      _isLoadingRisk = true;
    });
  }

  try {
    final url =
        "${AppUrls.riskEvaluation}?action=get&consultation_id=$_id";

    debugPrint("========================================");
    debugPrint("RISK API CALL");
    debugPrint("Risk API URL: $url");
    debugPrint("Consultation ID: $_id");

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
      },
    );

    debugPrint("Risk API Status Code: ${response.statusCode}");
    debugPrint("Risk API Response Body:");
    debugPrint(response.body);
    debugPrint("========================================");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      debugPrint("Decoded API data: $decoded");

      if (decoded is Map<String, dynamic> &&
          decoded['ok'] == true &&
          decoded['result'] != null) {

        final result = decoded['result'];

        debugPrint("Risk result: $result");

        if (mounted) {
          setState(() {
            _riskData = Map<String, dynamic>.from(result);
          });
        }

        debugPrint("✅ Risk data successfully stored");
        debugPrint("Risk Score: ${_riskData?['risk_score']}");
        debugPrint("Risk Level: ${_riskData?['risk_level']}");
        debugPrint("Quality: ${_riskData?['quality_category']}");
        debugPrint("Review: ${_riskData?['review_level']}");
        debugPrint("Final Score: ${_riskData?['final_score']}");
        debugPrint("Final Score 10: ${_riskData?['final_score_10']}");
      } else {
        debugPrint("❌ Risk API returned ok=false or result is null");
        debugPrint("ok: ${decoded['ok']}");
        debugPrint("result: ${decoded['result']}");
      }
    } else {
      debugPrint("❌ Risk API HTTP Error: ${response.statusCode}");
      debugPrint("Response: ${response.body}");
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Risk API Exception: $e");
    debugPrint("StackTrace: $stackTrace");
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingRisk = false;
      });
    }
  }
}

  Future<void> _preloadAudioMetadata() async {
    try {
      final response = await http.get(
          // Uri.parse('https://bhpkk2chuj.execute-api.us-east-1.amazonaws.com/audio/$_id') //AWS
          Uri.parse('https://8wfvyjajy1.execute-api.us-east-1.amazonaws.com/audio/$_id')   // DEV
        // Uri.parse('https://4ugllkifsb.execute-api.us-east-1.amazonaws.com/audio/$_id') //PRODUCTION
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String audioUrl = data['audio_url'];
        await _audioPlayer?.setUrl(audioUrl);
        _isAudioInitialized = true;
      }
    } catch (e) {
      debugPrint("Metadata Fetch Error: $e");
    }
  }

  Future<void> _handleAudioPlayback() async {
    try {
      if (!_isAudioInitialized) {
        await _preloadAudioMetadata();
      }
      if (_isPlaying) {
        await _audioPlayer?.pause();
      } else {
        await _audioPlayer?.play();
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
      utils.toastMessage("Error playing audio");
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(Icons.arrow_back, color: Colorprimary, size: 24),
          ),
        ),
        centerTitle: true,
        title: const Text("NourDoc", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [_buildPopupActions()],
      ),
      bottomNavigationBar: _buildBottomButtons(),
      body: ChangeNotifierProvider<ClinicalFindingsViewModel>.value(
        value: clinicalFindingsViewModel,
        child: Consumer<ClinicalFindingsViewModel>(
          builder: (context, value, child) {
            if (value.encounterInfo.status == Status.LOADING) return const Center(child: CircularProgressIndicator());
            if (value.encounterInfo.status == Status.ERROR) return _handleErrorLogic(value);

            if (value.encounterInfo.status == Status.COMPLETE) {
              final data = value.encounterInfo.data!.data;
              _initializeControllers(data);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(data), // TOP CARD (Updated Duration logic inside)
                    const SizedBox(height: 10),
                    if (_status == "FAILED")
                      _buildDelayedProcessingView()
                    else ...[
                      _buildVitalsWithIndicator(data.vitals),
                      const SizedBox(height: 5),
                      _buildToggleButtons(),
                      const SizedBox(height: 12),
                      _buildUnifiedContentBox(data),
                    ],
                    const SizedBox(height: 10),
                    const Text("Doctor-Patient Dialog Audio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                    _buildAudioPlayer(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: _isEditable ? FloatingActionButton(
        backgroundColor: Colorprimary,
        onPressed: () => Navigator.pushNamed(context, RouteNames.consultationSelection),
        child: const Icon(Icons.add, size: 24, color: Colors.white),
      ) : null,
    );
  }

  // --- TOP INFO CARD (Duration Updated Here) ---
  Widget _buildInfoCard(EncounterData data) {
    String displayDuration = "N/A";

    // Duration Logic
    if (data.duration.isNotEmpty && data.duration.toLowerCase() != "n/a") {
      displayDuration = formatConsultationTime(data.duration);
    } else if (_duration != Duration.zero) {
      int mins = _duration.inMinutes;
      int secs = _duration.inSeconds % 60;
      displayDuration = mins == 0 ? "00:${secs.toString().padLeft(2, '0')} sec" : "${mins.toString().padLeft(2, '0')} min ${secs.toString().padLeft(2, '0')} sec";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(children: [
        // AB DIRECT VARIABLES USE KAREIN, kyunki logic Model mein handle ho gayi hai
        _infoRow("Patient Name", data.patientName, "Age / Gender", "${data.patientAge} / ${data.patientGender}"),
        const Divider(height: 20, color: Colors.black12),
        _infoRow("Consulted At", data.date.isEmpty ? "N/A" : data.date, "Duration", displayDuration),
      ]),
    );
  }

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label1, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)), Text(value1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(label2, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)), Text(value2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])),
    ]);
  }

  // --- AUDIO PLAYER UI ---
  Widget _buildAudioPlayer() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(children: [
        // YAHAN BADLAV HAI: Loading check
        _isLoadingAudio
            ? const Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colorprimary,
            ),
          ),
        )
            : IconButton(
          icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colorprimary,
              size: 32),
          onPressed: () => _handleAudioPlayback(),
        ),
        Expanded(
            child: Slider(
              value: _sliderValue.clamp(0.0, 1.0),
              min: 0,
              max: 1.0,
              activeColor: Colorprimary,
              onChanged: (v) {
                setState(() {
                  _isDragging = true;
                  _sliderValue = v;
                });
              },
              onChangeEnd: (v) {
                final target =
                Duration(milliseconds: (_duration.inMilliseconds * v).toInt());
                _audioPlayer?.seek(target);
                _isDragging = false;
              },
            )),
        Text("${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // --- HELPERS ---
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  String formatConsultationTime(String durationString) {
    if (durationString.isEmpty || durationString.toLowerCase() == "n/a") return "N/A";

    // Naya Logic: Agar string mein pehle se 'min' ya 'sec' likha hai (jo recorder bhej raha hai)
    // toh usay waisa hi rehne dein.
    if (durationString.contains("min") || durationString.contains("sec")) {
      return durationString;
    }

    try {
      if (!durationString.contains("to")) return durationString;
      final parts = durationString.split("to");
      if (parts.length < 2) return durationString;

      String startStr = parts[0].trim();
      String endStr = parts[1].toLowerCase().replaceAll('hrs', '').trim();

      DateTime dt1 = DateTime.parse(startStr);
      DateTime dt2 = DateTime.parse(endStr);
      Duration diff = dt2.difference(dt1);

      String p(int n) => n.toString().padLeft(2, '0');
      String diffStr = diff.inMinutes > 0 ? "${diff.inMinutes} min" : "${diff.inSeconds} sec";

      return "${p(dt1.hour)}:${p(dt1.minute)} - ${p(dt2.hour)}:${p(dt2.minute)} ($diffStr)";
    } catch (e) {
      return durationString;
    }
  }

  // --- OTHER UI COMPONENTS (VITALS, TABS, ETC) ---
  Widget _buildVitalsWithIndicator(Map<String, dynamic>? vitals) {
    // Agar vitals null hain ya empty hain toh kuch na dikhao
    if (vitals == null || vitals.isEmpty) return const SizedBox.shrink();

    bool hasData = vitals.values.any((v) => v != null && v.toString().isNotEmpty && v.toString().toUpperCase() != "N/A");
    if (!hasData) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 35,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: vitals.entries.map((entry) {
          String key = entry.key.toLowerCase().trim();
          String val = entry.value?.toString() ?? "";
          if (val.isEmpty || val.toUpperCase() == "N/A") return const SizedBox.shrink();

          IconData icon;
          String unit = "";
          if (key.contains('temp')) { icon = Icons.thermostat; unit = "°F"; }
          else if (key.contains('bp')) { icon = Icons.speed; unit = " mmHg"; }
          else if (key.contains('pulse')) { icon = Icons.favorite; unit = " bpm"; }
          else if (key.contains('sugar')) { icon = Icons.water_drop; unit = " mg/dL"; }
          else if (key.contains('resp')) { icon = Icons.air; unit = " bpm"; }
          else { icon = Icons.monitor_weight_outlined; }

          return _vitalsChip("$val$unit", icon, Colors.black);
        }).toList(),
      ),
    );
  }

  Widget _vitalsChip(String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        // PEHLE: BorderRadius.circular(50) tha
        // AB: 4 ya 0 kar dain rectangle look k liye
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedContentBox(EncounterData data) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: !_isEditable && (_selectedTabIndex == 1 || _selectedTabIndex == 2) ? Colorprimary : Colors.grey.shade300, width: !_isEditable ? 1.5 : 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildContentHeader(),
        const SizedBox(height: 12),
        if (_selectedTabIndex == 0) _buildHighlightsContent(data.highlights)
        else if (_selectedTabIndex == 1) _buildFormattedTextField(soapController, true)
        else if (_selectedTabIndex == 2) _buildFormattedTextField(transcriptController, false)
          else if (_selectedTabIndex == 3) _buildICDCodesContent(data.icd)
            else if (_selectedTabIndex == 4) _buildRiskFactorsContent(),  // New Static Content
      ]),
    );
  }


//   Widget _buildRiskFactorsContent() {
//   // API loading
//   if (_isLoadingRisk) {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(20.0),
//         child: CircularProgressIndicator(
//           strokeWidth: 2,
//           color: Colorprimary,
//         ),
//       ),
//     );
//   }

//   // No API data
//   if (_riskData == null) {
//     return const Text(
//       "Risk data not available at the moment.",
//       style: TextStyle(
//         fontSize: 14,
//         color: Colors.grey,
//       ),
//     );
//   }

//   // Get values directly from API
//   final riskScore =
//       _riskData!['risk_score']?.toString() ?? "N/A";

//   final riskLevel =
//       _riskData!['risk_level']?.toString() ?? "N/A";

//   final qualityCategory =
//       _riskData!['quality_category']?.toString() ?? "N/A";

//   final reviewLevel =
//       _riskData!['review_level']?.toString() ?? "N/A";

//   final interpretation =
//       _riskData!['interpretation']?.toString() ?? "N/A";

//   final finalScore =
//       _riskData!['final_score']?.toString() ?? "N/A";

//   final finalScore10 =
//       _riskData!['final_score_10']?.toString() ?? "N/A";

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [

//       // Description
//       const Padding(
//         padding: EdgeInsets.only(bottom: 15.0),
//         child: Text(
//           "This assessment evaluates the reliability and quality of the AI-powered medical report derived from the recorded consultation.",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//             height: 1.4,
//           ),
//         ),
//       ),

//       // Risk Score
//       _riskItem(
//         "Risk Score",
//         riskScore,
//       ),

//       // Risk Level
//       _riskItem(
//         "Risk Level",
//         riskLevel,
//       ),

//       // Quality Category
//       _riskItem(
//         "Quality Category",
//         qualityCategory,
//       ),

//       // Review Level
//       _riskItem(
//         "Review Level",
//         reviewLevel,
//       ),

//       // Final Score
//       _riskItem(
//         "Final Score",
//         finalScore,
//       ),

//       // Final Score / 10
//       _riskItem(
//         "Final Score (10)",
//         finalScore10,
//       ),

//       // Interpretation
//       _riskItem(
//         "Interpretation",
//         interpretation,
//       ),
//     ],
//   );
// }

Widget _buildRiskFactorsContent() {
  // API loading
  if (_isLoadingRisk) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colorprimary,
        ),
      ),
    );
  }

  // No API data
  if (_riskData == null) {
    return const Text(
      "Risk data not available at the moment.",
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }

  // Only get the 3 values we want to show
  final riskScore =
      _riskData!['risk_score']?.toString() ?? "N/A";

  final qualityCategory =
      _riskData!['quality_category']?.toString() ?? "N/A";

  final interpretation =
      _riskData!['interpretation']?.toString() ?? "N/A";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // Description
      const Padding(
        padding: EdgeInsets.only(bottom: 15.0),
        child: Text(
          "This assessment evaluates the reliability and quality of the AI-powered medical report derived from the recorded consultation.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ),

      // Score
      _riskItem(
        "Score",
        "$riskScore (Range: 0-100)",
      ),

      // Quality Category
      _riskItem(
        "Quality Category",
        qualityCategory,
      ),

      // Interpretation
      _riskItem(
        "Interpretation",
        interpretation,
      ),
    ],
  );
}

Widget _riskItem(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(
            color: Colorprimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}



  Widget _buildHighlightsContent(Map<String, dynamic> highlights) {
    // 1. Filter out empty or "N/A" values first
    final allItems = highlights.entries
        .where((e) => e.value.toString().toUpperCase() != "N/A" && e.value.toString().isNotEmpty)
        .toList();

    if (allItems.isEmpty) return const Text("No specific highlights identified.");

    // 2. Separate the "Complaint" entry from the rest
    MapEntry<String, dynamic>? complaintEntry;
    List<MapEntry<String, dynamic>> otherEntries = [];

    for (var entry in allItems) {
      String key = entry.key.toLowerCase().trim();
      // This checks for "Complaint" or "Chief Complaint" or "Presenting Complaint"
      if (key == "complaint" || key == "chief complaint" || key == "presenting complaint") {
        complaintEntry = entry;
      } else {
        otherEntries.add(entry);
      }
    }

    // 3. Create a new sorted list: Put complaint at index 0, then add others
    List<MapEntry<String, dynamic>> sortedItems = [];
    if (complaintEntry != null) {
      sortedItems.add(complaintEntry);
    }
    sortedItems.addAll(otherEntries);

    // 4. Build the UI using the sorted list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sortedItems.length, (index) {
        final entry = sortedItems[index];
        String headingName = entry.key;
        // Check if the current key is "complaint" (case insensitive)
        if (headingName.toLowerCase().trim() == "complaint") {
          headingName = "Chief Complaint";
        }
        return _numberedPoint(index + 1, headingName, entry.value.toString());
      }),
    );
  }
  // Widget _buildHighlightsContent(Map<String, dynamic> highlights) {
  //   final items = highlights.entries
  //       .where((e) => e.value.toString().toUpperCase() != "N/A" && e.value.toString().isNotEmpty)
  //       .toList();
  //
  //   if (items.isEmpty) return const Text("No specific highlights identified.");
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: List.generate(items.length, (index) {
  //       final entry = items[index];
  //       // Yahan hum index + 1 bhej rahe hain numbering ke liye
  //       return _numberedPoint(index + 1, entry.key, entry.value.toString());
  //     }),
  //   );
  // }

// Naya helper method numbering ke liye
  Widget _numberedPoint(int number, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point ki jagah Number
          Text("$number. ", style: const TextStyle(color: Colorprimary, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: "$key: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value, style: const TextStyle(fontSize: 14, height: 1.4))
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String key, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("• ", style: TextStyle(color: Colorprimary, fontWeight: FontWeight.bold)),
      Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: "$key: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: value, style: const TextStyle(fontSize: 14, height: 1.4))]))),
    ]));
  }

  void _initializeControllers(EncounterData data) {
    if (soapValue == null) {
      // Null safety add kar di
      soapValue = (data.soap ?? "").trim();
      tarnscriptValue = (data.transcription ?? "").trim();

      soapController = TextEditingController(text: soapValue);
      transcriptController = TextEditingController(text: tarnscriptValue);
    }
  }

  Widget _buildContentHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
          _selectedTabIndex == 0 ? "KEY HIGHLIGHTS" :
          _selectedTabIndex == 1 ? "SOAP NOTES" :
          _selectedTabIndex == 2 ? "DOCTOR-PATIENT CONVERSATION" :
          _selectedTabIndex == 3 ? "MED CODES" :
          "REPORT RISK ASSESSMENT", // New Header Title
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)
      ),
      if (!_isEditable && (_selectedTabIndex == 1 || _selectedTabIndex == 2))
        const Text("(EDITING MODE)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colorprimary)),
    ]);
  }

  Widget _buildToggleButtons() {
    return Container(
      constraints: const BoxConstraints(minHeight: 45),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
          ]
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _toggleTab(Icons.tips_and_updates_outlined, "Summary", 0)),
            Expanded(child: _toggleTab(Icons.fact_check_outlined, "Notes", 1)),
            Expanded(child: _toggleTab(Icons.record_voice_over_outlined, "Transcript", 2)),
            Expanded(child: _toggleTab(Icons.segment_outlined, "Med Codes", 3)),
            Expanded(child: _toggleTab(Icons.gpp_maybe_outlined, "Risks", 4)), // Added New Tab
          ],
        ),
      ),
    );
  }

  Widget _toggleTab(IconData icon, String label, int index) {
    bool sel = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Added padding
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: sel ? Colorprimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8)
        ),
        // FittedBox ensures that if the text is too long, it scales down
        // instead of causing an "Overflow Error" or "Pixel Bleeding"
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  icon,
                  size: 16,
                  color: sel ? Colors.white : Colors.black
              ),
              const SizedBox(width: 4),
              Text(
                  label,
                  style: TextStyle(
                      fontSize: 13,
                      color: sel ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Widget _toggleTab(IconData icon, String label, int index) {
  //   bool sel = _selectedTabIndex == index;
  //   return GestureDetector(
  //     onTap: () => setState(() => _selectedTabIndex = index),
  //     child: Container(
  //       margin: const EdgeInsets.all(2), alignment: Alignment.center,
  //       decoration: BoxDecoration(color: sel ? Colorprimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
  //       child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: sel ? Colors.white : Colors.black), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 13, color: sel ? Colors.white : Colors.black, fontWeight: FontWeight.bold))]),
  //     ),
  //   );
  // }

  Widget _buildFormattedTextField(TextEditingController controller, bool isSoap) {
    if (_isEditable) return SelectableText.rich(isSoap ? _getFormattedSoap(controller.text) : _getFormattedTranscript(controller.text), style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87));
    return TextField(controller: controller, focusNode: _editorFocusNode, maxLines: null, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero));
  }

  TextSpan _getFormattedSoap(String text) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r'(SUBJECTIVE:|OBJECTIVE:|ASSESSMENT:|PLAN:)', caseSensitive: false);
    final matches = regExp.allMatches(text).toList();
    if (matches.isEmpty) return TextSpan(text: text);
    int lastMatchEnd = 0;
    for (var match in matches) {
      if (match.start > lastMatchEnd) spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      spans.add(TextSpan(text: text.substring(match.start, match.end), style: const TextStyle(fontWeight: FontWeight.bold)));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    return TextSpan(children: spans);
  }

  TextSpan _getFormattedTranscript(String text) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r'(Doctor:|Patient:)', caseSensitive: false);
    final matches = regExp.allMatches(text).toList();
    if (matches.isEmpty) return TextSpan(text: text);
    int lastMatchEnd = 0;
    for (var match in matches) {
      if (match.start > lastMatchEnd) spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      spans.add(TextSpan(text: text.substring(match.start, match.end), style: const TextStyle(fontWeight: FontWeight.bold)));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    return TextSpan(children: spans);
  }

  Widget _buildICDCodesContent(String icdString) {
    if (icdString.isEmpty || icdString.toUpperCase() == "N/A") return const Text("No codes suggested.");
    List<String> codes = icdString.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: codes.map((code) => _bulletPointRaw(code.trim())).toList());
  }

  Widget _bulletPointRaw(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("• ", style: TextStyle(color: Colorprimary, fontWeight: FontWeight.bold)), Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)))]));
  }

  Widget _handleErrorLogic(ClinicalFindingsViewModel value) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset("assets/icons/server.png", height: 180), const Text("Service Unavailable", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () => clinicalFindingsViewModel.getEncounterDetals(_id), child: const Text("Try Again"))]));
  }

  Widget _buildPopupActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colorprimary),
      onSelected: (value) async {
        if (value == 'Edit') { setState(() => _isEditable = false); _editorFocusNode.requestFocus(); }
        else if (value == 'Copy') { Clipboard.setData(ClipboardData(text: soapController.text)); utils.toastMessage("Copied"); }
      },
      itemBuilder: (context) => [const PopupMenuItem(value: 'Edit', child: ListTile(leading: Icon(Icons.edit), title: Text("Edit"))), const PopupMenuItem(value: 'Copy', child: ListTile(leading: Icon(Icons.copy), title: Text("Copy")))],
    );
  }

  Widget? _buildBottomButtons() {
    if (_isEditable) return null;
    return Padding(padding: const EdgeInsets.all(20), child: Row(children: [Expanded(child: ElevatedButton(onPressed: () => setState(() => _isEditable = true), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: const Text("Discard"))), const SizedBox(width: 16), Expanded(child: ElevatedButton(onPressed: () => _saveChanges(), style: ElevatedButton.styleFrom(backgroundColor: Colorprimary), child: const Text("Save")))]));
  }

  Future<void> _saveChanges() async {
    Map<String, String> datamap = {"transcription": transcriptController.text, "soap": soapController.text};
    dynamic response = await clinicalFindingsViewModel.updateEncounter(datamap, _id);
    if (response != null) { setState(() => _isEditable = true); utils.toastMessage("Saved Successfully"); }
  }

  Widget _buildDelayedProcessingView() {
    return Column(children: [Image.asset("assets/icons/processingDelay.png", height: 180), const Text("Processing Delayed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Text("We'll notify you once it's ready.", textAlign: TextAlign.center)]);
  }
}