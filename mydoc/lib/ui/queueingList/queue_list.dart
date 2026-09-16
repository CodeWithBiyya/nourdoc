

import 'package:flutter/material.dart';
import 'package:medicalai/ui/queueingList/queue_list_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../model/pending_consultation.dart';
import '../../routes/routs_name.dart';
import '../../utils/colors.dart';
import '../../utils/appDialog.dart';
import '../../utils/hive_storage.dart';
import '../../utils/noInternet.dart';
import '../../utils/utils.dart';
import 'package:flutter/cupertino.dart';


class OutboxListScreen extends StatefulWidget {
  const OutboxListScreen({super.key});

  @override
  State<OutboxListScreen> createState() => _OutboxListScreenState();
}

class _OutboxListScreenState extends State<OutboxListScreen> {
  final OutboxViewModel outboxViewModel = OutboxViewModel();

  @override
  void initState() {
    super.initState();
    outboxViewModel.fetchOutbox();
  }

  void _navigateBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.consultationSelection,
          (route) => route.settings.name == RouteNames.dashboard,
    );
  }

  // 🚩 NEW: Updated to handle the specific loading state
  void _showConfirmUploadDialog(dynamic hiveKey, String patientName) async {
    if (!await hasInternet()) {
      utils.toastMessage("You are offline. Connect to internet to upload.");
      return;
    }

    showAppDialog(
      context: context,
      icon: Icons.cloud_upload_outlined,
      title: "Upload Consultation?",
      content: "Do you want to upload the consultation for $patientName now?",
      primaryText: "Upload Now",
      onPrimary: () async {
        Navigator.pop(context); // Close the confirmation dialog

        // 🚩 Trigger the health check on the card
        bool isHealthy = await outboxViewModel.isServerAvailable(hiveKey);

        if (!mounted) return;

        if (isHealthy) {
          Navigator.pushNamed(
            context,
            RouteNames.manualUploadScreen,
            arguments: {'hiveKey': hiveKey},
          ).then((_) => outboxViewModel.fetchOutbox());
        } else {
          // If health check fails or times out
          showAppDialog(
            context: context,
            icon: Icons.sync_problem_rounded,
            title: "Connection Timed Out",
            content: "NourDoc is having trouble reaching the server. This could be a slow network or a temporary upgrade. Please try again in a few minutes.",
            primaryText: "Understood",
            onPrimary: () => Navigator.pop(context),
          );
        }
      },
      secondaryText: "Cancel",
      onSecondary: () => Navigator.pop(context),
    );
  }

  Widget _buildOutboxItem(
      BuildContext context,
      int number,
      PendingConsultation patient,
      dynamic hiveKey,
      ) {
    final viewModel = Provider.of<OutboxViewModel>(context);
    bool isThisItemChecking = viewModel.checkingKey == hiveKey;

    // 🚩 Format the date/time so the doctor knows when this was recorded
    String formattedDate = "${patient.startTime.day}/${patient.startTime.month}/${patient.startTime.year} at ${patient.startTime.hour}:${patient.startTime.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: isThisItemChecking ? null : () {
          int serverCount = HiveStorage.getServerBatchCount();
          if (serverCount >= 5) {
            Navigator.pushNamed(context, RouteNames.free_trial);
          } else {
            _showConfirmUploadDialog(hiveKey, patient.patientName);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isThisItemChecking ? Colorprimary : Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Text("$number.", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colorprimary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThisItemChecking ? "VERIFYING SERVER..." : "RECORDED ON $formattedDate",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isThisItemChecking ? Colorprimary : Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 🚩 Fallback if name is empty
                    Text(
                      patient.patientName.isEmpty ? "Unnamed Consultation" : patient.patientName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(patient.gender.toLowerCase() == 'male' ? Icons.male : Icons.female, size: 14, color: Colorprimary),
                        const SizedBox(width: 4),
                        Text("Age: ${patient.age} • ${_formatTime(patient.startTime)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              isThisItemChecking
                  ? const SizedBox(width: 26, height: 26, child: CupertinoActivityIndicator(color: Colorprimary))
                  : const Icon(Icons.cloud_upload_outlined, color: Colorprimary, size: 26),
            ],
          ),
        ),
      ),
    );
  }

// Helper to format time
  String _formatTime(DateTime dt) => "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

  // ... (Include _buildEmptyState and the main build method from your original code)
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colorprimary), onPressed: _navigateBack),
          title: const Text("Pending Uploads", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: ChangeNotifierProvider<OutboxViewModel>.value(
          value: outboxViewModel,
          child: Consumer<OutboxViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) return const Center(child: CircularProgressIndicator(color: Colorprimary));
              if (viewModel.outboxItems.isEmpty) return _buildEmptyState();

              return RefreshIndicator(
                onRefresh: () async => viewModel.fetchOutbox(),
                color: Colors.black,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: viewModel.outboxItems.length,
                  itemBuilder: (context, index) {
                    final entry = viewModel.outboxItems[index];
                    return _buildOutboxItem(context, index + 1, entry.value, entry.key);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("Outbox is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
