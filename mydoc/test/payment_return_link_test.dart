import 'package:flutter_test/flutter_test.dart';
import 'package:medicalai/features/subscription/payment_return.dart';

void main() {
  group('Payment return links', () {
    test('accepts the payment success link', () {
      final link = PaymentReturnLink.tryParse(
        Uri.parse('nourdoc://payment-success?session_id=cs_test_123'),
      );

      expect(link, isNotNull);
      expect(link!.cancelled, isFalse);
      expect(link.sessionId, 'cs_test_123');
    });

    test('rejects a success link without a session', () {
      expect(
        PaymentReturnLink.tryParse(Uri.parse('nourdoc://payment-success')),
        isNull,
      );
      expect(
        PaymentReturnLink.tryParse(
          Uri.parse('nourdoc://payment-success?session_id='),
        ),
        isNull,
      );
    });

    test('accepts cancel with or without a session', () {
      final plain = PaymentReturnLink.tryParse(
        Uri.parse('nourdoc://payment-cancel'),
      );
      final withSession = PaymentReturnLink.tryParse(
        Uri.parse('nourdoc://payment-cancel?session_id=cs_test_123'),
      );

      expect(plain?.cancelled, isTrue);
      expect(plain?.sessionId, isNull);
      expect(withSession?.cancelled, isTrue);
      expect(withSession?.sessionId, 'cs_test_123');
    });

    test('rejects other schemes, hosts, and paths', () {
      expect(
        PaymentReturnLink.tryParse(Uri.parse('https://m3hive.com/payment-success?session_id=cs_test')),
        isNull,
      );
      expect(
        PaymentReturnLink.tryParse(Uri.parse('nourdoc://payment-success/extra?session_id=cs_test')),
        isNull,
      );
      expect(
        PaymentReturnLink.tryParse(Uri.parse('nourdoc://dashboard')),
        isNull,
      );
    });
  });
}
