import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicalai/data/response/status.dart';
import 'package:medicalai/ui/my_consultations/my_encounters_viewmodel.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/utils.dart';
import '../../model/EncounterListModel.dart';
import '../../routes/routs_name.dart';
import '../../utils/noInternet.dart';

class FeedbackCollectionScreen extends StatefulWidget {
  const FeedbackCollectionScreen({super.key});

  @override
  State<FeedbackCollectionScreen> createState() =>
      _FeedbackCollectionScreenState();
}

class _FeedbackCollectionScreenState extends State<FeedbackCollectionScreen> {
  int _accuracyRating = 0;
  int _completenessRating = 0;
  int _usefulnessRating = 0;
  Timer? _refreshTimer;
  final TextEditingController _improvementController = TextEditingController();

  bool _isSubmitting =
      false; // 🚩 Add this to show a loader on the Submit button

  final MyEncounterViewModel myEncounterViewModel = MyEncounterViewModel();

  @override
  void initState() {
    super.initState();
    // Fetch latest reports from server to show status
    myEncounterViewModel.getEncounters();

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final encounters = myEncounterViewModel.apiEncounterList.data?.data ?? [];

      // Check if any encounter is still processing
      final stillProcessing = encounters.any(
        (e) => e.status.toLowerCase() == 'processing',
      );

      if (stillProcessing) {
        myEncounterViewModel.getEncounters();
      } else {
        timer.cancel(); // Stop refreshing when all finished
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _improvementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Batch Feedback",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ChangeNotifierProvider<MyEncounterViewModel>.value(
        value: myEncounterViewModel,
        child: Consumer<MyEncounterViewModel>(
          builder: (context, value, child) {
            switch (value.apiEncounterList.status) {
              case Status.LOADING:
                return const Center(
                  child: CircularProgressIndicator(color: Colorprimary),
                );

              case Status.ERROR:
                return _handleErrorLogic(value);

              case Status.COMPLETE:
                // Extract the top 5 encounters (the batch that triggered this screen)
                final lastBatch =
                    value.apiEncounterList.data?.data?.take(5).toList() ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current batch processing status:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 🚩 Patient List with Status Badges
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: lastBatch
                              .map(
                                (encounter) =>
                                    _buildEncounterStatusRow(encounter),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      _buildRatingSection(
                        "How accurate was this report?",
                        _accuracyRating,
                        (v) => setState(() => _accuracyRating = v),
                      ),
                      _buildRatingSection(
                        "How clinically complete was this report?",
                        _completenessRating,
                        (v) => setState(() => _completenessRating = v),
                      ),
                      _buildRatingSection(
                        "How useful is this report for your workflow?",
                        _usefulnessRating,
                        (v) => setState(() => _usefulnessRating = v),
                      ),

                      const Text(
                        "What is the ONE thing you would like improved?",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _improvementController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Type your feedback here...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colorprimary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                );
              default:
                return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  Widget _buildEncounterStatusRow(EncounterData encounter) {
    String status = encounter.status.toLowerCase();
    Color statusColor;
    IconData statusIcon;
    String displayStatus;

    if (status == 'finished') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      displayStatus = "Finished";
    } else if (status == 'processing') {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
      displayStatus = "Processing";
    } else {
      statusColor = Colors.blueGrey;
      statusIcon = Icons.access_time;
      displayStatus = "Queued";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              encounter.patientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2E5E6E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'processing')
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                else
                  Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  displayStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildActionButtons() {
  //   return Row(
  //     children: [
  //       Expanded(child: OutlinedButton(
  //         onPressed: () => Navigator.pop(context),
  //         style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)),
  //         child: const Text("Back"),
  //       )),
  //       const SizedBox(width: 15),
  //       Expanded(child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)),
  //         onPressed: _submitForm,
  //         child: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //       )),
  //     ],
  //   );
  // }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("Back"),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colorprimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    // 1. Validation
    if (_accuracyRating == 0 ||
        _completenessRating == 0 ||
        _usefulnessRating == 0) {
      utils.toastMessage("Please provide all ratings");
      return;
    }

    // 2. Connectivity Check
    if (!await hasInternet()) {
      utils.toastMessage("Connection lost. Online access required.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 3. Prepare Data
      final String token = HiveStorage.getToken() ?? "";

      // Get the IDs of the batch being rated (the top 5)
      final List<EncounterData> currentBatch =
          myEncounterViewModel.apiEncounterList.data?.data?.take(5).toList() ??
          [];
      final List<int> ids = currentBatch.map((e) => e.sessionId).toList();

      final Map<String, dynamic> feedbackPayload = {
        "session_ids": ids,
        "accuracy_rating": _accuracyRating,
        "completeness_rating": _completenessRating,
        "usefulness_rating": _usefulnessRating,
        "recommendation": _improvementController.text.trim(),
      };

      // 4. API Call
      // Using your Repository instance (ensure Repository is imported)
      final response = await myEncounterViewModel.postBatchFeedback(
        feedbackPayload,
        token,
      );
      // use status  instead of these messages duffer
      // 5. Handle Response
      // Since your API structure is "Flat", check for standard success
      // Success check
      if (response["message"]?.toString().toLowerCase() == "submitted") {
        _showThankYouDialog();
      }
// Conflict check
      else if (response["detail"] != null &&
          response["detail"].toString().toLowerCase().contains("already submitted")) {
        utils.toastMessage(response["detail"]);
      }
// Fallback for any other error
      else {
        utils.toastMessage(response["message"] ?? response["detail"] ?? "Submission failed");
      }

    } catch (e) {
      debugPrint("Feedback Error: $e");
      utils.toastMessage("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // void _submitForm() async {
  //   if (_accuracyRating == 0 ||
  //       _completenessRating == 0 ||
  //       _usefulnessRating == 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Please provide all ratings")),
  //     );
  //     return;
  //   }
  //
  //   if (!await hasInternet()) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Connection lost. Online access required to submit."),
  //       ),
  //     );
  //     return;
  //   }
  //
  //   // 🚩 PREPARE DATA FOR API (DICT FORMAT)
  //   final List<EncounterData> currentBatch =
  //       myEncounterViewModel.apiEncounterList.data?.data?.take(5).toList() ??
  //       [];
  //   final List<int> ids = currentBatch.map((e) => e.sessionId).toList();
  //
  //   // final Map<String, dynamic> feedbackPayload = {
  //   //   "session_ids": ids,
  //   //   "accuracy_rating": _accuracyRating,
  //   //   "completeness_rating": _completenessRating,
  //   //   "usefulness_rating": _usefulnessRating,
  //   //   "recommendation": _improvementController.text.trim(),
  //   // };
  //   //
  //   // await repo(feedbackPayload, token);
  //
  //   _showThankYouDialog();
  // }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // already non-dismissible by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // disables back button
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF255563)),
              const SizedBox(height: 20),
              const Text(
                "Thank you!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Batch cleared. You can now start new consultations.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF255563),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(120, 45),
                ),
                onPressed: () async {
                  // 🚩 FLUSH: Clear the server counter in Hive to unlock New Encounter
                  await HiveStorage.flushServerBatch();

                  if (mounted) {
                    // Returns to Dashboard
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.dashboard,
                          (route) => false, // removes all previous screens
                    );
                  }
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // void _showThankYouDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //
  //
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(Icons.check_circle, size: 80, color: Color(0xFF255563)),
  //           const SizedBox(height: 20),
  //           const Text(
  //             "Thank you!",
  //             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  //           ),
  //           const Text(
  //             "Batch cleared. You can now start new consultations.",
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 25),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF255563),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(30),
  //               ),
  //               minimumSize: const Size(120, 45),
  //             ),
  //             onPressed: () async {
  //               // 🚩 FLUSH: Clear the server counter in Hive to unlock New Encounter
  //               await HiveStorage.flushServerBatch();
  //
  //               if (mounted) {
  //                 // Returns to Dashboard
  //                 Navigator.pushNamedAndRemoveUntil(
  //                   context,
  //                   RouteNames.dashboard,
  //                   (route) =>
  //                       false, // This "false" tells Flutter to delete all previous screens
  //                 );
  //               }
  //             },
  //             child: const Text(
  //               "Continue",
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _handleErrorLogic(MyEncounterViewModel value) {
    final errorMessage = value.apiEncounterList.message ?? "";
    if (utils.getStatusCodeFromMessage(errorMessage) == 401) {
      HiveStorage.clearHives();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.popAndPushNamed(context, RouteNames.splash),
      );
      return const SizedBox();
    }

    return FutureBuilder<bool>(
      future: hasInternet(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        if (!snapshot.data!) {
          return _buildErrorState(
            image: "assets/icons/internet.png",
            title: "You're offline",
            subtitle:
                "Internet connection is required to verify your batch and unlock new encounters.",
            onRefresh: () => value.getEncounters(),
          );
        }
        return _buildErrorState(
          image: "assets/icons/server.png",
          title: "Service Upgradation",
          subtitle:
              "NourDoc is undergoing a live service upgrade. Please try again in a few minutes.",
          onRefresh: () => value.getEncounters(),
        );
      },
    );
  }

  Widget _buildErrorState({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onRefresh,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 200),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colorprimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: onRefresh,
                child: const Text(
                  "Refresh",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String question,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              int starValue = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starValue),
                child: Icon(
                  starValue <= currentRating ? Icons.star : Icons.star_border,
                  color: starValue <= currentRating
                      ? Colors.amber
                      : Colors.black26,
                  size: 28,
                ),
              );
            }),
          ),
        ),
        const Divider(),
        const SizedBox(height: 15),
      ],
    );
  }
}
