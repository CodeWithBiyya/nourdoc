import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicalai/app/theme/colors.dart';
import 'package:medicalai/core/storage/hive_storage.dart';

class DoctorInfoDialog extends StatefulWidget {
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
  State<DoctorInfoDialog> createState() => _DoctorInfoDialogState();
}

class _DoctorInfoDialogState extends State<DoctorInfoDialog> {
  String _city = "N/A";
  String _country = "N/A";

  @override
  void initState() {
    super.initState();
    final location = _getDisplayValue(HiveStorage.getcity());
    if (location.contains(",")) {
      final parts = location.split(",");
      _city = parts[0].trim();
      _country = parts.length > 1 ? parts[1].trim() : "N/A";
    } else {
      _city = location;
      _lookupCountry(location);
    }
  }

  Future<void> _lookupCountry(String city) async {
    if (city == "N/A") return;
    final found = await _countryForCity(city);
    if (!mounted || found == null) return;
    setState(() {
      _city = found.$1;
      _country = found.$2;
    });
  }

  @override
  Widget build(BuildContext context) {

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
              const DoctorAvatarIcon(size: 72),
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
              _infoRow("City", _city),
              _infoRow("Country", _country),
              _infoRow("License Number", _getDisplayValue(HiveStorage.getlicenseno())),

              const SizedBox(height: 15),

              // 4. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onEdit,
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
                      onPressed: widget.onLogout,
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

Map<String, List<String>>? _citiesByCountry;

Future<(String, String)?> _countryForCity(String city) async {
  _citiesByCountry ??= await _loadCitiesByCountry();
  final needle = city.toLowerCase().trim();
  for (final entry in _citiesByCountry!.entries) {
    for (final name in entry.value) {
      if (name.toLowerCase().trim() == needle) {
        return (name, entry.key);
      }
    }
  }
  return null;
}

Future<Map<String, List<String>>> _loadCitiesByCountry() async {
  final raw = await rootBundle.loadString('assets/files/countries.json');
  final data = json.decode(raw) as Map<String, dynamic>;
  return data.map((key, value) => MapEntry(key, List<String>.from(value as List)));
}

class DoctorAvatarIcon extends StatelessWidget {
  final double size;

  const DoctorAvatarIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _DoctorAvatarPainter(),
    );
  }
}

class _DoctorAvatarPainter extends CustomPainter {
  const _DoctorAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 40;
    final Paint primary = Paint()
      ..color = Colorprimary
      ..style = PaintingStyle.fill;
    final Paint white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint line = Paint()
      ..color = Colorprimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path shoulders = Path()
      ..moveTo(5 * s, 39 * s)
      ..quadraticBezierTo(20 * s, 23 * s, 35 * s, 39 * s)
      ..lineTo(35 * s, 40 * s)
      ..lineTo(5 * s, 40 * s)
      ..close();
    canvas.drawPath(shoulders, primary);

    canvas.drawCircle(Offset(20 * s, 17.5 * s), 7.4 * s, white);
    canvas.drawCircle(Offset(20 * s, 17.5 * s), 7.4 * s, line);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10.5 * s, 5.2 * s, 19 * s, 7.6 * s),
        Radius.circular(1.6 * s),
      ),
      primary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8.2 * s, 11.6 * s, 23.6 * s, 2.5 * s),
        Radius.circular(1.2 * s),
      ),
      primary,
    );

    final Paint cross = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(20 * s, 6.6 * s), Offset(20 * s, 11.2 * s), cross);
    canvas.drawLine(Offset(17.8 * s, 8.9 * s), Offset(22.2 * s, 8.9 * s), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



