// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// class PlanRequestApiService {
//   static const String baseUrl =
//       'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

//   // =========================================================
//   // CREATE PAID PLAN REQUEST
//   // POST /plan-requests
//   // =========================================================

//   Future<Map<String, dynamic>> requestPaidPlan({
//     required String doctorId,
//     required String selectedPlanId,
//     String doctorNotes = '',
//   }) async {
//     final url = Uri.parse(
//       '$baseUrl/plan-requests',
//     );

//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'doctor_id': doctorId,
//         'selected_plan_id': selectedPlanId,
//         'doctor_notes': doctorNotes,
//       }),
//     );

//     debugPrint(
//       'Plan Request Status: ${response.statusCode}',
//     );

//     debugPrint(
//       'Plan Request Response: ${response.body}',
//     );

//     if (response.statusCode < 200 ||
//         response.statusCode >= 300) {
//       throw Exception(
//         'Failed to request paid plan: '
//         '${response.statusCode}',
//       );
//     }

//     if (response.body.isEmpty) {
//       return {};
//     }

//     final decoded = jsonDecode(response.body);

//     if (decoded is Map<String, dynamic>) {
//       return decoded;
//     }

//     return {};
//   }

//   // =========================================================
//   // CREATE PAYMENT CHECKOUT
//   // POST /plan-requests/{id}/checkout
//   // =========================================================

// //   Future<Map<String, dynamic>> createCheckout({
// //     required String planRequestId,
// //     required String doctorId,
// //     required String successUrl,
// //     required String cancelUrl,
// //   }) async {
// //     final url = Uri.parse(
// //       '$baseUrl/plan-requests/$planRequestId/checkout',
// //     );

// //     final response = await http.post(
// //       url,
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Accept': 'application/json',
// //       },
// //       body: jsonEncode({
// //         'doctor_id': doctorId,
// //         successUrl: "https://example.com/payment-success",
// // cancelUrl: "https://example.com/payment-cancel",
// //       }),
// //     );

// //     debugPrint(
// //       'Checkout Status: ${response.statusCode}',
// //     );

// //     debugPrint(
// //       'Checkout Response: ${response.body}',
// //     );

// //     if (response.statusCode < 200 ||
// //         response.statusCode >= 300) {
// //       throw Exception(
// //         'Failed to create checkout: '
// //         '${response.statusCode}',
// //       );
// //     }

// //     if (response.body.isEmpty) {
// //       return {};
// //     }

// //     final decoded = jsonDecode(response.body);

// //     if (decoded is Map<String, dynamic>) {
// //       return decoded;
// //     }

// //     return {};
// //   }

// Future<String> createCheckout({
//   required String planRequestId,
//   required String doctorId,
//   required String successUrl,
//   required String cancelUrl,
// }) async {
//   final url = Uri.parse(
//     '$baseUrl/plan-requests/$planRequestId/checkout',
//   );

//   final response = await http.post(
//     url,
//     headers: {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     },
//     body: jsonEncode({
//       'doctor_id': doctorId,
//       'success_url': successUrl,
//       'cancel_url': cancelUrl,
//     }),
//   );

//   debugPrint("Checkout status: ${response.statusCode}");
//   debugPrint("Checkout response: ${response.body}");

//   if (response.statusCode < 200 ||
//       response.statusCode >= 300) {
//     throw Exception(
//       "Failed to create checkout: "
//       "${response.statusCode} ${response.body}",
//     );
//   }

//   final decoded = jsonDecode(response.body);

//   if (decoded is! Map<String, dynamic>) {
//     throw Exception("Invalid checkout response");
//   }

//   final checkoutUrl =
//       decoded['checkout_url'] ??
//       decoded['url'] ??
//       decoded['session_url'];

//   if (checkoutUrl == null ||
//       checkoutUrl.toString().isEmpty) {
//     throw Exception(
//       "Checkout URL was not returned by backend.\n"
//       "Response: ${response.body}",
//     );
//   }

//   return checkoutUrl.toString();
// }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_url.dart';

class PlanRequestApiService {
  static const String baseUrl =
      'https://8wfvyjajy1.execute-api.us-east-1.amazonaws.com';

  // =========================================================
  // CREATE PAID PLAN REQUEST
  // POST /plan-requests
  // =========================================================
  

  // Future<Map<String, dynamic>> requestPaidPlan({
  //   required String doctorId,
  //   required String selectedPlanId,
  //   String doctorNotes = '',
  // }) async {
  //   final url = Uri.parse('$baseUrl/plan-requests');

  //   debugPrint('==========================================');
  //   debugPrint('CREATE PLAN REQUEST');
  //   debugPrint('URL: $url');
  //   debugPrint('Doctor ID: $doctorId');
  //   debugPrint('Selected Plan ID: $selectedPlanId');
  //   debugPrint('==========================================');

  //   final response = await http.post(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Accept': 'application/json',
  //     },
  //     body: jsonEncode({
  //       'doctor_id': doctorId,
  //       'selected_plan_id': selectedPlanId,
  //       'doctor_notes': doctorNotes,
  //     }),
  //   );

  //   debugPrint('Plan Request Status: ${response.statusCode}');
  //   debugPrint('Plan Request Response: ${response.body}');

  //   if (response.statusCode < 200 ||
  //       response.statusCode >= 300) {
  //     throw Exception(
  //       'Failed to request paid plan: '
  //       '${response.statusCode}\n'
  //       '${response.body}',
  //     );
  //   }

  //   if (response.body.trim().isEmpty) {
  //     return {};
  //   }

  //   final decoded = jsonDecode(response.body);

  //   if (decoded is Map<String, dynamic>) {
  //     return decoded;
  //   }

  //   throw Exception(
  //     'Invalid plan request response:\n${response.body}',
  //   );
  // }

Future<Map<String, dynamic>> subscribeToPlan({
  required String doctorId,
  required String planId,
}) async {
  final url = Uri.parse(
    '$baseUrl/plans/subscribe/$doctorId',
  );

  debugPrint('==========================================');
  debugPrint('SUBSCRIBE TO PLAN');
  debugPrint('URL: $url');
  debugPrint('Doctor ID: $doctorId');
  debugPrint('Plan ID: $planId');
  debugPrint('==========================================');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'plan_id': planId,
    }),
  );

  debugPrint('Subscribe Status: ${response.statusCode}');
  debugPrint('Subscribe Response: ${response.body}');

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(
      'Failed to subscribe: '
      '${response.statusCode}\n'
      '${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  throw Exception(
    'Invalid subscription response: ${response.body}',
  );
}
  // =========================================================
  // CREATE STRIPE CHECKOUT
  // POST /plan-requests/{id}/checkout
  // =========================================================

  Future<String> createCheckout({
    required String planRequestId,
    required String doctorId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final url = Uri.parse(
      '$baseUrl/plan-requests/$planRequestId/checkout',
    );

    debugPrint('==========================================');
    debugPrint('CREATE STRIPE CHECKOUT');
    debugPrint('URL: $url');
    debugPrint('Plan Request ID: $planRequestId');
    debugPrint('Doctor ID: $doctorId');
    debugPrint('Success URL: $successUrl');
    debugPrint('Cancel URL: $cancelUrl');
    debugPrint('==========================================');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      }),
    );

    debugPrint('Checkout Status: ${response.statusCode}');
    debugPrint('Checkout Response: ${response.body}');

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to create checkout: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      throw Exception(
        'Checkout API returned an empty response.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid checkout response:\n${response.body}',
      );
    }

    // Support possible backend response field names.
    final checkoutUrl =
        decoded['checkout_url'] ??
        decoded['url'] ??
        decoded['session_url'];

    if (checkoutUrl == null ||
        checkoutUrl.toString().trim().isEmpty) {
      throw Exception(
        'Checkout URL was not returned by backend.\n'
        'Response: ${response.body}',
      );
    }

    debugPrint(
      'Stripe Checkout URL: $checkoutUrl',
    );

    return checkoutUrl.toString();
  }
}