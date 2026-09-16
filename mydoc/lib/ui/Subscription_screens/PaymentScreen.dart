import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../model/PlanModel.dart';
import '../Subscription_screens/SuccessScreen.dart';
import '../../utils/hive_storage.dart';
import '../../services/PlanRequestApiService.dart';


class PaymentScreen extends StatefulWidget {
  final PlanModel selectedPlan;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.selectedPlan,
    required this.paymentMethod
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
  final Color primaryColor = const Color(0xFF255563);

  final PlanRequestApiService _planRequestApiService =
    PlanRequestApiService();

bool isLoading = false;

  // --- Expiry Date Validation Logic ---
  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) return "Required";
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

  Future<void> _placeOrder() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    // ---------------------------------------------------------
    // IMPORTANT:
    // Replace this with the actual logged-in doctor's ID
    // from your existing HiveStorage/authentication code.
    // ---------------------------------------------------------

   final String doctorId =
    HiveStorage.getUserEmail() ?? "default_doctor_id";

debugPrint("Logged-in Doctor ID: $doctorId");

    // ---------------------------------------------------------
    // STEP 1: CREATE PLAN REQUEST
    // ---------------------------------------------------------

    final planRequest =
        await _planRequestApiService.requestPaidPlan(
      doctorId: doctorId,

      // Backend expects values like:
      // starter
      // growth
      // professional
      // enterprise
      selectedPlanId:
          widget.selectedPlan.planCode,

      doctorNotes:
          "I want to continue with this plan.",
    );

    debugPrint(
      "Created Plan Request: $planRequest",
    );

    // ---------------------------------------------------------
    // GET PLAN REQUEST ID
    // ---------------------------------------------------------

    final dynamic requestId =
        planRequest['id'] ??
        planRequest['plan_request_id'] ??
        planRequest['request_id'];

    if (requestId == null) {
      throw Exception(
        "Plan request ID was not returned by the API.",
      );
    }

    debugPrint(
      "Plan Request ID: $requestId",
    );

    // ---------------------------------------------------------
    // STEP 2: CREATE PAYMENT CHECKOUT
    // ---------------------------------------------------------

    final checkoutResponse =
        await _planRequestApiService.createCheckout(
      planRequestId:
          requestId.toString(),

      doctorId: doctorId,

      successUrl:
          "https://example.com/payment-success",

      cancelUrl:
          "https://example.com/payment-cancel",
    );

    debugPrint(
      "Checkout Response: $checkoutResponse",
    );

    // ---------------------------------------------------------
    // TEMPORARY:
    // Show response instead of falsely saying payment succeeded.
    // ---------------------------------------------------------

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "Checkout created successfully.",
        ),
      ),
    );

    debugPrint(
      "IMPORTANT CHECKOUT RESPONSE: "
      "$checkoutResponse",
    );

  } catch (e) {
    debugPrint(
      "Place Order Error: $e",
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "Payment error: $e",
        ),
      ),
    );
  }
}


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
        title: const Text("Payment", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Tab Switcher
              Container(
                height: 55,
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    _buildTab("Credit/Debit Card", isCreditCard, () => setState(() => isCreditCard = true)),
                    _buildTab("Bank Transfer/ Invoice\n(For Enterprise)", !isCreditCard, () => setState(() => isCreditCard = false)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Card Number with Formatter
              _buildInputLabel("Card Number"),
              TextFormField(
                controller: cardController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberInputFormatter(), // Custom Formatter niche define hai
                ],
                validator: (v) => v!.replaceAll(' ', '').length < 16 ? "Enter 16 digit card number" : null,
                decoration: _inputDecoration("1234 5678 9000 0001"),
              ),

              const SizedBox(height: 20),
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          validator: (v) => v!.length < 3 ? "Invalid" : null,
                          decoration: _inputDecoration("718"),
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
                    onChanged: (val) => setState(() => saveCard = val!),
                  ),
                  Text("Save Card Information", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 50),

              SizedBox(
                width: 180,
                height: 45,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("Place Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? primaryColor : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}

// --- Card Number Formatter (4-4-4-4) ---
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    var newString = "";
    for (int i = 0; i < text.length; i++) {
      newString += text[i];
      if ((i + 1) % 4 == 0 && i != text.length - 1) newString += " ";
    }
    return newValue.copyWith(text: newString, selection: TextSelection.collapsed(offset: newString.length));
  }
}

// --- Expiry Date Formatter (MM/YY) ---
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    var newString = "";
    for (int i = 0; i < text.length; i++) {
      newString += text[i];
      if (i == 1 && text.length > 2) newString += "/";
    }
    return newValue.copyWith(text: newString, selection: TextSelection.collapsed(offset: newString.length));
  }
}