import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/features/splash/splashscreen1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) return;
      previous?.call(details);
    };
  });

  testWidgets('Packages opened after the intro does not return to it', (tester) async {
    await _pumpPhone(tester);
    await tester.pumpWidget(_app(initial: RouteNames.splash1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    expect(find.text('Ambient Clinical Intelligence'), findsNothing);
    expect(find.text('Get Started'), findsOneWidget);

    final started = tester.element(find.text('Get Started'));
    Navigator.of(started).pushNamedAndRemoveUntil(
      RouteNames.subscription_screen,
      (route) => false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ambient Clinical Intelligence'), findsNothing);
    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Exit the app?'), findsOneWidget);
  });

  testWidgets('Packages opened from home goes back to home', (tester) async {
    await _pumpPhone(tester);
    await tester.pumpWidget(_app(initial: 'home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open packages'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Ambient Clinical Intelligence'), findsNothing);
  });

  testWidgets('Packages opened after login goes back to login', (tester) async {
    await _pumpPhone(tester);
    await tester.pumpWidget(_app(initial: RouteNames.splash1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pumpAndSettle();

    final started = tester.element(find.text('Get Started'));
    Navigator.of(started).pushNamedAndRemoveUntil(
      'login',
      (route) => false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Ambient Clinical Intelligence'), findsNothing);
  });
}

Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({required String initial}) {
  return MaterialApp(
    initialRoute: initial,
    onGenerateRoute: (settings) {
      if (settings.name == RouteNames.splash1) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SingleSplashScreen(),
        );
      }
      if (settings.name == 'home') {
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
      }
      if (settings.name == 'login') {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Login'),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, 'otp'),
                    child: const Text('Send code'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (settings.name == 'otp') {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  RouteNames.subscription_screen,
                ),
                child: const Text('Continue'),
              ),
            ),
          ),
        );
      }
      if (settings.name == RouteNames.subscription_screen) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _PackagesBack(),
        );
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      );
    },
  );
}

class _PackagesBack extends StatelessWidget {
  const _PackagesBack();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Packages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            showDialog<void>(
              context: context,
              builder: (context) => const AlertDialog(title: Text('Exit the app?')),
            );
          },
        ),
      ),
    );
  }
}
