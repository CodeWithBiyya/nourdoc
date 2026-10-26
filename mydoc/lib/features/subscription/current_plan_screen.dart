import 'package:flutter/material.dart';

import '../../app/routes/routs_name.dart';
import '../../app/theme/colors.dart';
import '../../core/common/appDialog.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/common/http_result.dart';
import '../../core/repository/Repository.dart';
import '../../core/services/PlanRequestApiService.dart';
import '../../core/storage/hive_storage.dart';

class CurrentPlanScreen extends StatefulWidget {
  const CurrentPlanScreen({super.key});

  @override
  State<CurrentPlanScreen> createState() => _CurrentPlanScreenState();
}

class _CurrentPlanScreenState extends State<CurrentPlanScreen> {
  static const Color primaryTeal = Colorprimary;

  EntitlementRead? _read;
  bool _loading = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final read = await Repository().readDoctorEntitlement();
    if (!mounted) return;
    setState(() {
      _read = read;
      _loading = false;
    });
  }

  Future<void> _confirmCancel() async {
    if (_cancelling) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      icon: Icons.cancel_outlined,
      title: 'Cancel subscription?',
      content: 'This asks the server to cancel the current plan.',
      primaryText: 'Cancel plan',
      onPrimary: () => Navigator.pop(context, true),
      secondaryText: 'Keep plan',
      onSecondary: () => Navigator.pop(context, false),
    );
    if (confirmed == true) _cancel();
  }

  Future<void> _cancel() async {
    final email = (HiveStorage.getUserEmail() ?? '').trim().toLowerCase();
    final token = HiveStorage.getToken() ?? '';
    if (email.isEmpty || token.isEmpty) {
      _message('Doctor is not logged in. The plan was not changed.');
      return;
    }

    setState(() => _cancelling = true);
    final result = await PlanRequestApiService().cancelPlan(
      doctorEmail: email,
      token: token,
    );
    if (!mounted) return;

    if (!result.reachedServer) {
      setState(() => _cancelling = false);
      _message(result.message);
      return;
    }

    final refreshed = await Repository().readDoctorEntitlement();
    if (!mounted) return;
    setState(() {
      if (refreshed.result != EntitlementFetchResult.network) {
        _read = refreshed;
      }
      _cancelling = false;
    });

    _message(_cancelMessage(result, refreshed));
  }

  String _cancelMessage(HttpResult result, EntitlementRead refreshed) {
    final backend = result.message.trim();

    if (result.statusCode == 401 && backend.isEmpty) {
      return 'Your session has expired. Log in again. The plan was not changed.';
    }

    if (result.isSuccess && refreshed.result == EntitlementFetchResult.network) {
      return backend.isEmpty
          ? 'The server accepted the cancellation, but the plan could not be read again.'
          : '$backend The plan could not be read again.';
    }

    if (result.isSuccess && refreshed.snapshot?.canUseProtectedFeatures == true) {
      return backend.isEmpty
          ? 'The server accepted the cancellation. The plan still shows as active, so it was left on screen.'
          : '$backend The plan still shows as active, so it was left on screen.';
    }

    if (backend.isNotEmpty) return backend;
    return 'The plan could not be cancelled (${result.statusCode}).';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 5)),
    );
  }

  void _leave() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final token = (HiveStorage.getToken() ?? '').trim();
    final signedIn = token.isNotEmpty && token.toLowerCase() != 'null';
    Navigator.pushReplacementNamed(
      context,
      signedIn ? RouteNames.dashboard : RouteNames.splash1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canLeaveToPreviousScreen = Navigator.of(context).canPop();
    return PopScope(
      canPop: canLeaveToPreviousScreen,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: ColoredBox(color: Color(0xFFE6EEF0), child: SizedBox(height: 1)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryTeal, size: 22),
          onPressed: _leave,
        ),
        title: const Text(
          'Current plan',
          style: TextStyle(
            color: Color(0xFF1C2B33),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : RefreshIndicator(
              color: primaryTeal,
              backgroundColor: Colors.white,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _body(),
                ],
              ),
            ),
    ),
    );
  }

  Widget _body() {
    final read = _read;
    if (read == null ||
        read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      return _notice(
        title: 'Plan status unavailable',
        message: 'Your plan could not be checked. It is not shown as active.',
        action: TextButton(onPressed: _load, child: const Text('Retry')),
      );
    }

    final current = read.snapshot;
    if (current == null || !current.hasEntitlement) {
      return _notice(
        title: 'No active subscription',
        message: 'There is no current plan on this account.',
        action: SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pushNamed(context, RouteNames.subscription_screen),
            child: const Text('View plans'),
          ),
        ),
      );
    }

    final remaining = EntitlementHelper.formatSeconds(current.remainingSeconds);
    final allocated = EntitlementHelper.formatSeconds(current.allocatedSeconds);
    final used = EntitlementHelper.formatSeconds(current.consumedSeconds);
    final active = current.canUseProtectedFeatures;
    final progress = current.allocatedSeconds <= 0
        ? 0.0
        : (current.consumedSeconds / current.allocatedSeconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E8EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _planTitle(current.planName),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2B33),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _badge(active ? 'Active' : current.statusLabel, filled: active),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                remaining,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colorprimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining of $allocated',
                style: const TextStyle(fontSize: 13, color: Color(0xFF5C6B72)),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE1E8EA)),
              const SizedBox(height: 12),
              const Text(
                'USAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colorprimary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE3EBED),
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).round()}% used',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5C6B72)),
              ),
              const SizedBox(height: 4),
              _metric('Remaining', remaining),
              _metric('Used', used),
              _metric('Total', allocated),
              if (current.reservedSeconds > 0)
                _metric('Reserved', EntitlementHelper.formatSeconds(current.reservedSeconds)),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE1E8EA)),
              const SizedBox(height: 12),
              const Text(
                'SUBSCRIPTION DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colorprimary,
                ),
              ),
              _detail('Plan type', current.isTrial ? 'Trial' : 'Paid'),
              _detail('Started', _date(current.startsAt)),
              _detail('Expires', _date(current.expiresAt)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pushNamed(context, RouteNames.subscription_screen),
            child: const Text(
              'View plans',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTeal,
              side: const BorderSide(color: Colorprimary, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _cancelling ? null : _confirmCancel,
            child: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colorprimary),
                  )
                : const Text(
                    'Cancel subscription',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  String _planTitle(String name) {
    final text = name.trim();
    if (text.isEmpty) return 'Current plan';
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _badge(String label, {required bool filled}) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFE7EEF4) : const Color(0xFFF3F5F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: filled ? Colorprimary : const Color(0xFF8A97A0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled ? Colorprimary : const Color(0xFF5C6B72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF5C6B72))),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C2B33),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF5C6B72))),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2B33),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice({
    required String title,
    required String message,
    required Widget action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C2B33),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF5C6B72)),
        ),
        const SizedBox(height: 16),
        action,
      ],
    );
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not available';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month - 1]} ${value.year}, $hour:$minute';
  }

}
