import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalai/app/routes/route.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/core/common/entitlement_helper.dart';
import 'package:medicalai/core/storage/hive_storage.dart';
import 'package:medicalai/features/splash/splashscreen1.dart';
import 'package:medicalai/features/subscription/SuccessScreen.dart';
import 'package:medicalai/features/subscription/payment_return.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const email = 'doctor@example.com';
  const planId = 'plan-1';
  const sessionId = 'cs_test_return';
  final link = Uri.parse('nourdoc://payment-success?session_id=$sessionId');
  final cancelLink = Uri.parse('nourdoc://payment-cancel?session_id=$sessionId');

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('payment_return_nav');
    PathProviderPlatform.instance = _FakePath(directory.path);
    await HiveStorage.init();
  });

  setUp(() async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) return;
      if (message.contains('Unable to load asset')) return;
      previous?.call(details);
    };
    PaymentReturn.instance.debugReset();
    await HiveStorage.setEmail(email);
    await HiveStorage.setToken('token-1');
    await HiveStorage.setName('Ada');
    await HiveStorage.clearPendingStripeCheckoutFor(email);
    await HiveStorage.savePendingStripeCheckout(
      doctorEmail: email,
      planId: planId,
      sessionId: sessionId,
    );
  });

  tearDown(() async {
    PaymentReturn.instance.debugReset();
    await HiveStorage.clearPendingStripeCheckoutFor(email);
  });

  testWidgets('cold start shows a check, then the receipt, and Back opens Packages', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    final key = await _pump(tester, observer, RouteNames.splash1);
    final gate = Completer<EntitlementRead>();
    PaymentReturn.instance.debugReadEntitlement = () => gate.future;
    final done = PaymentReturn.instance.onLink(link, coldStart: true);
    var foundProcessing = false;
    for (var i = 0; i < 15 && !foundProcessing; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      foundProcessing = find.text('Confirming your payment').evaluate().isNotEmpty;
    }
    if (!foundProcessing) {
      final types = tester.allWidgets.map((widget) => widget.runtimeType).take(50).join(', ');
      fail('processing screen was not shown: $types');
    }
    expect(find.text('Confirming your payment'), findsOneWidget);
    expect(find.text('Your transaction was Successful'), findsNothing);
    gate.complete(_usable());
    await _finish(tester, done);
    expect(_isCurrent(tester, find.byType(SuccessScreen)), isTrue);
    expect(_isCurrent(tester, find.text('Confirming your payment')), isFalse);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Ambient Clinical Intelligence'), findsNothing);
    expect(find.byType(SuccessScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpFor(tester, find.text('Packages'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Packages'), findsWidgets);
    expect(_isCurrent(tester, find.byType(SuccessScreen)), isFalse);
    expect(_isCurrent(tester, find.text('Confirming your payment')), isFalse);
    expect(observer.minDepth, greaterThan(0));
    expect(key.currentState, isNotNull);
  });

  testWidgets('warm return keeps the options screen under the receipt', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await _pump(tester, observer, 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    PaymentReturn.instance.debugReadEntitlement = () async => _usable();

    await _finish(tester, PaymentReturn.instance.onLink(link));
    await tester.pump();

    expect(find.byType(SuccessScreen), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(SuccessScreen),
      matching: find.byIcon(Icons.arrow_back_ios_new),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Payment options'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(find.text('Confirming your payment'), findsNothing);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('receipt Proceed opens the dashboard', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await _pump(tester, observer, 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    PaymentReturn.instance.debugReadEntitlement = () async => _usable();

    await _finish(tester, PaymentReturn.instance.onLink(link));
    await tester.pump();
    await tester.tap(find.text('Proceed to dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('cancelled checkout does not show the receipt', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await _pump(tester, observer, 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();

    final done = PaymentReturn.instance.onLink(cancelLink);
    await _letIoRun(tester);
    await _pumpFor(tester, find.text('Payment cancelled'));

    expect(find.text('Payment cancelled'), findsOneWidget);
    expect(find.text('This checkout was cancelled. No new plan was started.'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(find.text('Payment options'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await _finish(tester, done);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('a killed app can cancel without a receipt or an empty stack', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await _pump(tester, observer, RouteNames.splash1);

    final done = PaymentReturn.instance.onLink(cancelLink, coldStart: true);
    await _letIoRun(tester);
    await _pumpFor(tester, find.text('Payment cancelled'));

    expect(find.text('Payment cancelled'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(find.text('Packages'), findsWidgets);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await _finish(tester, done);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Get Started'), findsNothing);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('the same return link opens one receipt', (tester) async {
    await _phone(tester);
    await _pump(tester, _StackObserver(), 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    PaymentReturn.instance.debugReadEntitlement = () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return _usable();
    };

    final first = PaymentReturn.instance.onLink(link);
    final second = PaymentReturn.instance.onLink(link);
    await _finish(tester, Future.wait([first, second]));

    expect(find.byType(SuccessScreen), findsOneWidget);
  });

  testWidgets('resume during the check does not open a second receipt', (tester) async {
    await _phone(tester);
    await _pump(tester, _StackObserver(), 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    var reads = 0;
    PaymentReturn.instance.debugReadEntitlement = () async {
      reads += 1;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return _usable();
    };

    final done = PaymentReturn.instance.onLink(link);
    final recover = PaymentReturn.instance.recoverIfPending();
    await _finish(tester, Future.wait([done, recover]));

    expect(find.byType(SuccessScreen), findsOneWidget);
    expect(reads, greaterThan(0));
  });

  testWidgets('a failed check stays on the options screen', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await _pump(tester, observer, 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    PaymentReturn.instance.debugReadEntitlement = () async => EntitlementRead.network;

    final done = PaymentReturn.instance.onLink(link);
    await _letIoRun(tester);
    await _pumpFor(tester, find.text('Could not confirm payment'));

    expect(find.text('Could not confirm payment'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(find.text('Payment options'), findsOneWidget);
    expect(find.text('Confirming your payment'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pump();
    await _finish(tester, done);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('an unconfirmed plan does not show the receipt', (tester) async {
    await _phone(tester);
    await _pump(tester, _StackObserver(), 'home');
    await tester.tap(find.text('Open checkout'));
    await tester.pumpAndSettle();
    PaymentReturn.instance.debugReadEntitlement = () async => EntitlementRead.absent;

    final done = PaymentReturn.instance.onLink(link);
    await _letIoRun(tester);
    await _pumpFor(tester, find.text('Payment not confirmed'));

    expect(find.text('Payment not confirmed'), findsOneWidget);
    expect(find.byType(SuccessScreen), findsNothing);
    expect(find.text('Payment options'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump();
    await _finish(tester, done);
  });
}

Future<void> _letIoRun(WidgetTester tester) {
  return tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30))).then((_) {});
}

bool _isCurrent(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) return false;
  return ModalRoute.of(tester.element(finder))?.isCurrent ?? false;
}

Future<void> _finish(WidgetTester tester, Future<void> done) async {
  var pending = true;
  done.whenComplete(() => pending = false);
  for (var i = 0; i < 40 && pending; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await done.timeout(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

EntitlementRead _usable() {
  return EntitlementRead(
    EntitlementFetchResult.loaded,
    EntitlementSnapshot(
      kind: EntitlementKind.activePaid,
      planId: 'plan-1',
      planName: 'Starter',
      allocatedSeconds: 600,
      remainingSeconds: 600,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
  );
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<GlobalKey<NavigatorState>> _pump(
  WidgetTester tester,
  NavigatorObserver observer,
  String initial,
) async {
  final key = GlobalKey<NavigatorState>();
  PaymentReturn.instance.debugBindNavigator(key);
  await tester.pumpWidget(MaterialApp(
    navigatorKey: key,
    initialRoute: initial,
    navigatorObservers: [observer],
    onGenerateRoute: (settings) {
      if (settings.name == 'home') {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: 'checkout'),
                    builder: (_) => const Scaffold(body: Text('Payment options')),
                  ),
                ),
                child: const Text('Open checkout'),
              ),
            ),
          ),
        );
      }
      if (settings.name == RouteNames.dashboard) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('Dashboard')),
        );
      }
      if (settings.name == RouteNames.splash1) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SingleSplashScreen(),
        );
      }
      return Routes.generateRoute(settings);
    },
  ));
  await tester.pump();
  return key;
}

class _FakePath extends PathProviderPlatform {
  _FakePath(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _StackObserver extends NavigatorObserver {
  int depth = 0;
  int minDepth = 1;

  void _note() {
    if (depth < minDepth) minDepth = depth;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    depth += 1;
    _note();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    depth -= 1;
    _note();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    depth -= 1;
    _note();
  }
}
