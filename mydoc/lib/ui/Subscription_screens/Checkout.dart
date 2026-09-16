// import 'package:flutter/material.dart';
// import '../../model/PlanModel.dart';
// import 'PaymentScreen.dart';

// class Checkout extends StatefulWidget {
//   final PlanModel selectedPlan;

//   const Checkout({super.key, required this.selectedPlan});

//   @override
//   State<Checkout> createState() => _CheckoutState();
// }

// class _CheckoutState extends State<Checkout> {
//   bool isAnnualDiscount = false;
//   String selectedMethod = "Google Pay";
//   final Color primaryColor = const Color(0xFF255563);

//   @override
//   Widget build(BuildContext context) {
//     final plan = widget.selectedPlan;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: primaryColor, size: 22),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Checkout", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),

//             // --- DYNAMIC Order Summary Card ---
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Order Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 15),
//                   Row(
//                     children: [
//                       // FIXED: Using Image.asset for Plan Icon instead of Icon() widget
//                       Image.asset(
//                         plan.icon.toString(),
//                         width: 40,
//                         height: 40,
//                         errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, size: 40),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               plan.title,
//                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                             ),
//                             Text(
//                               plan.description,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Text(
//                         "Price: ${plan.price}",
//                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 30),
//                   Row(
//                     children: [
//                       SizedBox(
//                         height: 24,
//                         child: Switch(
//                           value: isAnnualDiscount,
//                           activeColor: primaryColor,
//                           onChanged: (val) => setState(() => isAnnualDiscount = val),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       const Expanded(
//                         child: Text(
//                           "Add Annual Pre pay discount\n(Save \$180/Year)",
//                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//             const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             Text("Choose the payment method you would like to use.", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//             const SizedBox(height: 20),

//             // CHANGED: Passing asset paths instead of IconData
//             _paymentOption("Google Pay", "assets/icons/Googlepay.png"),
//             _paymentOption("Apple Pay", "assets/icons/Applepay.png"),
//             _paymentOption("JazzCash", "assets/icons/jazzcash.png"),
//             _paymentOption("EasyPaisa", "assets/icons/easypaisy.png"),
//             _paymentOption("Online Bank Transfer", "assets/icons/bank.png"),

//             const SizedBox(height: 15),
//             _addNewCardButton(),
//             const SizedBox(height: 40),
//             _proceedButton(),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _addNewCardButton() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(color: const Color(0xFFF5E6E6), borderRadius: BorderRadius.circular(10)),
//       child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add, size: 16),
//             SizedBox(width: 8),
//             Text("Add New Card", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
//           ]
//       ),
//     );
//   }

//   Widget _proceedButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 45,
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PaymentScreen(
//                 selectedPlan: widget.selectedPlan,
//                 paymentMethod: selectedMethod,
//               ),
//             ),
//           );
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: const Text(
//           "Proceed",
//           style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   // Updated helper to use Image.asset
//   Widget _paymentOption(String title, String assetPath) {
//     bool isSelected = selectedMethod == title;
//     return GestureDetector(
//       onTap: () => setState(() => selectedMethod = title),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
//         ),
//         child: Row(
//           children: [
//             // FIXED: Using Image.asset for Payment Icons
//             Image.asset(
//               assetPath,
//               width: 24,
//               height: 24,
//               errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment_outlined, size: 24),
//             ),
//             const SizedBox(width: 15),
//             Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
//             const Spacer(),
//             if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 18),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../model/PlanModel.dart';
import 'PaymentScreen.dart';

class Checkout extends StatefulWidget {
  final PlanModel selectedPlan;

  const Checkout({
    super.key,
    required this.selectedPlan,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  bool isAnnualDiscount = false;
  String selectedMethod = "Google Pay";

  final Color primaryColor =
      const Color(0xFF255563);

  @override
  Widget build(BuildContext context) {
    final plan = widget.selectedPlan;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: primaryColor,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            // =================================================
            // ORDER SUMMARY
            // =================================================

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(15),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Order Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Image.asset(
                        plan.icon,
                        width: 40,
                        height: 40,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons.payment,
                            size: 40,
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              plan.displayTitle,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              plan.description,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,

                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        plan.formattedPrice,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(
                    height: 30,
                  ),

                  // =================================================
                  // ANNUAL DISCOUNT
                  // =================================================

                  Row(
                    children: [
                      SizedBox(
                        height: 24,

                        child: Switch(
                          value:
                              isAnnualDiscount,

                          activeColor:
                              primaryColor,

                          onChanged: (value) {
                            setState(() {
                              isAnnualDiscount =
                                  value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          "Add Annual Pre pay discount\n"
                          "(Save \$180/Year)",

                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Choose the payment method you would like to use.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 20),

            _paymentOption(
              "Google Pay",
              "assets/icons/Googlepay.png",
            ),

            _paymentOption(
              "Apple Pay",
              "assets/icons/Applepay.png",
            ),

            _paymentOption(
              "JazzCash",
              "assets/icons/jazzcash.png",
            ),

            _paymentOption(
              "EasyPaisa",
              "assets/icons/easypaisy.png",
            ),

            _paymentOption(
              "Online Bank Transfer",
              "assets/icons/bank.png",
            ),

            const SizedBox(height: 15),

            _addNewCardButton(),

            const SizedBox(height: 40),

            _proceedButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ADD NEW CARD
  // =========================================================

  Widget _addNewCardButton() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF5E6E6),
        borderRadius:
            BorderRadius.circular(10),
      ),

      child: const Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.add,
            size: 16,
          ),

          SizedBox(width: 8),

          Text(
            "Add New Card",
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROCEED
  // =========================================================

  Widget _proceedButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,

      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) =>
                  PaymentScreen(
                selectedPlan:
                    widget.selectedPlan,

                paymentMethod:
                    selectedMethod,
              ),
            ),
          );
        },

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              primaryColor,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),

        child: const Text(
          "Proceed",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PAYMENT OPTION
  // =========================================================

  Widget _paymentOption(
    String title,
    String assetPath,
  ) {
    final bool isSelected =
        selectedMethod == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = title;
        });
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade200,

            width:
                isSelected ? 2 : 1,
          ),
        ),

        child: Row(
          children: [
            Image.asset(
              assetPath,
              width: 24,
              height: 24,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.payment_outlined,
                  size: 24,
                );
              },
            ),

            const SizedBox(width: 15),

            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            const Spacer(),

            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}