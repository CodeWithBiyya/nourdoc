import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/PlanModel.dart';
import '../../routes/routs_name.dart';

class SuccessScreen extends StatelessWidget {
  final PlanModel selectedPlan;
  final String paymentMethod;
  final String cardNumber;

  const SuccessScreen({
    super.key,
    required this.selectedPlan,
    required this.paymentMethod,
    required this.cardNumber,
  });

  final Color primaryColor = const Color(0xFF255563);
  final Color receiptBg = const Color(0xFFF5E6E6);

  String _getPaymentIcon(String method) {
    switch (method) {
      case "Google Pay": return "assets/icons/Googlepay.png";
      case "Apple Pay": return "assets/icons/Applepay.png";
      case "JazzCash": return "assets/icons/jazzcash.png";
      case "EasyPaisa": return "assets/icons/easypaisy.png";
      case "Online Bank Transfer": return "assets/icons/bank.png";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());
    String transactionId = "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    String maskedCard = cardNumber.length > 4
        ? "**** **** **** ${cardNumber.substring(cardNumber.length - 4)}"
        : cardNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Payment", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: receiptBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 15),
                  const Text("Thank You!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Your transaction was Successful", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        _tableRow("Date", currentDate),
                        const Divider(),
                        _tableRow("Time", currentTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Align(alignment: Alignment.centerLeft, child: Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        _summaryRow("Plan", selectedPlan.displayTitle),
                        _summaryRow("Amount Paid", selectedPlan.formattedPrice),
                        _summaryRow("Transaction id", transactionId),
                        _summaryRow("Payment Method", paymentMethod),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Image.asset(
                          _getPaymentIcon(paymentMethod),
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.credit_card, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(maskedCard, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- UPDATED: LOCAL ASSET BARCODE ---
                  Column(
                    children: [
                      Image.asset(
                        "assets/icons/barcode.png",
                        height: 60,
                        width: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      const Text("0001 9889 8765 4321 06", style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
  Navigator.pushNamedAndRemoveUntil(
    context,
      RouteNames.dashboard,
    (route) => false,
  );
},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: primaryColor, width: 1),
                  ),
                ),
                child: const Text(
                  "Proceed to dashboard",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}