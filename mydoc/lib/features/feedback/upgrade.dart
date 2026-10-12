import 'package:flutter/material.dart';
// Assuming Colorprimary is defined in your colors file
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/routes/routs_name.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  // Specific colors from the design

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
        title: const Text(
          "NourDoc",
          style: TextStyle(
            color: Color(0xFF63A9B8), // Brand Teal
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 1. Title
            const Text(
              "Continue documenting smarter\nwith NourDoc",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),

            // 2. Subtitle
            Text(
              "Upgrade to unlock unlimited access and enhanced documentation features.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // 3. Feature List
            _buildFeatureItem(Icons.auto_awesome, "Unlimited AI consultation reports"),
            _buildFeatureItem(Icons.layers_outlined, "Smarter clinical structuring"),
            _buildFeatureItem(Icons.wc_outlined, "Age- and gender-optimized insights"),
            _buildFeatureItem(Icons.mic_none_outlined, "Advanced noise-filtered transcription"),
            _buildFeatureItem(Icons.description_outlined, "PDF and HTML report formats"),

            const SizedBox(height: 50),

            // 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colorprimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      "Contact sales",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.subscription_screen);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colorprimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Choose a plan",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. Footer Text
            Text(
              "You can upgrade anytime from Settings.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget for feature list items
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}