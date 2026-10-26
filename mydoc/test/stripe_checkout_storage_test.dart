import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medicalai/core/common/appDialog.dart';
import 'package:medicalai/core/common/entitlement_helper.dart';
import 'package:medicalai/core/storage/hive_storage.dart';

void main() {
  group('Stripe checkout storage', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nourdoc_stripe_test');
      Hive.init(directory.path);
      final box = await Hive.openBox('stripe_checkout_recovery');
      HiveStorage.debugBindStripeBox(box);
    });

    tearDown(() async {
      await Hive.close();
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    test('keeps a checkout with its doctor and ignores another doctor', () async {
      await HiveStorage.savePendingStripeCheckout(
        doctorEmail: 'doctor.a@example.com',
        planId: 'plan-starter',
        sessionId: 'cs_a',
      );

      expect(HiveStorage.pendingForDoctor('doctor.b@example.com'), isNull);
      final pending = HiveStorage.pendingForDoctor('Doctor.A@example.com');
      expect(pending?.planId, 'plan-starter');
      expect(pending?.sessionId, 'cs_a');
      expect(pending?.doctorEmail, 'doctor.a@example.com');
    });

    test('does not treat a legacy row without a doctor as this doctor', () async {
      final box = Hive.box('stripe_checkout_recovery');
      await box.put('stripe_pending_plan_id', 'plan-starter');
      await box.put('stripe_pending_session_id', 'cs_old');

      expect(HiveStorage.pendingForDoctor('doctor.a@example.com'), isNull);
    });

    test('clearing one doctor leaves the other checkout stored', () async {
      await HiveStorage.savePendingStripeCheckout(
        doctorEmail: 'doctor.a@example.com',
        planId: 'plan-a',
        sessionId: 'cs_a',
      );
      await HiveStorage.savePendingStripeCheckout(
        doctorEmail: 'doctor.b@example.com',
        planId: 'plan-b',
        sessionId: 'cs_b',
      );

      await HiveStorage.clearPendingStripeCheckoutFor('doctor.a@example.com');

      expect(HiveStorage.pendingForDoctor('doctor.a@example.com'), isNull);
      expect(HiveStorage.pendingForDoctor('doctor.b@example.com')?.planId, 'plan-b');
    });
  });

  test('account change drops the displayed plan', () {
    EntitlementHelper.display.value = const EntitlementSnapshot(
      kind: EntitlementKind.activePaid,
      planId: 'plan-starter',
      planName: 'Starter',
    );
    final generation = EntitlementHelper.accountGeneration;

    EntitlementHelper.noteAccountChanged();

    expect(EntitlementHelper.accountGeneration, generation + 1);
    expect(EntitlementHelper.display.value, isNull);
  });

  testWidgets('system back closes only the payment dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showAppDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  closeOnSystemBack: false,
                  title: 'Payment not confirmed',
                  content: 'Nothing was changed.',
                  primaryText: 'OK',
                  onPrimary: () => Navigator.pop(context),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Payment not confirmed'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Payment not confirmed'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
