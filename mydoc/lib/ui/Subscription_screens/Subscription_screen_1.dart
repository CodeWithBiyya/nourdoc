import 'package:flutter/material.dart';
import '../../model/PlanModel.dart';
import '../../services/Pricing_api_service.dart';
import 'Checkout.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _pricingApiService.getPlans();

      if (!mounted) return;

      setState(() {
        allPlans = plans;
        isLoading = false;
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
            icon: Icon(
              Icons.home_outlined,
              color: primaryTeal,
              size: 30,
            ),
            onPressed: () {},
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

      itemCount: allPlans.length,

      itemBuilder: (context, index) {
        final plan = allPlans[index];

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
                        plan.planCode.toLowerCase() == "enterprise"
    ? "Talk to us"
    : "Proceed with ${plan.formattedPrice}",

                        primaryTeal,

                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Checkout(
                                selectedPlan: plan,
                              ),
                            ),
                          );
                        },
                      ),

                      if (plan.isActive) ...[
                        const SizedBox(
                          width: 10,
                        ),

                        _actionButton(
                          "Renew",
                          primaryTeal,

                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Checkout(
                                  selectedPlan:
                                      plan,
                                ),
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

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback onTap,
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