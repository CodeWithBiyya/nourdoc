import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // needed again when Stripe is re-enabled
import 'package:app_links/app_links.dart';
import 'package:medicalai/utils/entitlement_helper.dart';
import '../../model/PlanModel.dart';
import '../Subscription_screens/SuccessScreen.dart';
import '../../utils/hive_storage.dart';
import '../../routes/routs_name.dart';
import '../../services/PlanRequestApiService.dart';
import '../../services/EntitlementApiService.dart';

class PaymentScreen extends StatefulWidget {
  final PlanModel selectedPlan;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.selectedPlan,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final TextEditingController cardController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // ============================================================
  // UI STATE
  // ============================================================

  bool isCreditCard = true;
  bool saveCard = false;
  bool isLoading = false;
  bool isConfirmingPayment = false;

  final Color primaryColor = const Color(0xFF255563);

  // ============================================================
  // SERVICES
  // ============================================================

  final PlanRequestApiService _planRequestApiService =
      PlanRequestApiService();

  final EntitlementApiService _entitlementApiService =
      EntitlementApiService();

  // ============================================================
  // DEEP LINK
  // ============================================================

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  // ============================================================
  // NAVIGATION HELPER
  // ============================================================

  void _goToDashboard() {
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
      (route) => false,
    );
  }

  // ============================================================
  // DEEP LINK INITIALIZATION
  // ============================================================

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // App was completely closed and launched through Stripe
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint('Initial payment deep link: $initialUri');
        await _handlePaymentCallback(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    // App was already running/backgrounded
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        debugPrint('Payment deep link received: $uri');
        await _handlePaymentCallback(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  // ============================================================
  // HANDLE STRIPE CALLBACK
  // ============================================================

  Future<void> _handlePaymentCallback(Uri uri) async {
    debugPrint('Payment callback received: $uri');

    if (uri.scheme != 'nourdoc') {
      debugPrint('Ignoring unknown scheme: ${uri.scheme}');
      return;
    }

    // PAYMENT CANCEL
    if (uri.host == 'payment-cancel') {
      final requestId = uri.queryParameters['request_id'];

      debugPrint('Payment cancelled. Request ID: $requestId');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled. You can try again.'),
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    // PAYMENT SUCCESS
    if (uri.host != 'payment-success') {
      debugPrint('Unknown payment callback host: ${uri.host}');
      return;
    }

    final requestId = uri.queryParameters['request_id'];
    final sessionId = uri.queryParameters['session_id'];

    debugPrint('Payment request ID: $requestId');
    debugPrint('Stripe session ID: $sessionId');

    // Stripe redirects the app while the webhook may still be
    // processing, so check the entitlement before showing success.
    await _confirmPayment(
      requestId: requestId,
      sessionId: sessionId,
    );
  }

  // ============================================================
  // CONFIRM PAYMENT
  // ============================================================

  Future<void> _confirmPayment({
    String? requestId,
    String? sessionId,
  }) async {
    if (isConfirmingPayment) return;
    if (!mounted) return;

    setState(() {
      isConfirmingPayment = true;
    });

    debugPrint('Confirming payment...');
    debugPrint('Request ID: $requestId');
    debugPrint('Session ID: $sessionId');

    try {
      final String? doctorId = HiveStorage.getUserEmail();

      if (doctorId == null || doctorId.isEmpty) {
        throw Exception('Doctor email not found. Please login again.');
      }

      debugPrint('Checking entitlement for doctor: $doctorId');

      for (int attempt = 1; attempt <= 4; attempt++) {
        debugPrint('Entitlement check attempt $attempt');

        try {
          final result = await _entitlementApiService.getEntitlementStatus(
            doctorId: doctorId,
          );

          debugPrint('Entitlement response: $result');

          // final status = result['status']?.toString().toLowerCase();
          // final upgradeRequired = result['upgrade_required'];

          // final bool active = status == 'active' && upgradeRequired != true;

                    final bool active = EntitlementHelper.isEnrolled(result);

          if (active) {
            debugPrint('ENTITLEMENT ACTIVE');

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  selectedPlan: widget.selectedPlan,
                  paymentMethod: widget.paymentMethod,
                  cardNumber: '****',
                ),
              ),
              (route) => false,
            );

            return;
          }

          debugPrint('Entitlement is not active yet.');
        } catch (e) {
          debugPrint('Entitlement check error: $e');
        }

        if (attempt < 4) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Webhook may still be processing
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment received. Your plan is still being activated. '
            'Please try again shortly.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Payment confirmation error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not confirm your payment yet: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isConfirmingPayment = false;
        });
      }
    }
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> _placeOrder() async {
    // Prevent duplicate requests
    if (isLoading) return;

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final String? doctorId = HiveStorage.getUserEmail();

      if (doctorId == null || doctorId.isEmpty) {
        throw Exception('Doctor is not logged in.');
      }

      debugPrint('Logged-in doctor: $doctorId');
      debugPrint('Selected plan: ${widget.selectedPlan.id}');

      // ----------------------------------------------------------
      // SUBSCRIBE TO PLAN
      // ----------------------------------------------------------

      final subscriptionResponse =
          await _planRequestApiService.subscribeToPlan(
        doctorId: doctorId,
        planId: widget.selectedPlan.id,
      );

      debugPrint('Subscription response: $subscriptionResponse');

      final entitlementId = subscriptionResponse['entitlement_id'];

      if (entitlementId == null) {
        throw Exception('Backend did not return entitlement ID.');
      }

      debugPrint('Entitlement ID: $entitlementId');

      // ----------------------------------------------------------
      // Entitlement exists -> doctor is enrolled -> Dashboard.
      //
      // NOTE: When Stripe checkout is re-enabled for paid plans,
      // open checkout here for paid plans instead of going straight
      // to the dashboard.
      // ----------------------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan activated successfully.')),
      );

      _goToDashboard();
      return;

      // ----------------------------------------------------------
      // STRIPE CHECKOUT (disabled for now)
      // ----------------------------------------------------------
      //
      // final checkoutUrl = await _planRequestApiService.createCheckout(
      //   planRequestId: requestId.toString(),
      //   doctorId: doctorId,
      //   successUrl: 'nourdoc://payment-success?request_id=$requestId',
      //   cancelUrl: 'nourdoc://payment-cancel?request_id=$requestId',
      // );
      //
      // final bool launched = await launchUrl(
      //   Uri.parse(checkoutUrl),
      //   mode: LaunchMode.externalApplication,
      // );
      //
      // if (!launched) {
      //   throw Exception('Could not open Stripe Checkout.');
      // }
    } catch (e) {
      // Backend says the doctor is already enrolled -> go to Dashboard
      if (e.toString().toLowerCase().contains('already has an active plan')) {
        debugPrint('Doctor already has an active plan -> Dashboard');
        _goToDashboard();
        return;
      }

      debugPrint('Payment error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _linkSubscription?.cancel();

    cardController.dispose();
    expiryController.dispose();
    cvvController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // TAB SWITCHER
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTab(
                      "Credit/Debit Card",
                      isCreditCard,
                      () => setState(() => isCreditCard = true),
                    ),
                    _buildTab(
                      "Bank Transfer/ Invoice\n(For Enterprise)",
                      !isCreditCard,
                      () => setState(() => isCreditCard = false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // CARD NUMBER
              _buildInputLabel("Card Number"),
              TextFormField(
                controller: cardController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.replaceAll(' ', '').length < 16) {
                    return "Enter 16 digit card number";
                  }
                  return null;
                },
                decoration: _inputDecoration("1234 5678 9000 0001"),
              ),

              const SizedBox(height: 20),

              // EXPIRY + CVV
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Expiry Date"),
                        TextFormField(
                          controller: expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            ExpiryDateInputFormatter(),
                          ],
                          validator: _validateExpiry,
                          decoration: _inputDecoration("MM/YY"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("CVV"),
                        TextFormField(
                          controller: cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return "Invalid";
                            }
                            return null;
                          },
                          decoration: _inputDecoration("718"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SAVE CARD
              Row(
                children: [
                  Checkbox(
                    value: saveCard,
                    activeColor: primaryColor,
                    onChanged: (value) {
                      setState(() {
                        saveCard = value ?? false;
                      });
                    },
                  ),
                  Text(
                    "Save Card Information",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // PLACE ORDER
              SizedBox(
                width: 180,
                height: 45,
                child: ElevatedButton(
                  onPressed:
                      isLoading || isConfirmingPayment ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Place Order",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // ============================================================
  // EXPIRY VALIDATION
  // ============================================================

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return "Required";
    }

    if (!RegExp(r'(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
      return "Use MM/YY format";
    }

    final components = value.split('/');
    final month = int.parse(components[0]);
    final year = int.parse("20${components[1]}");

    final now = DateTime.now();
    final expiryDate = DateTime(year, month);

    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return "Card has expired";
    }

    return null;
  }
}

// ================================================================
// CARD NUMBER FORMATTER (4-4-4-4)
// ================================================================

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');

    String newString = "";

    for (int i = 0; i < text.length; i++) {
      newString += text[i];

      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        newString += " ";
      }
    }

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

// ================================================================
// EXPIRY DATE FORMATTER (MM/YY)
// ================================================================

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    String newString = "";

    for (int i = 0; i < text.length; i++) {
      newString += text[i];

      if (i == 1 && text.length > 2) {
        newString += "/";
      }
    }

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}