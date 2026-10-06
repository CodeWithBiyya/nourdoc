import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // Add this
import 'package:http/http.dart' as http; // Add this



import '../../data/response/status.dart';
import '../../model/EncounterListModel.dart';
import '../../ui/my_consultations/my_encounters_viewmodel.dart';
import '../../utils/appDialog.dart';
import '../../utils/colors.dart';
import '../../routes/routs_name.dart';
import '../../utils/hive_storage.dart';
import '../../utils/noInternet.dart';
import '../../utils/utils.dart';
import '../my_consultations/my_encounters.dart';
import '../widgets/BottomLoginWidget.dart';
import '../widgets/doctorinfo_dialogbox.dart';
import '../../services/app_url.dart';
import '../../ui/Subscription_screens/Subscription_screen_1.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MyEncounterViewModel myEncounterViewModel = MyEncounterViewModel();

  String selectedTimeFilter = "Month";
  DateTime? customStartDate;
  DateTime monthViewDate = DateTime.now();
  int weekOffset = 0;

  List<DateTime> _generateMonthList() {
    List<DateTime> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    return months;
  }

  @override
  void initState() {
    super.initState();
    myEncounterViewModel.getEncounters();
    _resetToCurrentWeek();
  }

  void _resetToCurrentWeek() {
    setState(() {
      weekOffset = 0;
    });
  }

  void _refreshDashboard() {
    myEncounterViewModel.getEncounters();
  }

  // ─── Shared dashboard layout builder ────────────────────────────────────────
  Widget _buildDashboard({
    required bool isAccountEmpty,
    required List<EncounterData> filteredData,
    required int barCount,
    required DateTime currentWeekStart,
    required DateTime currentWeekEnd,
    required Map<String, int> dailyCounts,
    required Map<String, int> processingStatusCounts,
    required Map<String, int> visitTypeCounts,
    required bool canGoPrevious,
    required bool canGoNext,
    required int maleCount,
    required int femaleCount,
    required int otherGenderCount,
    required int ageUnder1,
    required int age1_5,
    required int age6_18,
    required int age19_35,
    required int age36_60,
    required int age60plus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 STATIC HEADER
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 10.0, top: 10),
          child: Text(
            "Clinical Insights Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colorprimary,
            ),
          ),
        ),

        // 🔹 SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Today", "Week", "Month", "Custom"]
                        .map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _filterButton(e),
                      ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildContextHeader(),
                const SizedBox(height: 8),
                _collapsibleCard(
                  title: "Your Patients Consultations",
                  child: Column(
                    children: [
                      if (selectedTimeFilter == "Month" && !isAccountEmpty)
                        _buildWeekNavigator(
                          canGoPrevious,
                          canGoNext,
                          currentWeekStart,
                          currentWeekEnd,
                        ),
                      SizedBox(
                        height: 220,
                        child: isAccountEmpty
                            ? const Center(
                          child: Text(
                            "No consultations made yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : filteredData.isEmpty
                            ? const Center(
                          child: Text(
                            "No data for this period",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : _buildBarChart(
                          barCount,
                          currentWeekStart,
                          dailyCounts,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _collapsibleCard(
                  title: "Reports Status",
                  child: isAccountEmpty || filteredData.isEmpty
                      ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        "No data available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                      : _buildStatusPie(processingStatusCounts),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoCard(
                        title: "Gender",
                        content: Column(
                          children: [
                            _linkRow("Male", maleCount, "gender", "Male"),
                            const SizedBox(height: 8),
                            _linkRow(
                              "Female",
                              femaleCount,
                              "gender",
                              "Female",
                            ),
                            const SizedBox(height: 8),
                            _linkRow(
                              "Other",
                              otherGenderCount,
                              "gender",
                              "Prefer not to disclose",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        title: "Age Groups",
                        content: Column(
                          children: [
                            _linkRow("< 1 Year", ageUnder1, "ageGroup", "<1"),
                            const SizedBox(height: 6),
                            _linkRow("1–5 Years", age1_5, "ageGroup", "1-5"),
                            const SizedBox(height: 6),
                            _linkRow("6-18", age6_18, "ageGroup", "6-18"),
                            const SizedBox(height: 6),
                            _linkRow("19–35", age19_35, "ageGroup", "19-35"),
                            const SizedBox(height: 6),
                            _linkRow("36–60", age36_60, "ageGroup", "36-60"),
                            const SizedBox(height: 6),
                            _linkRow("60+", age60plus, "ageGroup", "60+"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldExit =
            await showAppDialog<bool>(
              context: context,
              icon: "assets/icons/exit_1.png",
              title: "Exit Session",
              content:
              "Are you sure you want to exit?\nYour completed encounters are saved, and reports will be delivered in the app and by email.",
              secondaryText: "Cancel",
              primaryText: "Exit",
              onPrimary: () => SystemNavigator.pop(),
            ) ??
                false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "NourDoc",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: Image.asset(
              "assets/icons/exit.png",
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            onSelected: (value) async {
              if (value == 'profile') {
                // 1. Check karein ke email Hive mein maujood hai ya nahi
                String? email = HiveStorage.getEmail();

                if (email == null || email == "null" || email.trim().isEmpty) {
                  print("Error: Email is null in Hive. Cannot fetch profile.");
                  return;
                }

                // 2. Loader dikhayein
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colorprimary)),
                );

                try {

                  String encodedEmail = Uri.encodeComponent(email.trim());
                  String finalUrl = "${AppUrls.get_doctor_profile}$encodedEmail";

                  print("Requesting Profile from: $finalUrl");

                  final response = await http.get(Uri.parse(finalUrl));

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    print("Profile Data Received: $data");

                    // Data save karein
                    await HiveStorage.setName(data['doctor_name'] ?? "N/A");
                    await HiveStorage.setspeciallisation(data['doctor_specialisation'] ?? "N/A");
                    await HiveStorage.setPhone(data['phone_number'] ?? "N/A");

                    String exp = (data['experience'] ?? "0").toString().replaceAll(" years", "").trim();
                    await HiveStorage.setExperience(exp);

                    await HiveStorage.setlicenseno(data['license_no'] ?? "N/A");
                    await HiveStorage.setCity(data['city'] ?? "N/A");
                  } else {
                    print("API Error: ${response.statusCode} - ${response.body}");
                  }
                } catch (e) {
                  print("Exception: $e");
                }

                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
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
                }
              } else if (value == 'logout') {
                  HiveStorage.clearHives();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.splash, (route) => false, // This removes all previous screens
                  );
                }
              else if (value == 'subscription') {
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
                const PopupMenuItem(
                  value: 'profile',
                  child: Text("My Profile"),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: Text("About NourDoc"),
                ),
                const PopupMenuItem(
                  value: 'subscription',
                  child: Text("Upgrade/Downgrade"),
                ),
                const PopupMenuItem(
                  value: 'legal',
                  child: Text("Medico-Legal"),
                ),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Text("Privacy Policy"),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text("Logout", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        body: ChangeNotifierProvider<MyEncounterViewModel>(
          create: (BuildContext context) => myEncounterViewModel,
          child: Consumer<MyEncounterViewModel>(
            builder: (context, value, child) {
              switch (value.apiEncounterList.status) {
                case Status.LOADING:
                  return const Center(
                    child: CircularProgressIndicator(color: Colorprimary),
                  );

              // ─── ERROR: only logout on 401, else show empty dashboard ───
                case Status.ERROR:
                  final errorMessage = value.apiEncounterList.message ?? "";

                  if (utils.getStatusCodeFromMessage(errorMessage) == 401) {
                    HiveStorage.clearHives();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.splash, (route) => false, // This removes all previous screens
                      );
                    });
                    return const SizedBox();
                  }

                  // Build empty-state variables so dashboard renders normally
                  final DateTime monthStart = DateTime(
                    monthViewDate.year,
                    monthViewDate.month,
                    1,
                  );
                  final DateTime todayActual = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  final DateTime monthEnd = todayActual;

                  DateTime currentWeekEnd = monthEnd.subtract(
                    Duration(days: 7 * weekOffset),
                  );
                  DateTime currentWeekStart = currentWeekEnd.subtract(
                    const Duration(days: 6),
                  );
                  if (currentWeekStart.isBefore(monthStart)) {
                    currentWeekStart = monthStart;
                  }
                  final int barCount =
                      currentWeekEnd.difference(currentWeekStart).inDays + 1;

                  Map<String, int> dailyCounts = {};
                  for (int i = 0; i < barCount; i++) {
                    final day = currentWeekStart.add(Duration(days: i));
                    dailyCounts[DateFormat('yyyy-MM-dd').format(day)] = 0;
                  }

                  return _buildDashboard(
                    isAccountEmpty: true,
                    filteredData: [],
                    barCount: barCount,
                    currentWeekStart: currentWeekStart,
                    currentWeekEnd: currentWeekEnd,
                    dailyCounts: dailyCounts,
                    processingStatusCounts: {
                      "Completed": 0,
                      "Under Process": 0,
                      "Delayed": 0,
                    },
                    visitTypeCounts: {"New": 0, "Follow Up": 0},
                    canGoPrevious: false,
                    canGoNext: false,
                    maleCount: 0,
                    femaleCount: 0,
                    otherGenderCount: 0,
                    ageUnder1: 0,
                    age1_5: 0,
                    age6_18: 0,
                    age19_35: 0,
                    age36_60: 0,
                    age60plus: 0,
                  );

              // ─── COMPLETE ────────────────────────────────────────────────
                case Status.COMPLETE:
                  try {
                    final encounterResponse = value.apiEncounterList.data;
                    final List<EncounterData> allData =
                        encounterResponse?.data ?? [];
                    bool isAccountEmpty = allData.isEmpty;

                    final DateTime monthStart = DateTime(
                      monthViewDate.year,
                      monthViewDate.month,
                      1,
                    );
                    DateTime monthEnd;
                    DateTime todayActual = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );

                    if (monthViewDate.year == todayActual.year &&
                        monthViewDate.month == todayActual.month) {
                      monthEnd = todayActual;
                    } else {
                      monthEnd = DateTime(
                        monthViewDate.year,
                        monthViewDate.month + 1,
                        0,
                      );
                    }

                    DateTime currentWeekEnd = monthEnd.subtract(
                      Duration(days: 7 * weekOffset),
                    );
                    DateTime currentWeekStart = currentWeekEnd.subtract(
                      const Duration(days: 6),
                    );
                    if (currentWeekStart.isBefore(monthStart)) {
                      currentWeekStart = monthStart;
                    }
                    int barCount =
                        currentWeekEnd.difference(currentWeekStart).inDays + 1;

                    final bool canGoPrevious = currentWeekStart.isAfter(
                      monthStart,
                    );
                    final bool canGoNext = weekOffset > 0;

                    List<EncounterData> filteredData = [];
                    Map<String, int> visitTypeCounts = {
                      "New": 0,
                      "Follow Up": 0,
                    };
                    Map<String, int> processingStatusCounts = {
                      "Completed": 0,
                      "Under Process": 0,
                      "Delayed": 0,
                    };
                    Map<String, int> dailyCounts = {};

                    for (int i = 0; i < barCount; i++) {
                      final day = currentWeekStart.add(Duration(days: i));
                      dailyCounts[DateFormat('yyyy-MM-dd').format(day)] = 0;
                    }

                    for (var item in allData) {
                      if (item.date == null) continue;
                      DateTime itemDate;
                      try {
                        itemDate = DateFormat("dd-MMM-yyyy").parse(item.date!);
                      } catch (e) {
                        continue;
                      }
                      DateTime itemDateOnly = DateTime(
                        itemDate.year,
                        itemDate.month,
                        itemDate.day,
                      );

                      bool keep = false;
                      if (selectedTimeFilter == "Today")
                        keep = itemDateOnly.isAtSameMomentAs(todayActual);
                      else if (selectedTimeFilter == "Week")
                        keep = itemDateOnly.isAfter(
                          todayActual.subtract(const Duration(days: 7)),
                        );
                      else if (selectedTimeFilter == "Month")
                        keep = (itemDateOnly.month == monthViewDate.month &&
                            itemDateOnly.year == monthViewDate.year);
                      else if (selectedTimeFilter == "Custom" &&
                          customStartDate != null)
                        keep =
                            itemDateOnly.isAtSameMomentAs(customStartDate!);
                      else
                        keep = true;

                      if (keep) {
                        filteredData.add(item);
                        if ((item.visitType ?? "").toLowerCase().contains(
                          "new",
                        ))
                          visitTypeCounts["New"] = visitTypeCounts["New"]! + 1;
                        else
                          visitTypeCounts["Follow Up"] =
                              visitTypeCounts["Follow Up"]! + 1;

                        String status = (item.status).toLowerCase();
                        if (status.contains("finished"))
                          processingStatusCounts["Completed"] =
                              processingStatusCounts["Completed"]! + 1;
                        else if (status.contains("failed"))
                          processingStatusCounts["Delayed"] =
                              processingStatusCounts["Delayed"]! + 1;
                        else
                          processingStatusCounts["Under Process"] =
                              processingStatusCounts["Under Process"]! + 1;

                        final itemKey =
                        DateFormat('yyyy-MM-dd').format(itemDateOnly);
                        if (dailyCounts.containsKey(itemKey))
                          dailyCounts[itemKey] = dailyCounts[itemKey]! + 1;
                      }
                    }

                    int maleCount = 0, femaleCount = 0, otherGenderCount = 0;
                    int ageUnder1 = 0,
                        age1_5 = 0,
                        age6_18 = 0,
                        age19_35 = 0,
                        age36_60 = 0,
                        age60plus = 0;

                    for (var item in filteredData) {
                      if ((item.gender ?? "").toLowerCase().startsWith("m"))
                        maleCount++;
                      else if ((item.gender ?? "").toLowerCase().startsWith(
                        "f",
                      ))
                        femaleCount++;
                      else
                        otherGenderCount++;

                      String ageStr = item.age ?? "0";
                      if (ageStr == "0-1") {
                        ageUnder1++;
                      } else {
                        try {
                          int age = int.parse(ageStr);
                          if (age == 0) {
                            ageUnder1++;
                          } else if (age <= 5) {
                            age1_5++;
                          } else if (age <= 18) {
                            age6_18++;
                          } else if (age <= 35) {
                            age19_35++;
                          } else if (age <= 60) {
                            age36_60++;
                          } else {
                            age60plus++;
                          }
                        } catch (e) {
                          // ignore bad data
                        }
                      }
                    }

                    return _buildDashboard(
                      isAccountEmpty: isAccountEmpty,
                      filteredData: filteredData,
                      barCount: barCount,
                      currentWeekStart: currentWeekStart,
                      currentWeekEnd: currentWeekEnd,
                      dailyCounts: dailyCounts,
                      processingStatusCounts: processingStatusCounts,
                      visitTypeCounts: visitTypeCounts,
                      canGoPrevious: canGoPrevious,
                      canGoNext: canGoNext,
                      maleCount: maleCount,
                      femaleCount: femaleCount,
                      otherGenderCount: otherGenderCount,
                      ageUnder1: ageUnder1,
                      age1_5: age1_5,
                      age6_18: age6_18,
                      age19_35: age19_35,
                      age36_60: age36_60,
                      age60plus: age60plus,
                    );
                  } catch (e) {
                    return Center(child: Text("Error processing data: $e"));
                  }

                default:
                  return const Center(
                    child: CircularProgressIndicator(color: Colorprimary),
                  );
              }
            },
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: "add_btn",
              backgroundColor: Colorprimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Border radius 4 set ho gaya
              ),
              onPressed: () async {
                // 1. Wait karein jab tak user consultation screen se wapas na aa jaye
                await Navigator.pushNamed(
                  context,
                  RouteNames.consultationSelection,
                );

                // 2. Wapas aate hi data refresh karein
                print("User returned! Refreshing dashboard...");
                myEncounterViewModel.getEncounters();
              },
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: "view_btn",
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.MyEncountersScreen,
                arguments: {
                  "filter": selectedTimeFilter,
                  "customDate": customStartDate,
                  "monthDate": monthViewDate,
                },
              ),
              label: const Text(
                "Consultations",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(
                Icons.manage_search_outlined,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildContextHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 8),
          Text(
            selectedTimeFilter == "Today"
                ? "Report for Today"
                : selectedTimeFilter == "Week"
                ? "Report for Last 7 Days"
                : selectedTimeFilter == "Custom"
                ? "Report for ${DateFormat('dd MMM yyyy').format(customStartDate ?? DateTime.now())}"
                : "Report for ${DateFormat('MMMM yyyy').format(monthViewDate)}",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(
      bool canPrev,
      bool canNext,
      DateTime start,
      DateTime end,
      ) {
    final String displayDate =
    DateFormat('dd MMM').format(start) == DateFormat('dd MMM').format(end)
        ? DateFormat('dd MMM').format(start)
        : "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: canPrev ? Colors.black : Colors.grey.shade300,
            ),
            onPressed: canPrev ? () => setState(() => weekOffset++) : null,
          ),
          Text(
            displayDate,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: canNext ? Colors.black : Colors.grey.shade300,
            ),
            onPressed: canNext ? () => setState(() => weekOffset--) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(int count, DateTime start, Map<String, int> daily) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 10.0),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(count, (i) {
            final dayKey = DateFormat(
              'yyyy-MM-dd',
            ).format(start.add(Duration(days: i)));
            return _bar(i, (daily[dayKey] ?? 0).toDouble());
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  int i = val.toInt();
                  if (i < 0 || i >= count) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('E').format(start.add(Duration(days: i))),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPie(Map<String, int> counts) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: (counts['Completed'] ?? 0).toDouble(),
                  title: "${counts['Completed']}",
                  color: Colorprimary,
                  radius: 50,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: (counts['Under Process'] ?? 0).toDouble(),
                  title: "${counts['Under Process']}",
                  color: Colorprimarylight,
                  radius: 50,
                  titleStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: (counts['Delayed'] ?? 0).toDouble(),
                  title: "${counts['Delayed']}",
                  color: Colors.black,
                  radius: 50,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem(Colorprimary, "Completed"),
            _legendItem(Colorprimarylight, "Under Process"),
            _legendItem(Colors.black, "Delayed"),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitPie(Map<String, int> counts) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: (counts['New'] ?? 0).toDouble(),
                  title: "${counts['New']}",
                  color: Colorprimary,
                  radius: 50,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: (counts['Follow Up'] ?? 0).toDouble(),
                  title: "${counts['Follow Up']}",
                  color: Colors.black,
                  radius: 50,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem(Colorprimary, "New"),
            _legendItem(Colors.black, "Follow Up"),
          ],
        ),
      ],
    );
  }

  Widget _filterButton(String text) {
    final isSelected = selectedTimeFilter == text;
    final boxDecoration = BoxDecoration(
      color: isSelected ? Colorprimary : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colorprimary, width: 1),
    );
    final textStyle = TextStyle(
      color: isSelected ? Colors.white : Colorprimary,
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    if (text == "Month") {
      return PopupMenuButton<DateTime>(
        offset: const Offset(0, 40),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) => setState(() {
          monthViewDate = val;
          selectedTimeFilter = "Month";
          _resetToCurrentWeek();
        }),
        itemBuilder: (ctx) => _generateMonthList()
            .map(
              (d) => PopupMenuItem(
            value: d,
            child: Text(DateFormat('MMMM yyyy').format(d)),
          ),
        )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: boxDecoration,
          child: Text(text, style: textStyle),
        ),
      );
    }
    return GestureDetector(
      onTap: () async {
        if (text == "Custom") {
          DateTime? p = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Colorprimary),
              ),
              child: child!,
            ),
          );
          if (p != null)
            setState(() {
              customStartDate = p;
              selectedTimeFilter = text;
              _resetToCurrentWeek();
            });
        } else
          setState(() {
            selectedTimeFilter = text;
            monthViewDate = DateTime.now();
            _resetToCurrentWeek();
          });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: boxDecoration,
        child: Text(text, style: textStyle),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _collapsibleCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 14,
          color: Colorprimary,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required String title, required Widget content}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _linkRow(String label, int count, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: count > 0
                ? () => Navigator.pushNamed(
              context,
              RouteNames.MyEncountersScreen,
              arguments: {
                "filter": selectedTimeFilter,
                "customDate": customStartDate,
                "monthDate": monthViewDate,
                key: value,
              },
            )
                : null,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: count > 0
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: Colors.black,
                color: count > 0 ? Colors.black : Colors.grey,
              ),
            ),
          ),
          Text(
            "$count",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}