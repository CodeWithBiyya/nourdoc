import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/PlanModel.dart';
import '../../app/routes/routs_name.dart';
import '../../core/repository/Repository.dart';
import '../../core/services/PlanRequestApiService.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/storage/hive_storage.dart';
import 'SuccessScreen.dart';
import 'subscription_guard.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  bool isCreditCard = true;
  bool saveCard = false;
  bool isLoading = false;

  static const Color primaryColor = Color(0xFF255563);

  final PlanRequestApiService _planRequestApiService = PlanRequestApiService();

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.dashboard,
      (route) => false,
    );
  }

  String? _entitlementId(Map<String, dynamic> body) {
    final source = body['response'] is Map
        ? Map<String, dynamic>.from(body['response'] as Map)
        : body;

    for (final key in ['entitlement_id', 'transaction_id', 'id']) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _doctorName() {
    final name = (HiveStorage.getName() ?? '').trim();
    if (name.isEmpty || name.toLowerCase() == 'null' || name == 'N/A') {
      return '';
    }
    return name;
  }

  Future<void> _placeOrder() async {
    if (isLoading) return;

    // Bank transfer has no backend checkout. It must not subscribe or
    // open a receipt. Card details are validated only for the card tab.
    if (!isCreditCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank Transfer is currently unavailable.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    if (await subscriptionBlocked(context) || !mounted) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final doctorId = (HiveStorage.getUserEmail() ?? '').trim();
    if (doctorId.isEmpty) {
      _showMessage('Doctor is not logged in.');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final result = await _planRequestApiService.subscribeToPlan(
      doctorId: doctorId,
      planId: widget.selectedPlan.id,
    );
    if (!mounted) return;

    if (!result.reachedServer) {
      _showMessage(result.message);
      setState(() => isLoading = false);
      return;
    }

    if (result.statusCode == 400) {
      await Repository().readDoctorEntitlement();
      if (!mounted) return;
      _showMessage(result.message);
      setState(() => isLoading = false);
      _goToDashboard();
      return;
    }

    if (!result.isSuccess || result.data == null) {
      _showMessage(result.message);
      setState(() => isLoading = false);
      return;
    }

    final entitlementId = _entitlementId(result.data!);
    if (entitlementId == null) {
      _showMessage('Backend did not return an entitlement id.');
      setState(() => isLoading = false);
      return;
    }

    // Previous success path opened the receipt from the subscribe id
    // without reading the entitlement again. A 400 called
    // _goToDashboard() with no refresh.
    final read = await Repository().readDoctorEntitlement();
    final confirmed = read.snapshot;
    final selectedName = widget.selectedPlan.planCode.toUpperCase();
    final matches = confirmed != null &&
        (confirmed.planId == widget.selectedPlan.id ||
            confirmed.planName.toUpperCase() == selectedName);

    // Receipt requires the refreshed plan to be the one just bought,
    // still before expires_at, and with remaining_seconds > 0.
    // An entitlement id alone is not enough.
    if (confirmed == null || !matches || !confirmed.canUseProtectedFeatures) {
      _showMessage(
        'Payment was sent, but the plan is not active yet. Check Plans before trying again.',
      );
      if (mounted) setState(() => isLoading = false);
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          selectedPlan: widget.selectedPlan,
          checkoutMethod: widget.paymentMethod,
          paymentLabel: isCreditCard ? 'Credit Card' : 'Bank Transfer',
          cardNumber: isCreditCard ? cardController.text : '',
          transactionId: entitlementId,
          doctorName: _doctorName(),
          expiresOn: confirmed.expiresAt == null
              ? ''
              : '${confirmed.expiresAt!.day}/${confirmed.expiresAt!.month}/${confirmed.expiresAt!.year}',
          remainingLabel: EntitlementHelper.formatSeconds(confirmed.remainingSeconds),
          includedLabel: EntitlementHelper.formatSeconds(confirmed.allocatedSeconds),
        ),
      ),
    );
    if (mounted) setState(() => isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  void dispose() {
    // _linkSubscription?.cancel();
    cardController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  /*
  Kept from the previous Payment screen. Not called.
  Place Order now opens SuccessScreen after POST /plans/subscribe.

  Imports this block used:
    import 'dart:async';
    import 'package:url_launcher/url_launcher.dart';
    import 'package:app_links/app_links.dart';
    import 'package:medicalai/core/common/entitlement_helper.dart';
    import '../../core/services/EntitlementApiService.dart';

  Fields this block used:
    bool isConfirmingPayment = false;
    final EntitlementApiService _entitlementApiService = EntitlementApiService();
    late final AppLinks _appLinks;
    StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

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

  After subscribe succeeded, the old Place Order showed a snackbar
  and opened the dashboard. Stripe checkout below it was already
  unreachable because of the return.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan activated successfully.')),
      );

      _goToDashboard();
      return;

      // STRIPE CHECKOUT (disabled for now)
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
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: primaryColor,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTab(
                      'Credit/Debit Card',
                      isCreditCard,
                      () => setState(() => isCreditCard = true),
                    ),
                    _buildTab(
                      'Bank Transfer/ Invoice\n(For Enterprise)',
                      !isCreditCard,
                      () => setState(() => isCreditCard = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (isCreditCard) ...[
                _buildInputLabel('Card Number'),
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
                      return 'Enter 16 digit card number';
                    }
                    return null;
                  },
                  decoration: _inputDecoration('1234 5678 9000 0001'),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Expiry Date'),
                          TextFormField(
                            controller: expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryDateInputFormatter(),
                            ],
                            validator: _validateExpiry,
                            decoration: _inputDecoration('MM/YY'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('CVV'),
                          TextFormField(
                            controller: cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            validator: (value) {
                              if (value == null || value.length < 3) return 'Invalid';
                              return null;
                            },
                            decoration: _inputDecoration('718'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: saveCard,
                      activeColor: primaryColor,
                      onChanged: (value) => setState(() => saveCard = value ?? false),
                    ),
                    Text(
                      'Save Card Information',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Bank Transfer is currently unavailable. Place Order will not start this plan.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 50),
              SizedBox(
                width: 180,
                height: 45,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
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

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (!RegExp(r'(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
      return 'Use MM/YY format';
    }

    final parts = value.split('/');
    final expiry = DateTime(int.parse('20${parts[1]}'), int.parse(parts[0]));
    final now = DateTime.now();
    if (expiry.isBefore(DateTime(now.year, now.month))) return 'Card has expired';
    return null;
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) buffer.write(' ');
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) buffer.write('/');
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
