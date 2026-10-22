import 'package:flutter/material.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/app/theme/colors.dart';
import 'package:medicalai/core/common/utils.dart';
import 'package:provider/provider.dart';
import '../../core/common/appDialog.dart';
import '../../core/storage/hive_storage.dart';
import 'consultation_viewmodel.dart';
import 'package:flutter/services.dart';
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
  intl_data.Country _country = intl_data.countries.firstWhere((country) => country.code == 'PK');
  final GlobalKey _phoneFieldKey = GlobalKey();
  OverlayEntry? _countryMenu;

  String? selectedGender = "Male";
  String? selectedVisitType = "New";
  bool _isBookingLoading = false;

  String? selectedTemp, selectedPulse, selectedRespiration, selectedSysBP, selectedDiaBP, selectedSugar;

  late ConsultationViewModel consultationViewModel;
  Future<bool>? _entryAccess;

  late List<_Option> ageItems;
  late List<_Option> tempItems;
  late List<_Option> pulseItems;
  late List<_Option> respItems;
  late List<_Option> sysBPItems;
  late List<_Option> diaBPItems;
  late List<_Option> sugarItems;

  @override
  void initState() {
    super.initState();
    consultationViewModel = ConsultationViewModel();
    _setInitialCountryFromDoctor();
    _precomputeDropdowns();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryGate();
    });
  }

  Future<bool> _entryGate() {
    return _entryAccess ??= _checkEntryAccess();
  }

  Future<bool> _checkEntryAccess() async {
    final snapshot = await utils.requireProtectedAccess(context, showProgress: false);
    if (!mounted) return false;
    if (snapshot != null) return true;
    if (utils.planBlocksConsultation) {
      Navigator.of(context).pop();
      return false;
    }
    _entryAccess = null;
    return false;
  }

  void _precomputeDropdowns() {
    ageItems = List.generate(
      121,
      (i) => i == 0 ? const _Option("0-1", "< 1 Year") : _Option("$i", "$i"),
    );
    tempItems = [for (int i = 94; i <= 106; i++) _Option("$i", "$i")];
    pulseItems = [for (int i = 40; i <= 180; i++) _Option("$i", "$i")];
    respItems = [for (int i = 8; i <= 50; i++) _Option("$i", "$i")];
    sysBPItems = [for (int i = 80; i <= 200; i++) _Option("$i", "$i")];
    diaBPItems = [for (int i = 40; i <= 130; i++) _Option("$i", "$i")];
    sugarItems = [for (int i = 40; i <= 500; i += 10) _Option("$i", "$i")];
  }

  @override
  void dispose() {
    _countryMenu?.remove();
    _countryMenu = null;
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
          _country = country;
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Patient Details', style: TextStyle(color: Colorprimary, fontWeight: FontWeight.w900, fontSize: 32)),
                    const SizedBox(height: 18),
                    _buildSectionTitle("Patient Name *"),
                    _buildTextField(_nameController, "Enter full name"),
                    const SizedBox(height: 14),
                    _buildSectionTitle("Phone Number *"),
                    _buildPhoneField(),
                    const SizedBox(height: 14),
                    _buildSectionTitle("Age *"),
                    _buildAgeDropdown(),
                    const SizedBox(height: 14),
                    _buildSectionTitle("Gender"),
                    _buildGenderSelection(),
                    const SizedBox(height: 16),
                    _buildSectionTitle("Vitals (Optional)"),
                    const SizedBox(height: 8),
                    _buildVitalsGrid(),
                    const SizedBox(height: 14),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          key: _phoneFieldKey,
          height: 44,
          decoration: _fieldDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: _openCountryMenu,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_country.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '+${_country.dialCode}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1C2B33)),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_country.maxLength),
                  ],
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C2B33)),
                  decoration: InputDecoration(
                    hintText: 'xxxxxxx...',
                    hintStyle: _hintStyle(),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  onChanged: (_) => setState(_syncPhone),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 4),
          child: Text(
            '${_phoneController.text.length}/${_country.maxLength}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3A8)),
          ),
        ),
      ],
    );
  }

  void _syncPhone() {
    final digits = _phoneController.text;
    _completePhoneNumber = digits.isEmpty ? "" : "+${_country.fullCountryCode}$digits";
  }

  void _removeCountryMenu() {
    _countryMenu?.remove();
    _countryMenu = null;
  }

  void _openCountryMenu() {
    _removeCountryMenu();
    final fieldContext = _phoneFieldKey.currentContext;
    if (fieldContext == null) return;
    final box = fieldContext.findRenderObject() as RenderBox;
    final overlayBox = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    const menuHeight = 240.0;
    final spaceBelow = overlayBox.size.height - origin.dy - box.size.height - 12;
    final spaceAbove = origin.dy - 12;
    final openAbove = spaceBelow < 160 && spaceAbove > spaceBelow;
    final height = (openAbove ? spaceAbove : spaceBelow).clamp(140.0, menuHeight);
    final top = openAbove ? origin.dy - height - 4 : origin.dy + box.size.height + 4;

    _countryMenu = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeCountryMenu,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: origin.dx,
              top: top,
              width: box.size.width,
              height: height,
              child: _CountryMenu(
                selectedCode: _country.code,
                onSelected: (country) {
                  _removeCountryMenu();
                  if (!mounted) return;
                  setState(() {
                    _country = country;
                    _phoneController.clear();
                    _completePhoneNumber = "";
                  });
                },
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_countryMenu!);
  }

  Widget _buildVitalsGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVitalDropdown("Temp (°F)", selectedTemp, tempItems, (v) => setState(() => selectedTemp = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildVitalDropdown("Pulse (bpm)", selectedPulse, pulseItems, (v) => setState(() => selectedPulse = v))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVitalDropdown("Resp (bpm)", selectedRespiration, respItems, (v) => setState(() => selectedRespiration = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildBPField()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVitalDropdown("Sugar (mg/dL)", selectedSugar, sugarItems, (v) => setState(() => selectedSugar = v))),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalDropdown(String label, String? value, List<_Option> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _AnchoredSelect(
          value: value,
          hint: "-",
          options: items,
          onSelected: onChanged,
        ),
      ],
    );
  }

  Widget _buildAgeDropdown() {
    return _AnchoredSelect(
      value: _ageController.text.isEmpty ? null : _ageController.text,
      hint: "Select Age",
      options: ageItems,
      onSelected: (value) => setState(() => _ageController.text = value!),
    );
  }

  Widget _buildBPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BP (mmHg)", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
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

  Widget _miniBPBox(String? value, List<_Option> items, String hint, ValueChanged<String?> onChanged) {
    return _AnchoredSelect(
      value: value,
      hint: hint,
      options: items,
      onSelected: onChanged,
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Colorprimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        "Book For Later",
                        style: TextStyle(color: Colorprimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Functions ---

  void _onSaveContinue() async {
    if (_nameController.text.isNotEmpty && _ageController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      if (!await _entryGate() || !mounted) return;
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
        if (!mounted) return;
        if (allowed) {
          Navigator.pushNamed(
            context,
            RouteNames.audioRecorderScreen,
            arguments: navigationArgs,
          );
        } else if (utils.planBlocksConsultation) {
          Navigator.of(context).pop();
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
    if (!await _entryGate() || !mounted) return;
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

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: const TextStyle(color: Color(0xFF1C2B33), fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _buildTextField(TextEditingController controller, String hint) => Container(
        decoration: _fieldDecoration(),
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1C2B33)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _hintStyle(),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  Widget _buildGenderSelection() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ["Male", "Female", "Prefer not to disclose"].map((e) => _genderChip(e)).toList()));
  Widget _buildVisitTypeSelection() => Row(children: [_visitTypeChip("New"), const SizedBox(width: 20), _visitTypeChip("Follow up")]);

  Widget _buildPrimaryButton(String text, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colorprimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      );

  BoxDecoration _fieldDecoration() => BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E8EB)),
      );

  TextStyle _hintStyle() => const TextStyle(color: Color(0xFF9AA3A8), fontSize: 14);

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

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

class _AnchoredSelect extends StatelessWidget {
  final String? value;
  final String hint;
  final List<_Option> options;
  final ValueChanged<String?> onSelected;

  const _AnchoredSelect({
    required this.value,
    required this.hint,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.cast<_Option?>().firstWhere(
          (option) => option!.value == value,
          orElse: () => null,
        );
    final hasValue = selected != null;

    return Material(
      color: const Color(0xFFF5F6F7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _open(context),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E8EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? selected.label : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasValue ? const Color(0xFF1C2B33) : const Color(0xFF9AA3A8),
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      initialValue: value,
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE4E8EB)),
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: 220,
      ),
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.value,
            height: 40,
            child: Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: option.value == value ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1C2B33),
              ),
            ),
          ),
      ],
    );
    if (selected != null) onSelected(selected);
  }
}

class _CountryMenu extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<intl_data.Country> onSelected;

  const _CountryMenu({required this.selectedCode, required this.onSelected});

  @override
  State<_CountryMenu> createState() => _CountryMenuState();
}

class _CountryMenuState extends State<_CountryMenu> {
  final _search = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final countries = intl_data.countries.where((country) {
      if (query.isEmpty) return true;
      return country.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList();

    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E8EB)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: TextField(
                controller: _search,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C2B33)),
                cursorColor: Colorprimary,
                decoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA3A8)),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF7A8A90)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E8EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E8EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colorprimary),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final selected = country.code == widget.selectedCode;
                  return InkWell(
                    onTap: () => widget.onSelected(country),
                    child: Container(
                      color: selected ? const Color(0xFFF3F7F8) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(country.flag, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              country.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1C2B33)),
                            ),
                          ),
                          Text(
                            '+${country.dialCode}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF5C6B72)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}