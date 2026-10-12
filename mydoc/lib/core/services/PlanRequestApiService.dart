import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_url.dart';

class PlanRequestApiService {
  static const String baseUrl =
      'https://8wfvyjajy1.execute-api.us-east-1.amazonaws.com';


  
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