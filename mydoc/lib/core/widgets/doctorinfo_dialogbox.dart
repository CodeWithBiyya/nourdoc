import 'package:flutter/material.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';

class DoctorInfoDialog extends StatelessWidget {
  final String imagePath;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const DoctorInfoDialog({
    super.key,
    required this.imagePath,
    required this.onEdit,
    required this.onLogout,
  });


  @override
  Widget build(BuildContext context) {
    // Logic to handle City/Country split if stored together
    String location = _getDisplayValue(HiveStorage.getcity());
    String city = "N/A";
    String country = "N/A";
    if (location.contains(",")) {
      var parts = location.split(",");
      city = parts[0].trim();
      country = parts[1].trim();
    } else {
      city = location;
    }

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView( // 👈 1. Added ScrollView here
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 👈 2. Keeps dialog compact
            children: [
              // 1. Doctor Image
              Image.asset(
                'assets/icons/Doc.png',
                height: 90, // Adjust the height as needed
                width: 90,  // Adjust the width as needed
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),

              // 2. Title
              Text(
                "Doctor's Personal Information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colorprimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Information List
              _infoRow("Name", _getDisplayValue(HiveStorage.getName())),
              _infoRow("E-Mail", _getDisplayValue(HiveStorage.getEmail())),
              _infoRow("Contact", _getDisplayValue(HiveStorage.getPhone())),
              _infoRow("Speciality", _getDisplayValue(HiveStorage.getspeciallisation())),
              _infoRow("Experience", "${_getDisplayValue(HiveStorage.getexperience())} years"),
              _infoRow("City", city),
              _infoRow("Country", country),
              _infoRow("License Number", _getDisplayValue(HiveStorage.getlicenseno())),

              const SizedBox(height: 15),

              // 4. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colorprimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onLogout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1.2),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Helper to build the Label: Value rows
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.4),
            children: [
              TextSpan(text: "$label: "),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayValue(String? value) {
    if (value == null || value == "null" || value.isEmpty) {
      return "N/A";
    }
    return value;
  }
}



