import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/core/models/PlanModel.dart';
import 'package:medicalai/core/storage/hive_storage.dart';
import 'package:medicalai/features/subscription/Subscription_screen_1.dart';
import 'package:medicalai/features/subscription/SuccessScreen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('packages_receipt_back');
    PathProviderPlatform.instance = _FakePath(directory.path);
    await HiveStorage.init();
  });

  setUp(() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) return;
      if (message.contains('Unable to load asset')) return;
      previous?.call(details);
    };
  });

  testWidgets('root Packages, receipt, then Back stays on Packages', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await tester.pumpWidget(_app(initial: RouteNames.subscription_screen, observer: observer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Packages'), findsWidgets);
    await _openReceipt(tester);
    await tester.tap(_receiptBack());
    await tester.pumpAndSettle();

    expect(find.text('Packages'), findsWidgets);
    expect(find.text('Your transaction was Successful'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Exit the app?'), findsOneWidget);
    expect(find.text('Packages'), findsWidgets);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('Packages opened from home, receipt Back, then Packages Back', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await tester.pumpWidget(_app(initial: 'home', observer: observer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open packages'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await _openReceipt(tester);

    await tester.tap(_receiptBack());
    await tester.pumpAndSettle();
    expect(find.text('Packages'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Exit the app?'), findsNothing);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('receipt Proceed opens the dashboard', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await tester.pumpWidget(_app(initial: RouteNames.subscription_screen, observer: observer));
    await tester.pump();
    await _openReceipt(tester);

    await tester.tap(find.text('Proceed to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Your transaction was Successful'), findsNothing);
    expect(observer.minDepth, greaterThan(0));
  });

  testWidgets('Packages Back at the root asks to exit and keeps a route', (tester) async {
    await _phone(tester);
    final observer = _StackObserver();
    await tester.pumpWidget(_app(initial: RouteNames.subscription_screen, observer: observer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
    await tester.pumpAndSettle();

    expect(find.text('Exit the app?'), findsOneWidget);
    expect(find.text('Packages'), findsWidgets);
    expect(observer.minDepth, greaterThan(0));
  });
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openReceipt(WidgetTester tester) async {
  final context = tester.element(find.text('Packages').first);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'payment-success-receipt'),
      builder: (_) => SuccessScreen(
        selectedPlan: PlanModel(
          id: 'trial',
          planCode: 'TRIAL',
          title: 'Trial',
          displayPrice: 0,
          discountedPrice: 0,
          currency: 'PKR',
          includedMinutes: 10,
          includedSeconds: 600,
          expiryDays: 7,
          isTrial: true,
        ),
        checkoutMethod: 'Trial',
        paymentLabel: 'Trial',
        cardNumber: '',
        transactionId: 'entitlement-1',
        doctorName: 'Ada',
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Your transaction was Successful'), findsOneWidget);
}

Finder _receiptBack() {
  return find.descendant(
    of: find.byType(SuccessScreen),
    matching: find.byIcon(Icons.arrow_back_ios_new),
  );
}

Widget _app({required String initial, required NavigatorObserver observer}) {
  return MaterialApp(
    initialRoute: initial,
    navigatorObservers: [observer],
    onGenerateRoute: (settings) {
      switch (settings.name) {
        case 'home':
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Home'),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.subscription_screen),
                      child: const Text('Open packages'),
                    ),
                  ],
                ),
              ),
            ),
          );
        case RouteNames.dashboard:
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Center(child: Text('Dashboard'))),
          );
        case RouteNames.subscription_screen:
        case '/':
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SubscriptionScreen1(),
          );
        default:
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
      }
    },
  );
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
