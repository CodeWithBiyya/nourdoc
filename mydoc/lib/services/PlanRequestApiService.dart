import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlanRequestApiService {
  static const String baseUrl =
      'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

  // =========================================================
  // CREATE PAID PLAN REQUEST
  // POST /plan-requests
  // =========================================================

  Future<Map<String, dynamic>> requestPaidPlan({
    required String doctorId,
    required String selectedPlanId,
    String doctorNotes = '',
  }) async {
    final url = Uri.parse(
      '$baseUrl/plan-requests',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'selected_plan_id': selectedPlanId,
        'doctor_notes': doctorNotes,
      }),
    );

    debugPrint(
      'Plan Request Status: ${response.statusCode}',
    );

    debugPrint(
      'Plan Request Response: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to request paid plan: '
        '${response.statusCode}',
      );
    }

    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  // =========================================================
  // CREATE PAYMENT CHECKOUT
  // POST /plan-requests/{id}/checkout
  // =========================================================

  Future<Map<String, dynamic>> createCheckout({
    required String planRequestId,
    required String doctorId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final url = Uri.parse(
      '$baseUrl/plan-requests/$planRequestId/checkout',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        successUrl: "https://example.com/payment-success",
cancelUrl: "https://example.com/payment-cancel",
      }),
    );

    debugPrint(
      'Checkout Status: ${response.statusCode}',
    );

    debugPrint(
      'Checkout Response: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to create checkout: '
        '${response.statusCode}',
      );
    }

    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }
}