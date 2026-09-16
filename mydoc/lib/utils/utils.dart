import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart' show showFlushbar;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:medicalai/repository/Repository.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/appDialog.dart';
import 'package:medicalai/routes/routs_name.dart';

class utils {
  // 🟢 FIXED: Added Null safety and default values
  static toastMessage(String? message) {
    if (message == null || message.isEmpty) {
      print("Toast skipped: Message was null or empty");
      return;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM, // Use standard gravity
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // 🟢 IMPROVED: Success Message Flushbar
  static void flushBarSuccessMessages(String message, BuildContext context) {
    showFlushbar(
      context: context,
      flushbar: Flushbar(
        message: message,
        forwardAnimationCurve: Curves.decelerate,
        margin: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(8),
        reverseAnimationCurve: Curves.easeOut,
        flushbarPosition: FlushbarPosition.TOP, // Top looks better for success
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 3),
      )..show(context),
    );
  }

  static void flushBarErrorMessages(String message, BuildContext context) {
    showFlushbar(
      context: context,
      flushbar: Flushbar(
        message: message,
        margin: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.BOTTOM,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      )..show(context),
    );
  }

  String generateSixDigitCode() {
    final random = Random();
    int code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  static String generatePincode() {
    final Random random = Random();
    String number = '';
    for (int i = 0; i < 4; i++) {
      if (i == 0) {
        number += (random.nextInt(9) + 1).toString();
      } else {
        number += random.nextInt(10).toString();
      }
    }
    return number;
  }

  static Future<String> getFilePath(String filename) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$filename';
  }

  static int getStatusCodeFromMessage(String errorMessage){
    RegExp regExp = RegExp(r'status code\s*(\d+)');
    Match? match = regExp.firstMatch(errorMessage);
    if (match != null) {
      return int.parse(match.group(1)!);
    } else {
      return 0;
    }
  }

  static Future<bool> checkEntitlementAndLimit(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      final String doctorId = (HiveStorage.getEmail() ?? "").trim().toLowerCase();
      final String token = HiveStorage.getToken() ?? "";
      if (doctorId.isEmpty || token.isEmpty) {
        Navigator.pop(context);
        return false;
      }

      final status = await Repository().getEntitlementStatusApi(doctorId, token).timeout(const Duration(seconds: 15));
      print("GET ENTITLEMENT STATUS API RESPONSE: $status");
      Navigator.pop(context); // Close loading dialog

      if (status == null) return true; // Fail-safe: allow on server failure

      final data = (status is Map && status.containsKey('response')) ? status['response'] : status;

      final statusStr = data['status'] ?? '';

      if (statusStr != 'active') {
        _showUpgradeDialog(context, "No active plan or plan has expired. Please select a package to continue.");
        return false;
      }

      final num remainingMinutes = data['remaining_minutes'] ?? 0;

      if (remainingMinutes <= 0) {
        _showUpgradeDialog(context, "You have exhausted your plan minutes. Please upgrade to a paid plan to continue.");
        return false;
      }

      return true;
    } catch (e) {
      print("Error checking entitlement: $e");
      Navigator.pop(context); // Close loading dialog
      return true; // Fail-safe
    }
  }

  static void _showUpgradeDialog(BuildContext context, String message) {
    showAppDialog(
      context: context,
      icon: Icons.lock_outline,
      title: "Limit Reached",
      content: message,
      primaryText: "Upgrade Now",
      onPrimary: () {
        Navigator.pop(context); // Close dialog
        Navigator.pushNamed(context, RouteNames.upgrade);
      },
      secondaryText: "Cancel",
      onSecondary: () => Navigator.pop(context),
    );
  }
}