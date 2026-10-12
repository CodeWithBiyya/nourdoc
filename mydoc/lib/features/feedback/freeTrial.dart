import 'package:flutter/material.dart';
import 'package:medicalai/routes/routs_name.dart';

class FreeTrialLimitScreen extends StatelessWidget {
  const FreeTrialLimitScreen({super.key});

  final Color primaryTeal = const Color(0xFF63A9B8);
  final Color darkTeal = const Color(0xFF2E5E6E);
  final Color goldYellow = const Color(0xFFFFC542);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text("NourDoc", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond_outlined, size: 100, color: goldYellow),
            const SizedBox(height: 20),
            const Text("5/5 Free Reports Used", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: darkTeal, borderRadius: BorderRadius.circular(2)),
                ),
              )),
            ),
            const SizedBox(height: 30),
            const Text("Batch Milestone Reached", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(
              "You have reached your 5-report milestone. Please provide quick feedback on this batch to continue with new consultations.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: darkTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                onPressed: () => Navigator.pushNamed(context, RouteNames.feedback_collection),
                child: const Text("Provide Feedback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}