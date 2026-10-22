import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/common/appDialog.dart';
import '../../core/models/PlanModel.dart';
import '../../core/repository/Repository.dart';
import '../../core/services/PlanRequestApiService.dart';
import '../../core/services/pricing_api_service.dart';
import '../../core/common/api_envelope.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/storage/hive_storage.dart';
import '../../app/routes/routs_name.dart';
import '../../app/theme/colors.dart';
import 'Checkout.dart';
import 'subscription_guard.dart';

class SubscriptionScreen1 extends StatefulWidget {
  const SubscriptionScreen1({super.key});

  @override
  State<SubscriptionScreen1> createState() => _SubscriptionScreen1State();
}

class _SubscriptionScreen1State extends State<SubscriptionScreen1> {
  int? expandedIndex;

  final Color primaryTeal = Colorprimary;

  final PricingApiService _pricingApiService = PricingApiService();

  List<PlanModel> allPlans = [];

  bool isLoading = true;
  String? errorMessage;
  EntitlementRead? entitlementRead;
  String? activatingPlanId;
  bool _planActionInFlight = false;
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  EntitlementSnapshot? get _entitlement => entitlementRead?.snapshot;

  bool _samePlan(PlanModel plan) {
    final current = _entitlement;
    if (current == null || !current.hasEntitlement) return false;
    return current.planId == plan.id ||
        current.planName.toUpperCase() == plan.planCode.toUpperCase();
  }

  bool _purchaseBlocked(PlanModel plan) {
    final read = entitlementRead;
    if (read == null ||
        read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      return true;
    }

    final current = read.snapshot;
    if (current == null || !current.hasEntitlement) return false;
    if (!current.isExpired) return true;
    return current.isTrial && plan.planCode.toUpperCase() == 'TRIAL';
  }

  String _buttonLabel(PlanModel plan) {
    final read = entitlementRead;
    if (read == null ||
        read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      return 'Unavailable';
    }
    if (plan.planCode.toLowerCase() == 'enterprise') return 'Talk to us';

    final current = _entitlement;
    if (current != null && _samePlan(plan) && !current.isExpired) {
      return 'Current plan';
    }
    if (current != null && current.isExpired && current.isTrial && plan.planCode.toUpperCase() == 'TRIAL') {
      return 'Trial ended';
    }
    if (current != null && current.blocksAnotherPurchase && !_samePlan(plan)) {
      return 'Activate plan';
    }
    // GET /plans/entitlement does not say whether a trial was used before
    // when no entitlement is returned, and an expired paid plan does not
    // include trial history either. "Start trial" is shown only because
    // eligibility cannot be known here. The server accepts or rejects it.
    if (plan.effectivePrice == 0) return 'Start trial';
    return 'Proceed with ${plan.formattedPrice}';
  }

  Future<void> _loadPlans() async {
    try {
      final plansFuture = _pricingApiService.getPlans();
      final entitlementFuture = Repository().readDoctorEntitlement();
      final plans = await plansFuture;
      final entitlement = await entitlementFuture;

      if (!mounted) return;

      setState(() {
        allPlans = plans;
        entitlementRead = entitlement;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = safeErrorText(e);
      });

      debugPrint('Error loading plans: $e');
    }
  }

  Future<void> _activateWithoutPayment(PlanModel plan) async {
    if (activatingPlanId != null) return;
    if (await subscriptionBlocked(context)) return;
    if (!mounted) return;

    final doctorId = (HiveStorage.getUserEmail() ?? '').trim().toLowerCase();
    if (doctorId.isEmpty) {
      _showMessage('Doctor is not logged in.');
      return;
    }

    setState(() => activatingPlanId = plan.id);

    final result = await PlanRequestApiService().subscribeToPlan(
      doctorId: doctorId,
      planId: plan.id,
    );
    if (!mounted) return;

    if (result.isStripeCheckout) {
      setState(() => activatingPlanId = null);
      _showMessage(
        'Stripe checkout was returned. Payment on Stripe is not connected in the app yet, so this plan was not activated.',
      );
      return;
    }

    if (!result.isSuccess || result.data == null) {
      if (result.reachedServer) {
        final read = await Repository().readDoctorEntitlement();
        if (!mounted) return;
        setState(() {
          entitlementRead = read;
          activatingPlanId = null;
        });
      } else {
        setState(() => activatingPlanId = null);
      }
      _showMessage(result.message);
      return;
    }

    final read = await Repository().readDoctorEntitlement();
    if (!mounted) return;

    final confirmed = read.snapshot;
    final matches = confirmed != null &&
        (confirmed.planId == plan.id ||
            confirmed.planName.toUpperCase() == plan.planCode.toUpperCase());

    if (confirmed == null || !matches || !confirmed.canUseProtectedFeatures) {
      setState(() {
        entitlementRead = read;
        activatingPlanId = null;
      });
      _showMessage('The trial could not be confirmed. Nothing else was changed.');
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _onPlanAction(PlanModel plan) async {
    if (_planActionInFlight) return;
    _planActionInFlight = true;
    try {
      await _runPlanAction(plan);
    } finally {
      _planActionInFlight = false;
    }
  }

  Future<void> _runPlanAction(PlanModel plan) async {
    if (_purchaseBlocked(plan)) {
      final current = _entitlement;
      if (entitlementRead?.result == EntitlementFetchResult.network ||
          entitlementRead?.result == EntitlementFetchResult.malformed) {
        _showMessage('Your current plan could not be checked. A new plan was not started.');
        return;
      }
      if (current != null && current.blocksAnotherPurchase) {
        await subscriptionBlocked(context);
      }
      return;
    }
    if (await subscriptionBlocked(context) || !mounted) return;

    // Previous button always opened Checkout, including a free trial:
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => Checkout(selectedPlan: plan),
    // ));
    if (plan.effectivePrice == 0 && plan.planCode.toLowerCase() != 'enterprise') {
      await _activateWithoutPayment(plan);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(selectedPlan: plan),
      ),
    );
    if (mounted) _loadPlans();
  }

  Future<void> _onBack() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    await showAppDialog<void>(
      context: context,
      icon: 'assets/icons/exit_1.png',
      title: 'Exit the app?',
      content:
          'A package is needed before the home screen. Stay and choose one, or exit the app.',
      secondaryText: 'Stay',
      primaryText: 'Exit',
      onPrimary: () => SystemNavigator.pop(),
    );
    if (mounted) _exitDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final canLeaveToPreviousScreen = Navigator.of(context).canPop();
    return PopScope(
      canPop: canLeaveToPreviousScreen,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE6EEF0)),
        ),

        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: primaryTeal,
                  size: 22,
                ),
                onPressed: _onBack,
              ),
              const Expanded(
                child: Text(
                  'Packages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1C2B33),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.home_outlined,
                  color: primaryTeal,
                  size: 22,
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.dashboard,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================

      body: _buildBody(),
    ),
    );
  }

  Widget _buildBody() {
    // Loading
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colorprimary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // No plans
    if (allPlans.isEmpty) {
      return const Center(
        child: Text(
          "No subscription plans available.",
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),

      itemCount: allPlans.length + 1,

      itemBuilder: (context, index) {
        if (index == 0) return _entitlementBanner();

        final plan = allPlans[index - 1];

        final bool isEnterprise =
            plan.planCode.toLowerCase().contains("enterprise");

        // Enterprise heading
        if (isEnterprise) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10, top: 8),
                child: Text(
                  'Enterprise Plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C2B33),
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              _buildPlanCard(
                plan,
                index,
              ),
            ],
          );
        }

        return _buildPlanCard(
          plan,
          index,
        );
      },
    );
  }

  // =========================================================
  // PLAN CARD
  // =========================================================

  Widget _buildPlanCard(
    PlanModel plan,
    int index,
  ) {
    final bool isExpanded = expandedIndex == index;
    final bool isEnterprise = plan.planCode.toLowerCase().contains('enterprise');
    final bool isCurrent = _samePlan(plan) && !(_entitlement?.isExpired ?? true);
    final bool blocked = _purchaseBlocked(plan);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF4F7FA) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? primaryTeal : const Color(0xFFE1E8EA),
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              expandedIndex = isExpanded ? null : index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      plan.icon.toString(),
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.business_center, size: 24);
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1C2B33),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isEnterprise
                              ? Text(
                                  plan.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5C6B72),
                                    height: 1.35,
                                  ),
                                )
                              : _buildFormattedDescription(plan.description),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 10),
                  _statusBadge('Current plan', filled: true),
                ] else if (plan.isActive) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Active (${plan.remainingMinutes ?? ''})',
                    style: const TextStyle(
                      color: Colorprimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? _planDetails(plan)
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (!isCurrent)
                        _actionButton(
                          activatingPlanId == plan.id ? 'Starting...' : _buttonLabel(plan),
                          blocked ? const Color(0xFFE6EBED) : primaryTeal,
                          blocked ? null : () => _onPlanAction(plan),
                        ),
                      if (plan.isActive)
                        _actionButton(
                          'Renew',
                          blocked ? const Color(0xFFE6EBED) : primaryTeal,
                          blocked
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Checkout(selectedPlan: plan),
                                    ),
                                  );
                                },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planDetails(PlanModel plan) {
    final seconds = _grouped(plan.includedSeconds);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE1E8EA)),
          const SizedBox(height: 12),
          const Text(
            'PLAN DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Color(0xFF7A8A90),
            ),
          ),
          const SizedBox(height: 4),
          _detailRow('AI minutes', '${plan.includedMinutes} min'),
          _detailRow('Validity', '${plan.expiryDays} days'),
          _detailRow('Included processing', '$seconds sec'),
        ],
      ),
    );
  }

  String _grouped(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5C6B72)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C2B33),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUTTON
  // =========================================================

  Widget _entitlementBanner() {
    final read = entitlementRead;
    if (read == null) return const SizedBox.shrink();

    if (read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      return _statusCard(
        'Your current plan could not be checked. Purchases stay closed until it can.',
        action: TextButton(onPressed: _loadPlans, child: const Text('Retry')),
      );
    }

    final current = read.snapshot;
    if (current == null || !current.hasEntitlement) {
      return _statusCard('No plan is subscribed.');
    }

    return const SizedBox.shrink();
  }

  Widget _statusBadge(String label, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _statusCard(String text, {Widget? action}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E8EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF3E4C52)),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : const Color(0xFF6E7C82),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DESCRIPTION FORMATTER
  // =========================================================

  Widget _buildFormattedDescription(
    String text,
  ) {
    final List<String> parts =
        text.split('*');

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
          height: 1.3,
        ),

        children:
            parts.asMap().entries.map(
          (entry) {
            final int index =
                entry.key;

            return TextSpan(
              text: entry.value,

              style: TextStyle(
                fontWeight:
                    index % 2 != 0
                        ? FontWeight.bold
                        : FontWeight.normal,

                color:
                    index % 2 != 0
                        ? Colors.black87
                        : Colors.black54,
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}