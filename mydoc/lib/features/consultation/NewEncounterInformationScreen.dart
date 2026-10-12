import 'package:flutter/material.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:provider/provider.dart';
import '../utils/appDialog.dart';
import '../utils/hive_storage.dart';
import 'consultation_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart' as intl_data;

class NewEncounterInformationScreen extends StatefulWidget {
  const NewEncounterInformationScreen({super.key});

  @override
  State<NewEncounterInformationScreen> createState() =>
      _NewEncounterInformationScreen();
}

class _NewEncounterInformationScreen extends State<NewEncounterInformationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  String _completePhoneNumber = "";
  String _currentIsoCode = 'PK';
  Key _phoneWidgetRefreshKey = UniqueKey();

  String? selectedGender = "Male";
  String? selectedVisitType = "New";
  bool _isBookingLoading = false;

  String? selectedTemp, selectedPulse, selectedRespiration, selectedSysBP, selectedDiaBP, selectedSugar;

  late ConsultationViewModel consultationViewModel;

  // Optimized: Pre-calculate dropdown items to save CPU cycles during build
  late List<DropdownMenuItem<String>> ageItems;
  late List<DropdownMenuItem<String>> tempItems;
  late List<DropdownMenuItem<String>> pulseItems;
  late List<DropdownMenuItem<String>> respItems;
  late List<DropdownMenuItem<String>> sysBPItems;
  late List<DropdownMenuItem<String>> diaBPItems;
  late List<DropdownMenuItem<String>> sugarItems;

  @override
  void initState() {
    super.initState();
    consultationViewModel = ConsultationViewModel();
    _setInitialCountryFromDoctor();
    _precomputeDropdowns();
  }

  void _precomputeDropdowns() {
    ageItems = List.generate(121, (i) => DropdownMenuItem(
      value: i == 0 ? "0-1" : i.toString(),
      child: Text(i == 0 ? "< 1 Year" : "$i"),
    ));

    tempItems = [for (int i = 94; i <= 106; i++) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
    pulseItems = [for (int i = 40; i <= 180; i++) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
    respItems = [for (int i = 8; i <= 50; i++) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
    sysBPItems = [for (int i = 80; i <= 200; i++) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
    diaBPItems = [for (int i = 40; i <= 130; i++) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
    sugarItems = [for (int i = 40; i <= 500; i += 10) DropdownMenuItem(value: i.toString(), child: Text(i.toString()))];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setInitialCountryFromDoctor() {
    String? doctorPhone = HiveStorage.getPhone();
    if (doctorPhone != null && doctorPhone.startsWith("+")) {
      for (var country in intl_data.countries) {
        if (doctorPhone.startsWith("+${country.dialCode}")) {
          _currentIsoCode = country.code;
          break;
        }
      }
    }
  }

  String _capitalizeName(String value) {
    if (value.trim().isEmpty) return "";
    return value.trim().split(' ').map((word) => word.isEmpty ? "" : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colorprimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text("NourDoc", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: ChangeNotifierProvider<ConsultationViewModel>.value(
        value: consultationViewModel,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Patient Details', style: TextStyle(color: Colorprimary, fontWeight: FontWeight.w900, fontSize: 32)),
                    const SizedBox(height: 25),
                    _buildSectionTitle("Patient Name *"),
                    _buildTextField(_nameController, "Enter full name"),
                    const SizedBox(height: 10),
                    _buildSectionTitle("Phone Number *"),
                    _buildPhoneField(),
                    const SizedBox(height: 15),
                    _buildSectionTitle("Age *"),
                    _buildAgeDropdown(),
                    const SizedBox(height: 10),
                    _buildSectionTitle("Gender"),
                    _buildGenderSelection(),
                    const SizedBox(height: 15),
                    _buildSectionTitle("Vitals (Optional)"),
                    const SizedBox(height: 10),
                    _buildVitalsGrid(),
                    const SizedBox(height: 10),
                    _buildSectionTitle("Visit Type"),
                    _buildVisitTypeSelection(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // --- Optimized Helper Widgets ---

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: IntlPhoneField(
        key: _phoneWidgetRefreshKey,
        controller: _phoneController,
        initialCountryCode: _currentIsoCode,
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        dropdownIconPosition: IconPosition.trailing,
        flagsButtonPadding: const EdgeInsets.only(left: 15),
        decoration: InputDecoration(
          hintText: 'xxxxxxx...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
        onCountryChanged: (country) {
          setState(() {
            _currentIsoCode = country.code;
            _phoneController.clear();
            _completePhoneNumber = "";
          });
        },
        onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
      ),
    );
  }

  Widget _buildVitalsGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 5,
      ),
      children: [
        _buildVitalDropdown("Temp (°F)", selectedTemp, tempItems, (v) => setState(() => selectedTemp = v)),
        _buildVitalDropdown("Pulse (bpm)", selectedPulse, pulseItems, (v) => setState(() => selectedPulse = v)),
        _buildVitalDropdown("Resp (bpm)", selectedRespiration, respItems, (v) => setState(() => selectedRespiration = v)),
        _buildBPField(),
        _buildVitalDropdown("Sugar (mg/dL)", selectedSugar, sugarItems, (v) => setState(() => selectedSugar = v)),
      ],
    );
  }

  Widget _buildVitalDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(" $label", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              isExpanded: true,
              value: value,
              hint: const Text("-", style: TextStyle(fontSize: 14)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
          isExpanded: true,
          hint: Text("Select Age", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          value: _ageController.text.isEmpty ? null : _ageController.text,
          items: ageItems,
          onChanged: (value) => setState(() => _ageController.text = value!),
        ),
      ),
    );
  }

  Widget _buildBPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(" BP (mmHg)", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(child: _miniBPBox(selectedSysBP, sysBPItems, "Sys", (v) => setState(() => selectedSysBP = v))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("/", style: TextStyle(color: Colors.grey))),
            Expanded(child: _miniBPBox(selectedDiaBP, diaBPItems, "Dia", (v) => setState(() => selectedDiaBP = v))),
          ],
        ),
      ],
    );
  }

  Widget _miniBPBox(String? value, List<DropdownMenuItem<String>> items, String hint, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 11)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Row(
        children: [
          Expanded(child: _buildPrimaryButton("Continue", _onSaveContinue)),
          const SizedBox(width: 10),
          Expanded(
            child: _isBookingLoading
                ? const Center(child: CircularProgressIndicator(color: Colorprimary))
                : OutlinedButton(
              onPressed: _handlePreBooking,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colorprimary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text("Book For Later", style: TextStyle(color: Colorprimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Functions ---

  void _onSaveContinue() async {
    if (_nameController.text.isNotEmpty && _ageController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      if (!await _shouldProceedWithVitalsCheck()) return;

      // 1. Pehle Vitals ka nested map banayein (Same as handlePreBooking)
      Map<String, dynamic> vitalsMap = {
        "Temperature": selectedTemp,
        "Pulse": selectedPulse,
        "Respiration": selectedRespiration,
        "Blood Pressure": (selectedSysBP != null && selectedDiaBP != null)
            ? "$selectedSysBP/$selectedDiaBP"
            : null,
        "Sugar": selectedSugar,
      };

      // Khali vitals ko remove karein
      vitalsMap.removeWhere((key, value) => value == null || value.toString().isEmpty);

      // 2. Main navigation arguments banayein
      Map<String, dynamic> navigationArgs = {
        "name_patient": _capitalizeName(_nameController.text.trim()),
        "gender": selectedGender!,
        "age": _ageController.text,
        "patient_phone": _completePhoneNumber,
        "visit_type": selectedVisitType!,
      };

      // 3. Agar vitals hain, to "vitals" key add karein
      if (vitalsMap.isNotEmpty) {
        navigationArgs["vitals"] = vitalsMap;
      }

      // Khali main fields ko clean karein
      navigationArgs.removeWhere((key, value) => value == null || value.toString().isEmpty);

      utils.checkEntitlementAndLimit(context).then((allowed) {
        if (allowed) {
          Navigator.pushNamed(
            context,
            RouteNames.audioRecorderScreen,
            arguments: navigationArgs,
          );
        }
      });
    } else {
      utils.toastMessage("Fill Patient Name, Phone and Age");
    }
  }

  Future<void> _handlePreBooking() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _phoneController.text.isEmpty) {
      utils.toastMessage("Please fill Patient Name, Age and Contact");
      return;
    }
    if (!await _shouldProceedWithVitalsCheck()) return;

    setState(() => _isBookingLoading = true);

    // 1. Pehle Vitals ka Map banayein
    Map<String, dynamic> vitalsMap = {
      "Temperature": selectedTemp,
      "Pulse": selectedPulse,
      "Respiration": selectedRespiration,
      "Blood Pressure": (selectedSysBP != null && selectedDiaBP != null)
          ? "$selectedSysBP/$selectedDiaBP"
          : null,
      "Sugar": selectedSugar,
    };

    // 2. Vitals map se null ya empty values remove karein
    vitalsMap.removeWhere((key, value) => value == null || value.toString().isEmpty);

    // 3. Main Data Map banayein
    Map<String, dynamic> data = {
      "doctor_id": HiveStorage.getEmail() ?? "",
      "patient_name": _capitalizeName(_nameController.text.trim()),
      "patient_phone": _completePhoneNumber,
      "patient_age": _ageController.text,
      "patient_gender": selectedGender!,
      "visit_type": selectedVisitType!,
    };

    // 4. Agar vitalsMap khali nahi hai, to hi "vitals" key add karein
    if (vitalsMap.isNotEmpty) {
      data["vitals"] = vitalsMap;
    }

    try {
      dynamic response = await consultationViewModel.saveNewBooking(data);
      if (response != null && response["custom_status"] == 200) {
        utils.toastMessage("Patient booked!");
        Navigator.pop(context);
      } else {
        utils.toastMessage(response["message"] ?? "Booking failed");
      }
    } catch (e) {
      utils.toastMessage("Something went wrong.");
    } finally {
      if (mounted) setState(() => _isBookingLoading = false);
    }
  }

  // --- Reuse existing helper UI methods from your code ---
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)));
  Widget _buildTextField(TextEditingController controller, String hint) => Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)), child: TextField(controller: controller, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))));
  Widget _buildGenderSelection() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ["Male", "Female", "Prefer not to disclose"].map((e) => _genderChip(e)).toList()));
  Widget _buildVisitTypeSelection() => Row(children: [_visitTypeChip("New"), const SizedBox(width: 20), _visitTypeChip("Follow up")]);

  Widget _buildPrimaryButton(String text, VoidCallback onTap) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))));

  Widget _visitTypeChip(String value) => Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 24, width: 24, child: Radio<String>(value: value, groupValue: selectedVisitType, activeColor: Colorprimary, onChanged: (v) => setState(() => selectedVisitType = v))), const SizedBox(width: 8), Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500))]);
  Widget _genderChip(String value) => Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 24, width: 24, child: Radio<String>(value: value, groupValue: selectedGender, activeColor: Colorprimary, onChanged: (v) => setState(() => selectedGender = v))), const SizedBox(width: 8), Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(width: 15)]);

  Future<bool> _shouldProceedWithVitalsCheck() async {
    bool sysSelected = selectedSysBP != null;
    bool diaSelected = selectedDiaBP != null;
    bool isBPIncomplete = sysSelected != diaSelected;
    int filledCount = 0;
    if (selectedTemp != null) filledCount++;
    if (selectedPulse != null) filledCount++;
    if (selectedRespiration != null) filledCount++;
    if (sysSelected && diaSelected) filledCount++;
    if (selectedSugar != null) filledCount++;

    if (filledCount >= 3 && !isBPIncomplete) return true;

    return await showAppDialog<bool>(
      context: context,
      icon: Icons.warning_amber_outlined,
      title: filledCount == 0 ? "Vitals Missing" : "Incomplete Vitals",
      content: isBPIncomplete ? "Blood Pressure requires both values." : "Some vitals are not filled. complete the missing vitals for better accuracy.",
      primaryText: "Fill Vitals",
      secondaryText: isBPIncomplete ? null : "Proceed Anyway",
      onPrimary: () => Navigator.pop(context, false),
      onSecondary: () => Navigator.pop(context, true),
    ) ?? false;
  }
}