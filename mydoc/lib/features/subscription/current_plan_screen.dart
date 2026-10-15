import 'package:flutter/material.dart';

import '../../app/routes/routs_name.dart';
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
  static const Color primaryTeal = Color(0xFF3FA3BA);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: primaryTeal,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Current plan',
          style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : RefreshIndicator(
              color: primaryTeal,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _body(),
                ],
              ),
            ),
    );
  }

  Widget _body() {
    final read = _read;
    if (read == null ||
        read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      return _card(
        title: 'Plan status unavailable',
        lines: const [
          'Your plan could not be checked. It is not shown as active.',
        ],
        action: TextButton(onPressed: _load, child: const Text('Retry')),
      );
    }

    final current = read.snapshot;
    if (current == null || !current.hasEntitlement) {
      return _card(
        title: 'No active subscription',
        lines: const [
          'There is no current plan on this account.',
        ],
        action: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: () => Navigator.pushNamed(context, RouteNames.subscription_screen),
          child: const Text('View plans'),
        ),
      );
    }

    return _card(
      title: current.planName.isEmpty ? 'Current plan' : current.planName,
      lines: [
        current.statusLabel,
        'Type: ${current.isTrial ? 'Trial' : 'Paid'}',
        'Starts: ${_date(current.startsAt)}',
        'Expires: ${_date(current.expiresAt)}',
        'Time left: ${EntitlementHelper.formatSeconds(current.remainingSeconds)} '
            'of ${EntitlementHelper.formatSeconds(current.allocatedSeconds)}',
        'Used: ${EntitlementHelper.formatSeconds(current.consumedSeconds)}',
        if (current.reservedSeconds > 0)
          'Reserved: ${EntitlementHelper.formatSeconds(current.reservedSeconds)}',
      ],
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.subscription_screen),
            child: const Text('View plans'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF255563),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _cancelling ? null : _confirmCancel,
            child: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Cancel subscription'),
          ),
        ],
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not available';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month - 1]} ${value.year}, $hour:$minute';
  }

  Widget _card({
    required String title,
    required List<String> lines,
    required Widget action,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Text(line, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}
