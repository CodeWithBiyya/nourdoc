import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart' show showFlushbar;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:medicalai/core/repository/Repository.dart';
import 'package:medicalai/core/common/appDialog.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/core/common/entitlement_helper.dart';

class utils {
  /// Set when the latest protected-access check failed because the plan
  /// cannot be used. A network failure leaves this false.
  static bool planBlocksConsultation = false;

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

  /// Loads the entitlement and returns it only when protected use is allowed.
  /// A network or unreadable response does not grant access.
  ///
  /// [upcomingSeconds] is the audio about to be uploaded, in seconds.
  /// If it is longer than the remaining plan time, the doctor can still
  /// continue: the backend decides how much time is used.
  static Future<EntitlementSnapshot?> requireProtectedAccess(
    BuildContext context, {
    int? upcomingSeconds,
    bool showProgress = true,
  }) async {
    planBlocksConsultation = false;

    if (showProgress) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CupertinoActivityIndicator(radius: 20)),
      );
    }

    final read = await Repository().readDoctorEntitlement();
    if (showProgress && context.mounted) Navigator.pop(context);
    if (!context.mounted) return null;

    if (read.result == EntitlementFetchResult.network) {
      await showAppDialog(
        context: context,
        barrierDismissible: false,
        icon: Icons.wifi_off,
        title: 'Could not verify plan',
        content: 'Your plan could not be checked. Nothing was started. Try again when you are online.',
        primaryText: 'OK',
        onPrimary: () => Navigator.pop(context),
      );
      return null;
    }

    final snapshot = read.snapshot;
    if (snapshot == null || !snapshot.canUseProtectedFeatures) {
      planBlocksConsultation = true;
      await _showUpgradeDialog(
        context,
        snapshot?.blockReason ?? 'Your plan could not be read. Try again.',
      );
      return null;
    }

    if (upcomingSeconds != null && upcomingSeconds > snapshot.remainingSeconds) {
      final proceed = await showAppDialog<bool>(
        context: context,
        icon: Icons.timer_outlined,
        title: 'Longer than plan time',
        content:
            'This recording is ${EntitlementHelper.formatSeconds(upcomingSeconds)}. '
            'Your plan has ${EntitlementHelper.formatSeconds(snapshot.remainingSeconds)} left. '
            'The server decides how much time is used.',
        primaryText: 'Upload anyway',
        onPrimary: () => Navigator.pop(context, true),
        secondaryText: 'Not now',
        onSecondary: () => Navigator.pop(context, false),
      );
      if (proceed != true) return null;
    }

    return snapshot;
  }

  static Future<bool> checkEntitlementAndLimit(BuildContext context) async {
    final snapshot = await requireProtectedAccess(context);
    return snapshot != null;
  }

  /*
  Previous check. It looked for status == "active" and remaining_minutes,
  then still returned true, so recording continued. A failed request also
  returned true.

  static Future<bool> checkEntitlementAndLimit(BuildContext context) async {
    showDialog(...loader...);
    try {
      final String doctorId = (HiveStorage.getEmail() ?? "").trim().toLowerCase();
      final String token = HiveStorage.getToken() ?? "";
      if (doctorId.isEmpty || token.isEmpty) {
        Navigator.pop(context);
        return false;
      }
      final status = await Repository().getEntitlementStatusApi(doctorId, token).timeout(const Duration(seconds: 15));
      Navigator.pop(context);
      if (status == null) return true;
      final data = (status is Map && status.containsKey('response')) ? status['response'] : status;
      final statusStr = data['status'] ?? '';
      if (statusStr != 'active') {
        _showUpgradeDialog(context, "No active plan or plan has expired. Please select a package to continue.");
        // return false;
        return true;
      }
      final num remainingMinutes = data['remaining_minutes'] ?? 0;
      if (remainingMinutes <= 0) {
        _showUpgradeDialog(context, "You have exhausted your plan minutes. Please upgrade to a paid plan to continue.");
        // return false;
        return true;
      }
      return true;
    } catch (e) {
      Navigator.pop(context);
      return true;
    }
  }

  The dialog button used to open RouteNames.upgrade ("Upgrade Now").
  It now opens RouteNames.subscription_screen ("View plans").
  */

  static Future<void> _showUpgradeDialog(BuildContext context, String message) async {
    final openPlans = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      icon: Icons.lock_outline,
      title: 'Consultation unavailable',
      content: message,
      primaryText: 'View Plans',
      onPrimary: () => Navigator.pop(context, true),
      secondaryText: 'Close',
      onSecondary: () => Navigator.pop(context, false),
    );
    if (openPlans == true && context.mounted) {
      await Navigator.pushNamed(context, RouteNames.subscription_screen);
    }
  }
}