import 'package:flutter/material.dart';

import '../../app/routes/routs_name.dart';
import '../../core/common/appDialog.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/repository/Repository.dart';

/// Fresh entitlement read used before subscribe or simulated payment.
/// Returns true when the purchase must not continue.
Future<bool> subscriptionBlocked(BuildContext context) async {
  final read = await Repository().readDoctorEntitlement();
  if (!context.mounted) return true;

  if (read.result == EntitlementFetchResult.network ||
      read.result == EntitlementFetchResult.malformed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your current plan could not be checked. A new plan was not started.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    return true;
  }

  final current = read.snapshot;
  if (current != null && current.blocksAnotherPurchase) {
    final name = current.planName.isEmpty ? 'current' : current.planName;
    await showAppDialog<void>(
      context: context,
      icon: Icons.verified_outlined,
      title: 'Plan already active',
      content:
          'You already have an active $name plan. A new plan was not started.',
      primaryText: 'View current plan',
      onPrimary: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, RouteNames.current_plan);
      },
      secondaryText: 'Close',
      onSecondary: () => Navigator.pop(context),
    );
    return true;
  }

  return false;
}
