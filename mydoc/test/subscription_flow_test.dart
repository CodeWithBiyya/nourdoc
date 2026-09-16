import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pricing & Entitlement Logic Tests', () {
    test('Robust status parser - active plan with remaining minutes', () {
      final Map<String, dynamic> mockStatusResponse = {
        "status": "active",
        "plan_name": "Trial",
        "remaining_minutes": 25,
      };

      final data = mockStatusResponse.containsKey('response')
          ? mockStatusResponse['response'] as Map<String, dynamic>
          : mockStatusResponse;

      final statusStr = data['status'] ?? '';
      final num remainingMinutes = data['remaining_minutes'] ?? 0;

      expect(statusStr, 'active');
      expect(remainingMinutes > 0, true);
    });

    test('Robust status parser - active plan with zero remaining minutes', () {
      final Map<String, dynamic> mockStatusResponse = {
        "response": {
          "status": "active",
          "plan_name": "Trial",
          "remaining_minutes": 0,
        }
      };

      final data = mockStatusResponse.containsKey('response')
          ? mockStatusResponse['response'] as Map<String, dynamic>
          : mockStatusResponse;

      final statusStr = data['status'] ?? '';
      final num remainingMinutes = data['remaining_minutes'] ?? 0;

      expect(statusStr, 'active');
      expect(remainingMinutes <= 0, true); // Should block recording
    });

    test('Robust start response parser - allowed (nested schema)', () {
      final Map<String, dynamic> mockStartResponse = {
        "allowed_response": {
          "allowed": true,
          "job_id": "job_123",
          "reserved_minutes": 20,
        }
      };

      bool allowed = false;
      if (mockStartResponse.containsKey('allowed_response') && mockStartResponse['allowed_response'] != null) {
        allowed = mockStartResponse['allowed_response']['allowed'] == true;
      }

      expect(allowed, true);
    });

    test('Robust start response parser - denied (nested schema)', () {
      final Map<String, dynamic> mockStartResponse = {
        "denied_response": {
          "allowed": false,
          "message": "You do not have enough available minutes for this consultation."
        }
      };

      bool allowed = true;
      String message = "";
      if (mockStartResponse.containsKey('denied_response') && mockStartResponse['denied_response'] != null) {
        allowed = mockStartResponse['denied_response']['allowed'] == true;
        message = mockStartResponse['denied_response']['message'];
      }

      expect(allowed, false);
      expect(message, "You do not have enough available minutes for this consultation.");
    });

    test('Robust start response parser - fallback (flat schema)', () {
      final Map<String, dynamic> mockStartResponse = {
        "allowed": true,
        "job_id": "job_123",
        "reserved_minutes": 20,
      };

      bool allowed = false;
      if (mockStartResponse.containsKey('allowed_response') && mockStartResponse['allowed_response'] != null) {
        allowed = mockStartResponse['allowed_response']['allowed'] == true;
      } else {
        allowed = mockStartResponse['allowed'] == true;
      }

      expect(allowed, true);
    });
  });
}
