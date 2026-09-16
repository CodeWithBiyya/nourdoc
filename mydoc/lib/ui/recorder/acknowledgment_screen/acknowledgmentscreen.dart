import 'package:flutter/material.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/colors.dart';
import '../../../utils/hive_storage.dart';

class AcknowledgmentScreen extends StatelessWidget {
  const AcknowledgmentScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final String patientName = args['name_patient'] ?? "N/A";
    final String doctorName = HiveStorage.getName() ?? "Doctor";
    final String duration = args['duration'] ?? "0 sec";

    return WillPopScope(
      onWillPop: () async {
        // Navigator.pushNamedAndRemoveUntil(context, RouteNames.dashboard, (route) => false);
        _handleBackNavigation(context); // 🚩 Call the fix

        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, // Matches your screen background
          elevation: 0,
          // 🔹 1. This controls the total width allowed for the icon area.
          // Set it small so it sits close to the edge.
          leadingWidth: 55,

          leading: GestureDetector(
            onTap: () {

              _handleBackNavigation(context); // 🚩 Call the fix

            },
            child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
              child: Image.asset(
                "assets/icons/home_button.png",
                 width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
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
        // 🔹 LayoutBuilder is the key to "Constraint" logic in Flutter
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Forces the column to be at least as tall as the screen
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: IntrinsicHeight( // Ensures the Column works with Spacer
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/icons/black_notext.png",
                          width: MediaQuery.of(context).size.width * 0.60,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Consultation Submitted",
                          style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "AI-powered medical consultation summary is being generated",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            text: "Thank you, ",
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                            children: [
                              TextSpan(
                                text: "Dr. $doctorName",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- INFO BOX ---
                        _buildMainInfoBox(patientName, duration),

                        const SizedBox(height: 30),

                        // --- STEPS ---
                        _buildStepsSection(),

                        // 🔹 THIS SPACER IS THE "CONSTRAINT"
                        // It pushes everything below it to the bottom of the screen
                        const Spacer(),


                        Row(
                          children: [
                            // Button 1: New Consultation
                            Expanded(
                              child: _buildButton(
                                text: "New Consult",
                                icon: Icons.add,
                                isPrimary: true,
                                onTap: () {
                                  Navigator.pushNamedAndRemoveUntil(context, RouteNames.dashboard, (route) => false);
                                  Navigator.pushNamed(context, RouteNames.consultationSelection);
                                },
                              ),
                            ),

                            const SizedBox(width: 8), // Slightly smaller gap to save space

                            // Button 2: All Consultations
                            Expanded(
                              child: _buildButton(
                                text: " All Consultations", // Shortened to fit comfortably with eye icon
                                icon: Icons.visibility_outlined,
                                isPrimary: false,
                                onTap: () {
                                  Navigator.pushNamedAndRemoveUntil(context, RouteNames.dashboard, (route) => false);
                                  Navigator.pushNamed(context, RouteNames.MyEncountersScreen);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 60), // Safe padding at the very bottom
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  void _handleBackNavigation(BuildContext context) {
    // 1. Reset the app to the Dashboard (This becomes the new bottom of the stack)
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
          (route) => false,
    );

    // 2. Immediately push the Consultation Selection screen on top
    Navigator.pushNamed(context, RouteNames.consultationSelection);
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        // 🔹 Replace Spacer() with a small fixed gap
        const SizedBox(width: 10),
        // 🔹 Wrap the value text in Expanded to occupy the remaining space
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end, // 👈 Keeps the text aligned to the right
            maxLines: 1,              // 👈 Forces text to stay on one line
            overflow: TextOverflow.ellipsis, // 👈 Adds "..." if the name is too long
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colorprimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }



  // --- REUSABLE UI HELPERS TO KEEP CODE CLEAN ---

  Widget _buildMainInfoBox(String name, String dur) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, "Patient", name),
          Divider(color: Colors.grey.shade100, height: 25),
          _buildInfoRow(Icons.timer_outlined, "Duration", dur),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What happens next?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        _buildStep(Icons.auto_awesome_outlined, "AI is processing the medical report."),
        _buildStep(Icons.mail_outline, "A copy will be sent to your email."),
        _buildStep(Icons.description_outlined, "View results in the Consultation tab."),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap
  }) {
    final buttonStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12, // 🔹 Smaller font as requested
    );

    return SizedBox(
      height: 45,
      child: isPrimary
          ? ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16), // 🔹 Add Icon
        label: Text(text, style: buttonStyle),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colorprimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
      )
          : OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16), // 🔹 Eye Icon
        label: Text(text, style: buttonStyle),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          side: const BorderSide(color: Colors.black, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }}
