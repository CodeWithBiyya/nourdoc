import 'package:flutter/material.dart';
import '../../core/models/PlanModel.dart';
import '../../core/repository/Repository.dart';
import '../../core/services/PlanRequestApiService.dart';
import '../../core/services/pricing_api_service.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/storage/hive_storage.dart';
import '../../app/routes/routs_name.dart';
import 'Checkout.dart';
import 'subscription_guard.dart';

class SubscriptionScreen1 extends StatefulWidget {
  const SubscriptionScreen1({super.key});

  @override
  State<SubscriptionScreen1> createState() => _SubscriptionScreen1State();
}

class _SubscriptionScreen1State extends State<SubscriptionScreen1> {
  int? expandedIndex;

  final Color primaryTeal = const Color(0xFF3FA3BA);

  final PricingApiService _pricingApiService = PricingApiService();

  List<PlanModel> allPlans = [];

  bool isLoading = true;
  String? errorMessage;
  EntitlementRead? entitlementRead;
  String? activatingPlanId;
  bool _planActionInFlight = false;

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
      return 'Plan active';
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
      final plans = await _pricingApiService.getPlans();
      final entitlement = await Repository().readDoctorEntitlement();

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
        errorMessage = e.toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: primaryTeal,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        title: const Text(
          "Packages",
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Current plan',
            icon: Icon(Icons.assignment_outlined, color: primaryTeal, size: 26),
            onPressed: () => Navigator.pushNamed(context, RouteNames.current_plan),
          ),
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              color: primaryTeal,
              size: 30,
            ),
            onPressed: () {
                 Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
      (route) => false,
    );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // =========================
      // BODY
      // =========================

      body: _buildBody(),
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
              color: Colors.red,
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
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        50,
      ),

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
                padding: EdgeInsets.only(
                  left: 35,
                  bottom: 20,
                  top: 10,
                ),
                child: Text(
                  "Enterprise Plan",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
    final bool isExpanded =
        expandedIndex == index;

    final bool isEnterprise =
        plan.planCode.toLowerCase().contains("enterprise");

    return Container(
      margin: const EdgeInsets.only(
        bottom: 35,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // Active subscription
          if (plan.isActive)
            Padding(
              padding: const EdgeInsets.only(
                left: 45,
                bottom: 5,
              ),

              child: Text(
                "Active (${plan.remainingMinutes ?? ""})",

                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Stack(
            clipBehavior: Clip.none,

            children: [

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // =========================
                  // NUMBER
                  // =========================

                  Padding(
                    padding: const EdgeInsets.only(
                      top: 15,
                      right: 10,
                    ),

                    child: Text(
                      "${index + 1}.",

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // =========================
                  // CARD
                  // =========================

                  Expanded(
                    child: Container(

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(15),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.1),

                            blurRadius: 8,

                            offset:
                                const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Material(
                        color: Colors.transparent,

                        child: InkWell(

                          borderRadius:
                              BorderRadius.circular(15),

                          onTap: () {
                            setState(() {
                              expandedIndex =
                                  isExpanded
                                      ? null
                                      : index;
                            });
                          },

                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(
                              12,
                              16,
                              12,
                              30,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                // =========================
                                // TITLE ROW
                                // =========================

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    Image.asset(
                                      plan.icon.toString(),

                                      width: 24,
                                      height: 24,

                                      errorBuilder:
                                          (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons
                                              .business_center,
                                          size: 24,
                                        );
                                      },
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    Expanded(
                                      child: Text(
                                        plan.displayTitle,

                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,

                                          fontSize: 15,

                                          color:
                                              Color(
                                            0xFF333333,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Icon(
                                      isExpanded
                                          ? Icons
                                              .keyboard_arrow_up
                                          : Icons
                                              .keyboard_arrow_down,

                                      size: 24,

                                      color:
                                          Colors.grey[600],
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                // =========================
                                // DESCRIPTION
                                // =========================

                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    left: 34,
                                  ),

                                  child: isEnterprise
                                      ? Text(
                                          plan.description,

                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                            height: 1.4,
                                          ),
                                        )
                                      : _buildFormattedDescription(
                                          plan.description,
                                        ),
                                ),

                                // =========================
                                // EXPANDED CONTENT
                                // =========================

                                // if (isExpanded) ...[
                                //   const Padding(
                                //     padding:
                                //         EdgeInsets.symmetric(
                                //       vertical: 10,
                                //     ),

                                //     child: Divider(),
                                //   ),

                                //   Text(
                                //     plan.detailTitle,

                                //     style:
                                //         const TextStyle(
                                //       fontWeight:
                                //           FontWeight.bold,
                                //       fontSize: 13,
                                //     ),
                                //   ),

                                //   const SizedBox(
                                //     height: 4,
                                //   ),

                                //   Text(
                                //     plan.detailContent
                                //             .isEmpty
                                //         ? "Plan details available soon."
                                //         : plan.detailContent,

                                //     style:
                                //         const TextStyle(
                                //       fontSize: 12,
                                //       color:
                                //           Colors.black54,
                                //       height: 1.5,
                                //     ),
                                //   ),
                                // ],

                                if (isExpanded) ...[
  const Padding(
    padding: EdgeInsets.symmetric(
      vertical: 10,
    ),
    child: Divider(),
  ),

  const Text(
    "Plan Details",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
    ),
  ),

  const SizedBox(height: 8),

  Text(
    "AI Minutes: ${plan.includedMinutes}",
    style: const TextStyle(
      fontSize: 12,
      color: Colors.black54,
    ),
  ),

  const SizedBox(height: 4),

  Text(
    "Validity: ${plan.expiryDays} days",
    style: const TextStyle(
      fontSize: 12,
      color: Colors.black54,
    ),
  ),

  const SizedBox(height: 4),

  Text(
    "Included Seconds: ${plan.includedSeconds}",
    style: const TextStyle(
      fontSize: 12,
      color: Colors.black54,
    ),
  ),
]
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // =================================================
              // FLOATING BUTTON
              // =================================================

              Positioned(
                bottom: -18,
                left: 0,
                right: 0,

                child: Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      _actionButton(
                        activatingPlanId == plan.id
                            ? 'Starting...'
                            : _buttonLabel(plan),
                        _purchaseBlocked(plan) ? Colors.grey : primaryTeal,
                        _purchaseBlocked(plan) ? null : () => _onPlanAction(plan),
                      ),

                      if (plan.isActive) ...[
                        const SizedBox(
                          width: 10,
                        ),

                        _actionButton(
                          "Renew",
                          _purchaseBlocked(plan) ? Colors.grey : primaryTeal,
                          _purchaseBlocked(plan)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Checkout(selectedPlan: plan),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
      return _statusCard(
        'No current plan. The server decides if a trial is still available. '
        'A trial does not ask for a card. A paid plan does.',
      );
    }

    final expiry = current.expiresAt;
    final expiryText = expiry == null
        ? ''
        : 'Expires ${expiry.day}-${_month(expiry.month)}-${expiry.year}. ';

    return _statusCard(
      '${current.statusLabel}. $expiryText'
      '${EntitlementHelper.formatSeconds(current.remainingSeconds)} left '
      'of ${EntitlementHelper.formatSeconds(current.allocatedSeconds)}.',
    );
  }

  String _month(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  Widget _statusCard(String text, {Widget? action}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
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
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: color,

          borderRadius:
              BorderRadius.circular(8),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.15),

              blurRadius: 4,

              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Text(
          label,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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