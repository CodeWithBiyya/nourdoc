import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart' as intl_data;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/ui/profile/doctor_profile_viewmodel.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import '../../utils/utils.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController(
    text: HiveStorage.getName().toString() != "null" ? HiveStorage.getName().toString() : "",
  );
  final TextEditingController emailController = TextEditingController(
    text: HiveStorage.getEmail().toString() != "null" ? HiveStorage.getEmail().toString() : "",
  );
  final TextEditingController contactController = TextEditingController();
  final TextEditingController licenseController = TextEditingController(
    text: HiveStorage.getlicenseno().toString() != "null" ? HiveStorage.getlicenseno().toString() : "",
  );
  final TextEditingController specialityController = TextEditingController(
    text: HiveStorage.getspeciallisation().toString() != "null" ? HiveStorage.getspeciallisation().toString() : "",
  );

  bool _isEmailTxtDisable = false;
  String? selectedSpeciality;
  String? selectedExperience;
  String? selectedCountry;
  String? selectedCity;
  Map<String, List<String>> countryCityMap = {};
  List<String> specialities = [];

  String _completePhoneNumber = "";
  String _currentIsoCode = 'PK';
  Key _phoneWidgetRefreshKey = UniqueKey();

  bool isProfil = true;
  bool _isLoadingData = true;
  List<intl_data.Country> _filteredLibraryCountries = [];

  @override
  void initState() {
    super.initState();
    if (experiences.contains(HiveStorage.getexperience())) {
      selectedExperience = HiveStorage.getexperience();
    }
    if (HiveStorage.getEmail() != null && HiveStorage.getEmail() != "null") {
      _isEmailTxtDisable = true;
      emailController.text = HiveStorage.getEmail()!;
    }
    _completePhoneNumber = HiveStorage.getPhone() ?? "";

    Future.wait([loadCountryCityData(), loadSpecialitiesData()]).then((_) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _parseStoredPhone();
        });
      }
    });
  }

  void _parseStoredPhone() {
    if (_completePhoneNumber.isNotEmpty && _completePhoneNumber.startsWith("+")) {
      bool found = false;
      for (var country in _filteredLibraryCountries) {
        String prefix = "+${country.dialCode}";
        if (_completePhoneNumber.startsWith(prefix)) {
          _currentIsoCode = country.code;
          String national = _completePhoneNumber.replaceFirst(prefix, "").trim();
          contactController.text = national;
          _phoneWidgetRefreshKey = UniqueKey();
          found = true;
          break;
        }
      }
    }
  }

  Future<void> loadCountryCityData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/files/countries.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      countryCityMap = data.map((key, value) => MapEntry(key, List<String>.from(value)));
      _filteredLibraryCountries = intl_data.countries.where((libCountry) {
        return countryCityMap.keys.any((jsonName) =>
        jsonName.toLowerCase().trim() == libCountry.name.toLowerCase().trim());
      }).toList();

      if (_filteredLibraryCountries.any((c) => c.code == "PK")) {
        _currentIsoCode = "PK";
      } else if (_filteredLibraryCountries.isNotEmpty) {
        _currentIsoCode = _filteredLibraryCountries.first.code;
      }

      String savedLocation = HiveStorage.getcity().toString();
      if (savedLocation != "null" && savedLocation.contains(",")) {
        var parts = savedLocation.split(",");
        selectedCity = parts[0].trim();
        selectedCountry = parts[1].trim();
        try {
          var match = _filteredLibraryCountries.firstWhere((c) => c.name.toLowerCase().trim() == selectedCountry!.toLowerCase().trim());
          _currentIsoCode = match.code;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error loading countries: $e");
    }
  }

  void _updateIsoCodeFromName(String countryName) {
    try {
      var matches = _filteredLibraryCountries.where((c) => c.name.toLowerCase().trim() == countryName.toLowerCase().trim());
      setState(() {
        if (matches.isNotEmpty) {
          _currentIsoCode = matches.first.code;
        } else {
          _currentIsoCode = _filteredLibraryCountries.any((c) => c.code == "PK") ? "PK" : (_filteredLibraryCountries.isNotEmpty ? _filteredLibraryCountries.first.code : 'PK');
        }
        _phoneWidgetRefreshKey = UniqueKey();
      });
    } catch (e) {
      debugPrint("Country lookup failed: $e");
    }
  }

  Future<void> loadSpecialitiesData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/files/specialities.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      specialities = List<String>.from(data['specialties'])..sort();
      if (specialities.contains(HiveStorage.getspeciallisation())) {
        selectedSpeciality = HiveStorage.getspeciallisation();
        specialityController.text = selectedSpeciality ?? "";
      }
    } catch (e) {
      debugPrint("Error loading specialities: $e");
    }
  }

  final List<String> experiences = ["1", "2", "3", "4", "5+"];

  // --- DESIGN HELPERS MATCHING NEW ENCOUNTER SCREEN ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments as Map?;
    isProfil = args != null ? args['isProfile'] == "1" : false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colorprimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NourDoc",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfil ? "Doctor's Profile" : "Doctor Signup",
                  style: const TextStyle(
                    color: Colorprimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("NAME *"),
                buildTextField("Enter full name", nameController, false),
                const SizedBox(height: 15),

                _buildSectionTitle("EMAIL"),
                buildTextField(
                    "Enter email", emailController, _isEmailTxtDisable),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("COUNTRY *"),
                          buildCountryDropdown(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("CITY *"),
                          buildCityDropdown(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildSectionTitle("PHONE NUMBER *"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dialogTheme: const DialogThemeData(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                      ),
                    ),
                    child: IntlPhoneField(
                      key: _phoneWidgetRefreshKey,
                      controller: contactController,
                      initialCountryCode: _currentIsoCode,
                      countries: _filteredLibraryCountries,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      dropdownIconPosition: IconPosition.trailing,
                      flagsButtonPadding: const EdgeInsets.only(left: 15),
                      decoration: InputDecoration(
                        hintText: 'xxxxxxx...',
                        hintStyle: TextStyle(color: Colors.grey.shade400,
                            fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 10),
                        counterStyle: const TextStyle(fontSize: 10, height: 2),
                      ),
                      onCountryChanged: (country) {
                        setState(() {
                          _currentIsoCode = country.code;
                          final matches = countryCityMap.keys.where(
                                (name) =>
                            name.toLowerCase().trim() ==
                                country.name.toLowerCase().trim(),
                          );
                          if (matches.isNotEmpty)
                            selectedCountry = matches.first;
                          selectedCity = null;
                        });
                      },
                      onChanged: (phone) =>
                      _completePhoneNumber = phone.completeNumber,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                _buildSectionTitle("SPECIALITY *"),
                buildSpecialityDropdown(),
                const SizedBox(height: 15),

                _buildSectionTitle("EXPERIENCE *"),
                buildDropdown(
                  selectedExperience,
                  experiences,
                      (value) => setState(() => selectedExperience = value),
                ),
                const SizedBox(height: 15),

                if (selectedCountry == "Pakistan") ...[
                  _buildSectionTitle("PMDC LICENSE"),
                  buildTextField(
                      "Enter license number", licenseController, false),
                  const SizedBox(height: 15),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colorprimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            utils.toastMessage("Please enter valid information");
                            return;
                          }

                          // 🚩 FIX 1: Experience logic (Send only the value like "4" or "5+", don't add "years" manually)
                          String? expToSend = selectedExperience;

                          // 🚩 FIX 2: City logic (Send only city name as per working 2nd code)
                          String? cityToSend = selectedCity ?? "";

                          // Construct the Map
                          Map<String, dynamic> datamap = {
                            'name': nameController.text.trim(),
                            'ph_number': _completePhoneNumber,
                            'specialisation': selectedSpeciality,
                            'experience': expToSend,
                            'license_no': selectedCountry == "Pakistan" ? licenseController.text.trim() : null,
                            'city': cityToSend, // Only City
                          };

                          // Remove null/empty keys
                          datamap.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);

                          utils.toastMessage("Processing...");

                          try {
                            if (isProfil) {
                              // ================= UPDATE PROFILE LOGIC =================
                              String email = emailController.text.trim();

                              dynamic response = await DoctorProfileViewModel().updateDoctorProfile(email, datamap);

                              // 🚩 FIX 3: Response String Check (Checking both common success messages)
                              String resStr = response.toString();
                              if (response != null && (resStr.contains("Profile Updated") || resStr.contains("Update Successful"))) {

                                // Update Hive
                                await Future.wait([
                                  HiveStorage.setName(datamap['name'] ?? nameController.text.trim()),
                                  HiveStorage.setPhone(datamap['ph_number'] ?? _completePhoneNumber),
                                  HiveStorage.setCity(selectedCity ?? ""), // Store City
                                  HiveStorage.setExperience(selectedExperience ?? ""),
                                  HiveStorage.setspeciallisation(selectedSpeciality ?? ""),
                                  HiveStorage.setlicenseno(datamap['license_no'] ?? ""),
                                ]);

                                utils.toastMessage("Profile Updated Successfully");
                                if(mounted) Navigator.pop(context);
                              } else {
                                utils.toastMessage("Failed: $response");
                              }
                            } else {
                              // ================= REGISTER LOGIC =================
                              datamap['user'] = emailController.text.trim();
                              datamap['username'] = emailController.text.trim();

                              dynamic responses = await DoctorProfileViewModel().postRegisterUser(datamap);

                              // Check success
                              bool isSuccess = (responses != null) &&
                                  (responses["Registered"] == true || responses["registered"] == true || responses["message"].toString().contains("Success"));

                              if (isSuccess) {
                                if (responses["token"] != null) {
                                  await HiveStorage.setToken(responses["token"].toString());
                                }
                                await Future.wait([
                                  HiveStorage.setName(nameController.text.trim()),
                                  HiveStorage.setEmail(emailController.text.trim().toLowerCase()),
                                  HiveStorage.setPhone(_completePhoneNumber),
                                  HiveStorage.setCity(selectedCity ?? ""),
                                  HiveStorage.setExperience(selectedExperience ?? ""),
                                  HiveStorage.setspeciallisation(selectedSpeciality ?? ""),
                                  HiveStorage.setlicenseno(datamap['license_no'] ?? ""),
                                  HiveStorage.setProfileSatatus("c"),
                                ]);

                                utils.toastMessage("Registered successfully");
                                Navigator.pushNamedAndRemoveUntil(context, RouteNames.dashboard, (route) => false);
                              } else {
                                utils.toastMessage(responses != null ? (responses["message"] ?? "Failed") : "Error");
                              }
                            }
                          } catch (e) {
                            debugPrint("Error: $e");
                            utils.toastMessage("Something went wrong");
                          }
                        },
                        child: Text(isProfil ? "Update" : "Register",
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => clearAllFields(),
                        child: const Text("Clear", style: TextStyle(
                            color: Colors.black87)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void clearAllFields() {
    setState(() {
      nameController.clear();
      contactController.clear();
      licenseController.clear();
      selectedCountry = null;
      selectedCity = null;
      selectedSpeciality = null;
      selectedExperience = null;
      _completePhoneNumber = "";
      _phoneWidgetRefreshKey = UniqueKey();
    });
  }

  Widget buildCountryDropdown() => buildSearchableSelector(
    title: "Select Country",
    value: selectedCountry,
    items: countryCityMap.keys.toList()..sort(),
    onSelected: (val) {
      setState(() {
        selectedCountry = val;
        selectedCity = null;
        if (selectedCountry != "Pakistan") licenseController.clear();
      });
      _updateIsoCodeFromName(val);
    },
  );

  Widget buildCityDropdown() {
    List<String> cities = (selectedCountry != null && countryCityMap.containsKey(selectedCountry)) ? countryCityMap[selectedCountry]! : [];
    return buildSearchableSelector(
      title: "Select City",
      value: selectedCity,
      items: cities..sort(),
      enabled: selectedCountry != null,
      onSelected: (val) => setState(() => selectedCity = val),
    );
  }

  Widget buildSearchableSelector({required String title, required String? value, required List<String> items, required Function(String) onSelected, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GestureDetector(
        onTap: !enabled ? null : () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (context) {
              String filter = '';
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  title: Text(title),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(hintText: "Search...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                          onChanged: (value) => setState(() => filter = value),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            children: items.where((i) => i.toLowerCase().contains(filter.toLowerCase())).map((i) => ListTile(
                              title: Text(i),
                              onTap: () => Navigator.pop(context, i),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          );
          if (selected != null) onSelected(selected);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                      value ?? "Select...",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: value == null ? Colors.grey.shade400 : Colors.black,
                          fontSize: 14
                      )
                  )
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSpecialityDropdown() {
    return buildSearchableSelector(
      title: "Select Speciality",
      value: selectedSpeciality,
      items: specialities,
      onSelected: (val) {
        setState(() {
          selectedSpeciality = val;
          specialityController.text = val;
        });
      },
    );
  }

  Widget buildTextField(String hint, TextEditingController controller, bool isDisable) {
    return Container(
      decoration: BoxDecoration(
        color: isDisable ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        enabled: !isDisable,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget buildDropdown(String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text("Select...", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        ),
      ),
    );
  }
}
