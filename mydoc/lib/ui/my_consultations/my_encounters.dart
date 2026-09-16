import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:medicalai/data/response/status.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/ui/my_consultations/my_encounters_viewmodel.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/noInternet.dart';
import '../wedgits/BottomLoginWidget.dart';
import '../wedgits/appbar_actions_wiget.dart';
import '../wedgits/doctorinfo_dialogbox.dart';
import '../Subscription_screens/Subscription_screen_1.dart';


// Optimized: Static formatter to avoid recreation
final DateFormat _sharedDateFormat = DateFormat("dd-MMM-yyyy");

class MyEncountersScreen extends StatefulWidget {
  const MyEncountersScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyEncountersScreen();
  }
}

class _MyEncountersScreen extends State<MyEncountersScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late MyEncounterViewModel myEncounterViewModel;
  final TextEditingController _searchController = TextEditingController();

  final bool _isDeleteMode = false;
  String searchQuery = "";
  String selectedFilter = "all";
  DateTime? customDate;
  DateTime? selectedMonthDate;

  String? selectedGender;
  String? selectedAgeGroup;
  bool _argsApplied = false;

  @override
  void initState() {
    super.initState();
    myEncounterViewModel = MyEncounterViewModel();
    WidgetsBinding.instance.addObserver(this);
    myEncounterViewModel.getEncounters();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    myEncounterViewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshScreen();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsApplied) {
      final maybeArgs = ModalRoute.of(context)?.settings.arguments;
      if (maybeArgs != null && maybeArgs is Map<String, dynamic>) {
        setState(() {
          if (maybeArgs["filter"] != null) {
            selectedFilter = maybeArgs["filter"].toString().toLowerCase();
          }
          if (maybeArgs["customDate"] != null) {
            customDate = maybeArgs["customDate"];
          }
          if (maybeArgs["monthDate"] != null) {
            selectedMonthDate = maybeArgs["monthDate"];
          }
          if (maybeArgs.containsKey("gender")) {
            selectedGender = maybeArgs["gender"];
          }
          if (maybeArgs.containsKey("ageGroup")) {
            selectedAgeGroup = maybeArgs["ageGroup"];
          }
        });
      }
      _argsApplied = true;
    }
  }

  void _refreshScreen() {
    myEncounterViewModel.getEncounters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, RouteNames.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "NourDoc",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colorprimary),
          actions: [
            PopupMenuButton<String>(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              icon: Image.asset(
                "assets/icons/Doc.png",
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'profile') {
                  showDialog(
                    context: context,
                    builder: (_) => DoctorInfoDialog(
                      imagePath: "assets/icons/Doc.png",
                      onEdit: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, RouteNames.doctor_profile_screen, arguments: {"isProfile": "1"});
                      },
                      onLogout: () {
                        HiveStorage.clearHives();
                        Navigator.pushNamedAndRemoveUntil(context, RouteNames.splash, (route) => false);
                      },
                    ),
                  );
                } else if (value == 'logout') {
                  HiveStorage.clearHives();
                  Navigator.pushNamedAndRemoveUntil(context, RouteNames.splash, (route) => false);
                } else if (value == 'subscription') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen1()),
                  );
                }
                else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InfoDetailScreen(type: value)),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text("My Profile")),
                //const PopupMenuItem(value: 'subscription', child: Text("Upgrade/Downgrade")),
                const PopupMenuItem(value: 'about', child: Text("About NourDoc")),
                const PopupMenuItem(value: 'legal', child: Text("Medico-Legal")),
                const PopupMenuItem(value: 'privacy', child: Text("Privacy Policy")),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text("Logout", style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _refreshScreen(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChangeNotifierProvider.value(
              value: myEncounterViewModel,
              child: Consumer<MyEncounterViewModel>(
                builder: (context, value, child) {
                  switch (value.apiEncounterList.status) {
                    case null:
                      return const SafeArea(child: Center(child: Text("Nothing Received")));
                    case Status.LOADING:
                      return const SafeArea(child: Center(child: CircularProgressIndicator(color: Colorprimary)));
                    case Status.COMPLETE:
                      if (value.apiEncounterList.data?.customStatus == 404) {
                        return _buildNoConsultationsEmptyState();
                      } else {
                        final allData = value.apiEncounterList.data?.data ?? [];

                        // Optimized: Sorting logic
                        allData.sort((a, b) {
                          try {
                            DateTime dateA = _sharedDateFormat.parse(a.date!);
                            DateTime dateB = _sharedDateFormat.parse(b.date!);
                            int dateCompare = dateB.compareTo(dateA);
                            if (dateCompare != 0) return dateCompare;
                          } catch (e) {}
                          return b.sessionId.compareTo(a.sessionId);
                        });

                        // Optimized: Fetch Hive items ONCE outside the loop
                        final localPendingItems = HiveStorage.getAllPending();

                        final displayList = allData.where((item) {
                          // Search check
                          if (searchQuery.isNotEmpty && !item.patientName.toLowerCase().contains(searchQuery)) return false;

                          // Date check
                          if (!filterByDate(item.date)) return false;

                          String apiStatus = (item.status ?? "").toString().toUpperCase();

                          // Check against Hive (optimized lookup)
                          bool isStillInOutbox = localPendingItems.any((pending) => pending.patientName == item.patientName);

                          bool isFullyUploaded = apiStatus == "FINISHED" || apiStatus == "PROCESSING";
                          if (!isFullyUploaded) return false;
                          if (apiStatus == "PROCESSING" && isStillInOutbox) return false;

                          // Gender check
                          if (selectedGender != null) {
                            if (!(item.gender ?? "").toLowerCase().startsWith(selectedGender!.toLowerCase().substring(0, 1))) return false;
                          }

                          // Age check
                          if (selectedAgeGroup != null) {
                            if (!checkAge(item.age, selectedAgeGroup!)) return false;
                          }

                          return true;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Consultation Records', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colorprimary)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              children: [
                                if (selectedFilter != "all")
                                  _buildFilterChip(
                                      (selectedFilter == "month" && selectedMonthDate != null) ? DateFormat('MMMM yyyy').format(selectedMonthDate!) : selectedFilter.toUpperCase(),
                                          () => setState(() { selectedFilter = "all"; selectedMonthDate = null; })),
                                if (selectedGender != null) _buildFilterChip("Gender: $selectedGender", () => setState(() => selectedGender = null)),
                                if (selectedAgeGroup != null) _buildFilterChip("Age: ${selectedAgeGroup == '<1' ? '0-1' : selectedAgeGroup}", () => setState(() => selectedAgeGroup = null)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: displayList.isEmpty ? 3 : displayList.length + 2,
                                padding: const EdgeInsets.only(bottom: 80),
                                itemBuilder: (context, index) {
                                  if (index == 0) return _buildSearchBar();
                                  if (index == 1) return _buildIconLegends();

                                  if (displayList.isEmpty) {
                                    return _buildNoConsultationsEmptyState();
                                  } else {
                                    var item = displayList[index - 2];
                                    String apiStatus = (item.status ?? "PROCESSING").toString().toUpperCase();

                                    Widget statusWidget;
                                    if (apiStatus == 'FINISHED') {
                                      statusWidget = const Icon(Icons.check_circle, color: Colorprimary, size: 24);
                                    } else if (apiStatus == 'PROCESSING' || apiStatus == 'STARTING') {
                                      statusWidget = Image.asset(
                                        "assets/icons/processing.png",
                                        width: 24, // You can adjust size
                                        height: 24,
                                        fit: BoxFit.contain,
                                      );
                                    } else {
                                      statusWidget = const Icon(Icons.info_outline_rounded, color: Colors.red, size: 22);
                                    }

                                    return _buildEncounterItem(
                                      context,
                                      index - 1,
                                      item.patientName,
                                      statusWidget,
                                      item.sessionId.toString(),
                                      item.age ?? "N/A",
                                      item.gender ?? "N/A",
                                      item.visitType ?? "New",
                                      apiStatus,
                                      item.vitals,
                                      item.date ?? "N/A",
                                      value,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    case Status.ERROR:
                      return _buildErrorLogic(value);
                  }
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colorprimary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onPressed: () async {
            await Navigator.pushNamed(context, RouteNames.consultationSelection);
            _refreshScreen();
          },
          child: const Icon(Icons.add, size: 24, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "Search by patient name...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setState(() { _searchController.clear(); searchQuery = ""; })) : null,
                  isDense: true,
                ),
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              ),
            ),
            InkWell(onTap: () => showFilterMenu(context), child: Icon(Icons.filter_alt_outlined, size: 28, color: selectedFilter != "all" ? Colorprimary : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterItem(
      BuildContext context,
      int number,
      String title,
      Widget statusWidget,
      String Id,
      String age,
      String gender,
      String vistType,
      String status,
      Map<String, dynamic>? vitals,
      String date,
      MyEncounterViewModel viewModel) {
    String firstName = title.trim().split(' ').first;
    String ageLabel = (age == "0-1" || age == "0") ? "0-1" : age;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
      child: Slidable(
        key: Key(Id),
        enabled: _isDeleteMode,
        child: GestureDetector(
          onTap: () {
            if (!_isDeleteMode) {
              if (status != "FINISHED" && status != "FAILED") {
                showDialog(context: context, builder: (context) => const ProcessingPopup());
              } else {
                Navigator.pushNamed(context, RouteNames.ClinicalFindingsScreen, arguments: {
                  'id': Id,
                  'status': status,
                }).then((val) => _refreshScreen());
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(color: _isDeleteMode ? const Color(0xFF255563) : const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("$number.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isDeleteMode ? Colors.white70 : Colorprimary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(firstName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _isDeleteMode ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 12, color: _isDeleteMode ? Colors.white70 : Colors.grey.shade600),
                          children: [
                            TextSpan(text: "$date • "),
                            WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                    gender.toLowerCase().startsWith('m') ? Icons.male : Icons.female,
                                    size: 14,
                                    color: _isDeleteMode ? Colors.white70 : Colorprimary
                                )
                            ),
                            TextSpan(text: " ${gender.isEmpty ? 'N/A' : gender} • Age: $ageLabel Y"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (vitals != null && vitals.isNotEmpty)
                        Wrap(runSpacing: 4, children: vitals.entries.map((entry) => _buildMiniVitalIcon(entry.key, entry.value.toString())).toList()),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                statusWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconLegends() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 25,
          children: [
            _LegendItem(Icon(Icons.check_circle, color: Colorprimary, size: 22), "Finished"),
            _LegendItem(Image.asset("assets/icons/processing.png", width: 20, height: 20),"Processing"),
            _LegendItem(Icon(Icons.info_outline_rounded, color: Colorprimary, size: 22), "Delayed"),
          ],
        ),
      ),
    );
  }

  bool checkAge(String? ageString, String range) {
    if (ageString == null || ageString.isEmpty) return false;
    if (range == "<1") return ageString == "0-1";
    int age = (ageString == "0-1") ? 0 : (int.tryParse(ageString) ?? 0);
    if (range == "1-5") return age >= 1 && age <= 5;
    if (range == "6-18") return age >= 6 && age <= 18;
    if (range == "19-35") return age > 18 && age <= 35;
    if (range == "36-60") return age > 35 && age <= 60;
    if (range == "60+") return age > 60;
    return false;
  }

  bool filterByDate(String? dateString) {
    if (selectedFilter == "all" || dateString == null) return true;
    try {
      DateTime date = _sharedDateFormat.parse(dateString);
      DateTime now = DateTime.now();
      DateTime itemDate = DateTime(date.year, date.month, date.day);
      DateTime today = DateTime(now.year, now.month, now.day);
      if (selectedFilter == "today") return itemDate.isAtSameMomentAs(today);
      if (selectedFilter == "week") return itemDate.isAfter(today.subtract(const Duration(days: 7)));
      if (selectedFilter == "month") {
        if (selectedMonthDate != null) return itemDate.month == selectedMonthDate!.month && itemDate.year == selectedMonthDate!.year;
        return itemDate.month == now.month && itemDate.year == now.year;
      }
      if (selectedFilter == "custom" && customDate != null) return itemDate.isAtSameMomentAs(DateTime(customDate!.year, customDate!.month, customDate!.day));
    } catch (_) { return true; }
    return true;
  }

  void showFilterMenu(BuildContext context) async {
    final result = await showMenu(context: context, color: Colors.white, position: const RelativeRect.fromLTRB(100, 150, 10, 0), items: [
      const PopupMenuItem(value: "all", child: Text("All Records")),
      const PopupMenuItem(value: "today", child: Text("Today")),
      const PopupMenuItem(value: "week", child: Text("This Week")),
      const PopupMenuItem(value: "month", child: Text("This Month")),
      const PopupMenuItem(value: "custom", child: Text("Select Date")),
    ]);
    if (result == null) return;
    if (result == "custom") { pickCustomDate(); return; }
    setState(() {
      selectedFilter = result.toString().toLowerCase();
      selectedMonthDate = (selectedFilter == "month") ? DateTime.now() : null;
    });
  }

  Future<void> pickCustomDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (ctx, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colorprimary)), child: child!));
    if (picked != null) setState(() { selectedFilter = "custom"; customDate = picked; });
  }

  Widget _buildMiniVitalIcon(String key, String value) {
    if (value.toUpperCase() == "N/A" || value.isEmpty || value == "null") return const SizedBox.shrink();
    IconData icon; String unit = ""; String k = key.toLowerCase().trim();
    if (k == "temperature") { icon = Icons.thermostat; unit = "°F"; }
    else if (k == "pulse") { icon = Icons.favorite; unit = " bpm"; }
    else if (k == "blood pressure") { icon = Icons.speed; unit = " mmHg"; }
    else if (k == "sugar") { icon = Icons.monitor_weight_outlined; unit = " mg"; }
    else if (k == "respiration") { icon = Icons.air; unit = " bpm"; }
    else icon = Icons.monitor_weight_outlined;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colorprimary), Text("$value$unit", style: const TextStyle(fontSize: 10)), const SizedBox(width: 4)]);
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) => Chip(label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: Colorprimary, deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white), onDeleted: onDelete, padding: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildNoConsultationsEmptyState() => Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset("assets/icons/emptyConsul.png", height: 250, fit: BoxFit.contain), const SizedBox(height: 20), const Text("No Recent Consultations", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 25), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), elevation: 0), onPressed: () => Navigator.pushNamed(context, RouteNames.consultationSelection), child: const Text("New Consultation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))])));

  Widget _buildErrorLogic(MyEncounterViewModel value) {
    final errorMessage = value.apiEncounterList.message ?? "";
    int statusCode = utils.getStatusCodeFromMessage(errorMessage);

    if (statusCode == 401) {
      HiveStorage.clearHives();
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.popAndPushNamed(context, RouteNames.splash));
      return const SizedBox();
    }

    if (statusCode == 400 || statusCode == 404 || errorMessage.toLowerCase().contains("not found")) {
      return _buildNoConsultationsEmptyState();
    }

    return FutureBuilder<bool>(
      future: hasInternet(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return _buildErrorState(
            image: "assets/icons/internet.png",
            title: "You're offline",
            subtitle: "Please check your internet connection.",
            onRefresh: _refreshScreen,
          );
        }
        return _buildErrorState(
          image: "assets/icons/server.png",
          title: "Service Upgradation",
          subtitle: "NourDoc is undergoing a live service upgrade.",
          onRefresh: _refreshScreen,
        );
      },
    );
  }

  Widget _buildErrorState({required String image, required String title, required String subtitle, required VoidCallback onRefresh}) => Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset(image, height: 220, fit: BoxFit.contain), const SizedBox(height: 30), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0), onPressed: onRefresh, child: const Text("Refresh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))])));

  @override
  bool get wantKeepAlive => true;
}

// Optimized Legend Item as a Stateless class
class _LegendItem extends StatelessWidget {
  final Widget icon;
  final String label;
  const _LegendItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500))]);
  }
}

class ProcessingPopup extends StatelessWidget {
  const ProcessingPopup({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      titlePadding: const EdgeInsets.only(top: 25, left: 20, right: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      actionsPadding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
      title: const Column(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 55, width: 55, child: CupertinoActivityIndicator(radius: 18)), SizedBox(height: 15), Text("Report in Progress", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colorprimary))]),
      content: const Text("Your recorded session is being processed. Please wait while the medical report is generated.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF424242), height: 1.4)),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colorprimary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, RouteNames.consultationSelection); }, child: const Text("New Consultation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))))],
    );
  }
}

class InfoDetailScreen extends StatelessWidget {
  final String type;
  const InfoDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    String title = "";
    if (type == 'about') title = "About NourDoc";
    else if (type == 'legal') title = "Medico-Legal Disclaimer";
    else if (type == 'privacy') title = "Data Privacy & Consent";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    const TextStyle normalStyle = TextStyle(fontSize: 12, height: 1.6, color: Colors.black87);
    const TextStyle boldStyle = TextStyle(fontSize: 12, height: 1.6, fontWeight: FontWeight.bold, color: Colors.black);
    const TextStyle linkStyle = TextStyle(fontSize: 12, height: 1.6, color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold);

    if (type == 'about') {
      return RichText(
        text: TextSpan(
          style: normalStyle,
          children: [
            const TextSpan(text: "NourDoc", style: boldStyle),
            const TextSpan(text: " is an AI-powered medical documentation application designed to support physicians in accurately capturing and structuring clinical encounters. It securely records and transcribes real-time doctor–patient conversations and automatically generates standardized "),
            const TextSpan(text: "SOAP notes", style: boldStyle),
            const TextSpan(text: ", reducing manual documentation effort and administrative burden.\n\n"),
            const TextSpan(text: "Developed and maintained by "),
            const TextSpan(text: "M3 Hive", style: boldStyle),
            const TextSpan(text: " ("),
            TextSpan(
              text: "m3hive.com",
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () => _handleURL(context, "https://m3hive.com"),
            ),
            const TextSpan(text: "), a specialized Software and Artificial Intelligence company, NourDoc enables faster, more precise, and professionally compliant clinical documentation.\n\n"),
            const TextSpan(text: "For additional information or clarification, please contact "),
            TextSpan(
              text: "NourDoc@m3hive.com",
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () => _handleURL(context, "mailto:NourDoc@m3hive.com"),
            ),
          ],
        ),
      );
    }

    if (type == 'legal') {
      return RichText(
        text: TextSpan(
          style: normalStyle,
          children: [
            const TextSpan(text: "Medico-Legal Disclaimer (NourDoc):\n\n", style: boldStyle),
            const TextSpan(text: "The clinical summaries are generated by "),
            const TextSpan(text: "NourDoc", style: boldStyle),
            const TextSpan(text: " (AI-assisted medical documentation application), using recorded doctor–patient interactions captured within the app. The content is intended strictly for clinical documentation and reference purposes. It does not replace, override, or influence the treating physician’s independent clinical judgment, diagnosis, or treatment decisions.\n\n"),
            const TextSpan(
              text: "Full responsibility for reviewing, validating, interpreting, and applying the information remains with the attending physician. ",
            ),
            const TextSpan(
                text: "NourDoc and M3 Hive assume no responsibility or liability for any clinical decisions or outcomes arising from the use of this AI-generated summary.",
                style: boldStyle
            ),
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: normalStyle,
        children: [
          const TextSpan(text: "Data Privacy & Patient Consent (NourDoc):\n\n", style: boldStyle),
          const TextSpan(text: "All doctor–patient conversations are recorded within the "),
          const TextSpan(text: "NourDoc", style: boldStyle),
          const TextSpan(text: " application strictly after obtaining the "),
          const TextSpan(text: "patient’s informed consent. ", style: boldStyle),
          const TextSpan(text: "NourDoc enforces rigorous data privacy policies and security protocols to safeguard patient information.\n\n"),
          const TextSpan(text: "All recordings and AI-generated clinical documentation are processed, stored, and accessed in "),
          const TextSpan(text: "compliance with applicable data protection and patient confidentiality standards", style: boldStyle),
          const TextSpan(text: ", and are available only to authorized clinical users through the NourDoc platform."),
        ],
      ),
    );
  }

  Future<void> _handleURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch";
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url.replaceAll("mailto:", "")));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link copied to clipboard.")),
        );
      }
    }
  }
}