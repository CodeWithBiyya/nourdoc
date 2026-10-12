import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicalai/data/response/status.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:provider/provider.dart';
import '../../model/BookedPatientData.dart';
import '../utils/appDialog.dart';
import '../utils/hive_storage.dart';
import '../utils/noInternet.dart';
import '../utils/utils.dart';
import 'consultation_viewmodel.dart';

class ConsultationSelectionScreen extends StatefulWidget {
  const ConsultationSelectionScreen({super.key});

  @override
  State<ConsultationSelectionScreen> createState() =>
      _ConsultationSelectionScreenState();
}

class _ConsultationSelectionScreenState
    extends State<ConsultationSelectionScreen> {
  ConsultationViewModel consultationViewModel = ConsultationViewModel();

  @override
  void initState() {
    super.initState();
    consultationViewModel.getBookedPatients();
  }

  void _refreshData() {
    consultationViewModel.getBookedPatients();
  }

  void _navigateBack() {
    // 🚩 Professional Fix: Clear history and go to Dashboard
    // This prevents the "Black Screen" crash and ensures the Dashboard refreshes.
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
          (route) => false,
    );
  }
  String formatBookingTimestamp(String isoDate) {
    if (isoDate.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(isoDate);
      // Returns: 30-Mar-2026 • 03:54 PM
      return DateFormat('dd-MMM-yyyy • hh:mm a').format(dt);
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // 🚩 Prevent default system pop
        onPopInvoked: (didPop) {
          if (didPop) return;
          _navigateBack(); // 🚩 Handle hardware back button
        },
        child:
      Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colorprimary),
        centerTitle: true,
        title: const Text(
          "NourDoc",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      //final , when bookign api availbe
      body: ChangeNotifierProvider<ConsultationViewModel>(
        create: (BuildContext context) => consultationViewModel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATIC HEADER & BUTTONS (Always Visible)
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 10.0, top: 10),
              child: Text(
                'New Consultation',
                style: TextStyle(
                  color: Colorprimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildNewConsultationButton(),
                  // 🚩 Keeping your Outbox Button logic
                  if ( HiveStorage.getOutBoxCount() > 0) ...[
                    const SizedBox(height: 15),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colorprimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => Navigator.pushNamed(context, RouteNames.queuelist).then((_) {
                        setState(() {});
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.outbox_rounded, color: Colorprimary),
                          const SizedBox(width: 10),
                          Text(
                            "View Outbox (${HiveStorage.getOutBoxCount()})",
                            style: const TextStyle(color: Colorprimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. DYNAMIC AREA (Restored Booking List)
            Expanded(
              child: Consumer<ConsultationViewModel>(
                builder: (context, value, child) {
                  // STATE: LOADING
                  if (value.bookedPatientList.status == Status.LOADING) {
                    return const Center(child: CircularProgressIndicator(color: Colorprimary));
                  }

                  // STATE: ERROR
                  if (value.bookedPatientList.status == Status.ERROR) {
                    return _handleError(value);
                  }

                  // STATE: COMPLETE
                  if (value.bookedPatientList.status == Status.COMPLETE) {
                    final rawPatients = value.bookedPatientList.data ?? [];

                    // CASE A: EMPTY (No pre-booked patients)
                    if (rawPatients.isEmpty) {
                      return _buildScrollableIllustration(_buildNoPrebookedEmptyState());
                    }

                    // CASE B: LIST (Show patients)
                    final patients = rawPatients;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        const Center(child: Text("OR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Select from pre-booked list", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => await consultationViewModel.getBookedPatients(),
                            color: Colors.black,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: patients.length,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemBuilder: (context, index) {
                                return _buildPrebookedItem(index + 1, patients[index]);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),


      floatingActionButton: FloatingActionButton.extended(
        heroTag: "selection_view_btn",
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onPressed: () =>
            Navigator.pushNamed(context, RouteNames.MyEncountersScreen),
        label: const Text(
          "Consultations",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.manage_search_outlined, color: Colors.black),
      ),
    ),);

  }

  Widget _buildOutboxCard() {
    int count = HiveStorage.getOutBoxCount();
    if (count == 0) return const SizedBox.shrink(); // Hide if empty

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.queuelist),
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colorprimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colorprimary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Colorprimary, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$count Pending Uploads",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colorprimary,
                    ),
                  ),
                  const Text(
                    "Tap to sync consultations to the server.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colorprimary),
          ],
        ),
      ),
    );
  }


// --- REFINED ERROR HANDLER ---

  Widget _handleError(ConsultationViewModel value) {
    // 🚩 We removed the 401/Unauthorized redirect logic to prevent the "crash" to login screen.

    return FutureBuilder<bool>(
      future: hasInternet(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final hasNet = snapshot.data!;

        // 1. If Offline: Show Internet Error
        if (!hasNet) {
          return _buildErrorState(
            image: "assets/icons/internet.png",
            title: "You're offline",
            subtitle: "Please check your internet connection.",
            onRefresh: _refreshData,
          );
        }

        // 2. DEFAULT FALLBACK:
        // Even if it's a 401, 400, or 500 error, we show the "No pre-booked" state
        // instead of logging the user out.
        return _buildErrorState(
          image: "assets/icons/emptyPrebook.png",
          title: "No Pre-booked Consultations",
          subtitle: "Currently, there are no consultations available or there was a server response issue.",
          onRefresh: _refreshData,
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildNewConsultationButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colorprimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        int queueCount = HiveStorage.getOutBoxCount();
        

        // 2. Behavior B: Phone Queue is full (5/5). Must sync to free up space.
         if (queueCount >= 5) {
          showAppDialog(
            context: context,
            icon: Icons.cloud_off_rounded,
            title: "Upload Required",
            content: "You have 5 consultations waiting on your device. Please connect to the internet to finish the batch upload.",
            primaryText: "Understood",
            onPrimary: () => Navigator.pop(context),
          );
        }

        // 3. Behavior A: Both are under 5. Allow new consultation.
        else {
          utils.checkEntitlementAndLimit(context).then((allowed) {
            if (allowed) {
              Navigator.pushNamed(context, RouteNames.NewEncounterInformationScreen)
                  .then((_) => consultationViewModel.getBookedPatients());
            }
          });
        }
      },


      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "New Consultation",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.add, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildScrollableIllustration(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () async =>
              await consultationViewModel.getBookedPatients(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoPrebookedEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "assets/icons/emptyPrebook.png",
          height: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          "No Prebook Patients",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // const SizedBox(height: 8),
        // const Text("Pull down to refresh", style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

// ... inside ConsultationSelectionScreen state ...
  Widget _buildPrebookedItem(int number, BookedPatientData patient) {
    // 🚩 FIX: Debugging ke liye (Console check karein agar name ab bhi na aaye)
    debugPrint("Booking ID: ${patient.bookingId}, Name: ${patient.patientName}");

    // 🚩 Logic from 2nd code: Check if name is empty
    String displayName = patient.patientName.trim().isEmpty ? "Name Missing" : patient.patientName;

    // Format age label
    String ageLabel = (patient.age == "0-1" || patient.age == "0") ? "0-1" : patient.age;

    // Date Logic
    String displayDate = patient.date.isNotEmpty ? patient.date : "N/A";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
  // ============================================================
  // SAFETY CHECK: PREVENT RE-CONSULTATION
  // ============================================================

  final String bookingId =
      patient.bookingId.toString().trim();

  // Prevent recording the same booking twice
  if (HiveStorage.isBookingCompleted(bookingId)) {
    showAppDialog(
      context: context,
      icon: Icons.check_circle_outline,
      title: "Already Consulted",
      content:
          "This patient has already completed a consultation.",
      primaryText: "OK",
      onPrimary: () => Navigator.pop(context),
    );

    return;
  }

  // ============================================================
  // EXISTING OUTBOX LIMIT CHECK
  // ============================================================

  if (HiveStorage.getOutBoxCount() >= 5) {
    showAppDialog(
      context: context,
      icon: Icons.cloud_off_rounded,
      title: "Upload Required",
      content:
          "You have 5 consultations waiting to upload. Please sync these before starting another from the list.",
      primaryText: "Understood",
      onPrimary: () => Navigator.pop(context),
    );
  } else {
    utils.checkEntitlementAndLimit(context).then((allowed) {
      if (allowed) {
        Navigator.pushNamed(
          context,
          RouteNames.audioRecorderScreen,
          arguments: {
            "booking_id": patient.bookingId,
            "name_patient": patient.patientName,
            "gender": patient.gender,
            "age": patient.age,
            "visit_type": "New",
            "patient_id": patient.patientId,
            "patient_phone": patient.patientPhone,
            "dob": "",
            "temp": patient.temp,
            "pulse": patient.pulse,
            "resp_rate": patient.resp_rate,
            "bp": patient.bp,
            "sugar": patient.sugar,
          },
        );
      }
    });
  }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index Number
              Text(
                  "$number.",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colorprimary
                  )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚩 FIX: Patient Name (Direct use with fallback)
                    Text(
                      displayName, // "Name Missing" dikhayega agar API se nahi aa raha
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 2),

                    // METADATA ROW: Date, Gender, Age
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        children: [
                          TextSpan(text: "Date: $displayDate • "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              patient.gender.toLowerCase().startsWith('m')
                                  ? Icons.male
                                  : Icons.female,
                              size: 14,
                              color: Colorprimary,
                            ),
                          ),
                          TextSpan(text: " ${patient.gender} • Age: $ageLabel Y"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // VITALS WRAP
                    Wrap(
                      runSpacing: 4,
                      children: [
                        _miniVital(Icons.favorite, patient.pulse, "bpm"),
                        _miniVital(Icons.monitor_weight_outlined, patient.sugar, "mg"),
                        _miniVital(Icons.air, patient.resp_rate, "bpm"),
                        _miniVital(Icons.thermostat, patient.temp, "°F"),
                        _miniVital(Icons.speed, patient.bp, "mmHg"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 

  Widget _miniVital(IconData icon, String? value, String unit) {
    if (value == null || value.isEmpty || value == "null")
      return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colorprimary),
        // const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        if (unit.isNotEmpty)
          Text(
            " $unit",
            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
          ),

        const SizedBox(width: 6,)
      ],
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
            Image.asset(image, height: 220, fit: BoxFit.contain),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 250,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colorprimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                onPressed: onRefresh,
                child: const Text(
                  "Refresh",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
