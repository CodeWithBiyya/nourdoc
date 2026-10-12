import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/PlanModel.dart';
import '../../app/routes/routs_name.dart';

class SuccessScreen extends StatelessWidget {
  final PlanModel selectedPlan;
  final String checkoutMethod;
  final String paymentLabel;
  final String cardNumber;
  final String transactionId;
  final String doctorName;
  final String expiresOn;
  final String remainingLabel;
  final String includedLabel;

  const SuccessScreen({
    super.key,
    required this.selectedPlan,
    required this.checkoutMethod,
    required this.paymentLabel,
    required this.cardNumber,
    required this.transactionId,
    required this.doctorName,
    this.expiresOn = '',
    this.remainingLabel = '',
    this.includedLabel = '',
  });

  static const Color primaryColor = Color(0xFF255563);
  static const Color receiptBg = Color(0xFFF5E6E6);

  String get _greeting {
    final name = doctorName.trim();
    if (name.isEmpty || name.toLowerCase() == 'null' || name == 'N/A') {
      return 'Thank You!';
    }
    final titled = name.toLowerCase().startsWith('dr') ? name : 'Dr $name';
    return 'Thank You $titled!';
  }

  String get _maskedCard {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return '';
    final first = digits.substring(0, 4);
    final last = digits.substring(digits.length - 4);
    return '$first **** **** $last';
  }

  String _methodIcon(String method) {
    switch (method) {
      case 'Google Pay':
        return 'assets/icons/Googlepay.png';
      case 'Apple Pay':
        return 'assets/icons/Applepay.png';
      case 'JazzCash':
        return 'assets/icons/jazzcash.png';
      case 'EasyPaisa':
        return 'assets/icons/easypaisy.png';
      case 'Online Bank Transfer':
      case 'Bank Transfer':
        return 'assets/icons/bank.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentDate = DateFormat('dd/MM/yyyy').format(now);
    final currentTime = DateFormat('hh:mm a').format(now);
    // Previous receipt built these locally instead of using the subscribe response:
    // String transactionId = "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    // String maskedCard = cardNumber.length > 4
    //     ? "**** **** **** ${cardNumber.substring(cardNumber.length - 4)}"
    //     : cardNumber;
    // Heading was a fixed "Thank You!" with no doctor name.
    final methodForRow = paymentLabel == 'Bank Transfer'
        ? 'Online Bank Transfer'
        : checkoutMethod;
    final maskedCard = _maskedCard;

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
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: receiptBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 15),
                  Text(_greeting, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Your transaction was Successful', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        _tableRow('Date', currentDate),
                        const Divider(),
                        _tableRow('Time', currentTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        _summaryRow('Plan', selectedPlan.displayTitle),
                        _summaryRow('Amount Paid', selectedPlan.formattedPrice),
                        _summaryRow('Transaction id', transactionId),
                        _summaryRow('Payment Method', paymentLabel),
                        if (expiresOn.isNotEmpty) _summaryRow('Expires', expiresOn),
                        if (includedLabel.isNotEmpty) _summaryRow('Included time', includedLabel),
                        if (remainingLabel.isNotEmpty) _summaryRow('Time left', remainingLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        _methodIcon(methodForRow).isEmpty
                            ? const Icon(Icons.credit_card, size: 22)
                            : Image.asset(
                                _methodIcon(methodForRow),
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.credit_card, size: 20),
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            methodForRow,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (maskedCard.isNotEmpty)
                          Text(maskedCard, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  // Previous receipt also drew a static barcode under the summary:
                  // const SizedBox(height: 30),
                  // Column(
                  //   children: [
                  //     Image.asset(
                  //       "assets/icons/barcode.png",
                  //       height: 60,
                  //       width: 220,
                  //       fit: BoxFit.contain,
                  //       errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 50, color: Colors.grey),
                  //     ),
                  //     const SizedBox(height: 5),
                  //     const Text("0001 9889 8765 4321 06", style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.black54)),
                  //   ],
                  // ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Proceed to dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
