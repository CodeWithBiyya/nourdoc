// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// // import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// // import 'package:medicalai/services/background_queue_coordinator.dart';
// import 'package:medicalai/utils/colors.dart';
// import 'package:medicalai/utils/hive_storage.dart';
// import 'package:medicalai/utils/appDialog.dart'; // 🚩 Ensure this is the correct path to your dialog file
// import 'package:permission_handler/permission_handler.dart';
// import '../../routes/routs_name.dart';
// import '../../repository/Repository.dart';

// class splashscreen extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _splashscreen();
// }

// class _splashscreen extends State<splashscreen> {

//   void _showPermissionRequiredDialog() {
//     // 🚩 Reusing your showAppDialog function
//     showAppDialog(
//       context: context,
//       barrierDismissible: false, // Force them to choose
//       icon: Icons.notifications_active_outlined, // Professional sync icon
//       title: "Notification Permission Required",
//       content: "NourDoc needs notification permissions to securely sync your consultations in the background. Please enable them in settings to continue.",
//       primaryText: "Open Settings",
//       onPrimary: () async {
//         Navigator.pop(context); // Close dialog
//         await openAppSettings(); // Open Android settings
//         // Note: The user will manually return to the app and click "Get Started" again
//       },
//       secondaryText: "Cancel",
//       onSecondary: () => Navigator.pop(context),
//     );
//   }

//   Future<void> _checkTokenAndNavigate() async {
//     var token = HiveStorage.getToken();
//     final emailVal = HiveStorage.getEmail();
//     String? email = emailVal != null ? emailVal.trim().toLowerCase() : null;
//     bool hasValidToken = token != null &&
//         token.toString().toLowerCase() != 'null' &&
//         token.toString().trim().isNotEmpty;

//     if (hasValidToken && email != null && email.isNotEmpty) {
//       // Show loader
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator(color: Colorprimary)),
//       );

//       try {
//         final repo = Repository();
//         final status = await repo.getEntitlementStatusApi(email, token).timeout(const Duration(seconds: 15));
//         print("SPLASH ENTITLEMENT STATUS API RESPONSE: $status");

//         if (mounted) Navigator.pop(context); // Remove loader

//         if (status != null) {
//           final data = (status is Map && status.containsKey('response')) ? status['response'] : status;
//           final statusStr = data['status'] ?? '';
//           if (statusStr == 'active') {
//             num remainingMinutes = data['remaining_minutes'] ?? 0;
//             if (remainingMinutes <= 0) {
//               if (mounted) Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
//             } else {
//               if (mounted) Navigator.pushReplacementNamed(context, RouteNames.dashboard);
//             }
//           } else {
//             if (mounted) Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
//           }
//         } else {
//           if (mounted) Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
//         }
//       } catch (e) {
//         print("Status check error in splash: $e");
//         if (mounted) Navigator.pop(context); // Remove loader
//         // Fallback to dashboard to prevent locking user out offline
//         if (mounted) Navigator.pushReplacementNamed(context, RouteNames.dashboard);
//       }
//     } else {
//       if (mounted) Navigator.pushReplacementNamed(context, RouteNames.login_with_email);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SizedBox(
//         height: screenHeight,
//         width: screenWidth,
//         child: Column(
//           children: [

//             Expanded(
//               flex: 5,
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Image.asset(
//                     "assets/icons/black_new.png",
//                     width: screenWidth * 0.7,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               flex: 5,
//               child: Container(
//                 width: screenWidth,
//                 decoration: BoxDecoration(
//                   color: Colorprimary,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(50),
//                     topRight: Radius.circular(50),
//                   ),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Every Patient Deserves Your Full Attention",
//                           style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 20),
//                       const Text(
//                         "NourDoc securely transforms clinical conversations into structured documentation, allowing you to focus on what matters most... your patients.",
//                         style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
//                       ),
//                       const Spacer(),
//                       Center(
//                         child: ElevatedButton(
//                           // onPressed: _handleGetStarted,
//                           onPressed: _checkTokenAndNavigate,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             fixedSize: Size(screenWidth > 600 ? 400 : 300, 50),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                           ),
//                           child: const Text('Get Started', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:medicalai/services/background_queue_coordinator.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/appDialog.dart'; // 🚩 Ensure this is the correct path to your dialog file
import 'package:permission_handler/permission_handler.dart';
import '../../routes/routs_name.dart';
import 'package:medicalai/utils/entitlement_helper.dart';
import '../../repository/Repository.dart';

class splashscreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _splashscreen();
}

class _splashscreen extends State<splashscreen> {

  void _showPermissionRequiredDialog() {
    // 🚩 Reusing your showAppDialog function
    showAppDialog(
      context: context,
      barrierDismissible: false, // Force them to choose
      icon: Icons.notifications_active_outlined, // Professional sync icon
      title: "Notification Permission Required",
      content: "NourDoc needs notification permissions to securely sync your consultations in the background. Please enable them in settings to continue.",
      primaryText: "Open Settings",
      onPrimary: () async {
        Navigator.pop(context); // Close dialog
        await openAppSettings(); // Open Android settings
        // Note: The user will manually return to the app and click "Get Started" again
      },
      secondaryText: "Cancel",
      onSecondary: () => Navigator.pop(context),
    );
  }

  Future<void> _checkTokenAndNavigate() async {
    var token = HiveStorage.getToken();
    final emailVal = HiveStorage.getEmail();
    String? email = emailVal != null ? emailVal.trim().toLowerCase() : null;
    bool hasValidToken = token != null &&
        token.toString().toLowerCase() != 'null' &&
        token.toString().trim().isNotEmpty;

    if (hasValidToken && email != null && email.isNotEmpty) {
      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colorprimary)),
      );

      try {
        final repo = Repository();
        final status = await repo.getEntitlementStatusApi(email, token).timeout(const Duration(seconds: 15));
        print("SPLASH ENTITLEMENT STATUS API RESPONSE: $status");

        if (mounted) Navigator.pop(context); // Remove loader

        if (status != null) {
          // final data = (status is Map && status.containsKey('response')) ? status['response'] : status;
          // final statusStr = (data is Map ? (data['status'] ?? '') : '').toString().trim().toLowerCase();

          // // Doctor is enrolled in a plan -> go straight to Dashboard
          // // (remaining minutes are enforced later, when starting a consultation)
          // final bool isEnrolled =
          //     statusStr == 'active' || (data is Map && data['is_active'] == true);

          final bool isEnrolled = EntitlementHelper.isEnrolled(status);

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              isEnrolled ? RouteNames.dashboard : RouteNames.subscription_screen,
            );
          }
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
        }
      } catch (e) {
        print("Status check error in splash: $e");
        if (mounted) Navigator.pop(context); // Remove loader
        // Fallback to dashboard to prevent locking user out offline
        if (mounted) Navigator.pushReplacementNamed(context, RouteNames.dashboard);
      }
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, RouteNames.login_with_email);
    }
  }

// Future<void> _checkTokenAndNavigate() async {
//   var token = HiveStorage.getToken();

//   final emailVal = HiveStorage.getEmail();
//   String? email =
//       emailVal != null ? emailVal.trim().toLowerCase() : null;

//   bool hasValidToken = token != null &&
//       token.toString().toLowerCase() != 'null' &&
//       token.toString().trim().isNotEmpty;

//   if (hasValidToken && email != null && email.isNotEmpty) {
//     // TEMPORARY:
//     // Skip entitlement/subscription check completely.
//     // Go directly to dashboard so consultation can be tested.

//     print("TEMP TEST MODE: Skipping subscription/entitlement check");

//     if (mounted) {
//       Navigator.pushReplacementNamed(
//         context,
//         RouteNames.dashboard,
//       );
//     }
//   } else {
//     // No valid login -> go to login
//     if (mounted) {
//       Navigator.pushReplacementNamed(
//         context,
//         RouteNames.login_with_email,
//       );
//     }
//   }
// }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Column(
          children: [

            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    "assets/icons/black_new.png",
                    width: screenWidth * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: screenWidth,
                decoration: BoxDecoration(
                  color: Colorprimary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Every Patient Deserves Your Full Attention",
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text(
                        "NourDoc securely transforms clinical conversations into structured documentation, allowing you to focus on what matters most... your patients.",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const Spacer(),
                      Center(
                        child: ElevatedButton(
                          // onPressed: _handleGetStarted,
                          onPressed: _checkTokenAndNavigate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            fixedSize: Size(screenWidth > 600 ? 400 : 300, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Get Started', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

