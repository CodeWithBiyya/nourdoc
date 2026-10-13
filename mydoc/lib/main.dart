import 'dart:async';

// import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/repository/Repository.dart';
import 'package:medicalai/routes/route.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:medicalai/ui/consultation_viewmodel.dart';

// IMPORTANT:
// Change the import above if your SuccessScreen is located somewhere else.
// Also import PlanModel if needed by your SuccessScreen.


// ============================================================
// GLOBAL NAVIGATOR KEY
// ============================================================

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🟢 MAIN STARTED");

  try {
    await Hive.initFlutter();
    await HiveStorage.init();

    print("✅ Hive Basic Init Done");
  } catch (e) {
    print("❌ CRITICAL ERROR: $e");
  }

  // runApp(const MyApp());
  runApp(
  ChangeNotifierProvider(
    create: (_) => ConsultationViewModel(),
    child: const MyApp(),
  ),
);
}


// ============================================================
// MY APP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NourDoc',

      // IMPORTANT
      navigatorKey: navigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      initialRoute: RouteNames.splash1,
      onGenerateRoute: Routes.generateRoute,

      builder: (context, child) {
        return AppLifecycleHandler(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}


// ============================================================
// APP LIFECYCLE + STRIPE DEEP LINK HANDLER
// ============================================================

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState
    extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {

  // late final AppLinks _appLinks;

  // StreamSubscription<Uri>? _linkSubscription;

  // bool _paymentLinkHandled = false;


  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // _initDeepLinks();
  }


  // ==========================================================
  // DEEP LINK INITIALIZATION
  // ==========================================================

  // Future<void> _initDeepLinks() async {
  //   _appLinks = AppLinks();

  //   // --------------------------------------------------------
  //   // APP OPENED FROM DEEP LINK
  //   // --------------------------------------------------------

  //   try {
  //     final Uri? initialUri =
  //         await _appLinks.getInitialLink();

  //     if (initialUri != null) {
  //       print(
  //         "🔗 Initial deep link received: $initialUri",
  //       );

  //       _handleDeepLink(initialUri);
  //     }
  //   } catch (e) {
  //     print(
  //       "❌ Initial deep link error: $e",
  //     );
  //   }


  //   // --------------------------------------------------------
  //   // APP ALREADY RUNNING / RESUMED FROM STRIPE
  //   // --------------------------------------------------------

  //   _linkSubscription =
  //       _appLinks.uriLinkStream.listen(
  //     (Uri uri) {
  //       print(
  //         "🔗 Deep link received: $uri",
  //       );

  //       _handleDeepLink(uri);
  //     },
  //     onError: (error) {
  //       print(
  //         "❌ Deep link stream error: $error",
  //       );
  //     },
  //   );
  // }


  // ==========================================================
  // HANDLE DEEP LINK
  // ==========================================================

  void _handleDeepLink(Uri uri) {
    print(
      "🔗 Handling deep link: $uri",
    );

    // We only accept:
    //
    // nourdoc://payment-success
    //

    if (uri.scheme != "nourdoc") {
      print(
        "⚠️ Unknown scheme: ${uri.scheme}",
      );
      return;
    }

    if (uri.host != "payment-success") {
      print(
        "⚠️ Unknown host: ${uri.host}",
      );
      return;
    }

    // // Prevent duplicate navigation.
    // if (_paymentLinkHandled) {
    //   print(
    //     "⚠️ Payment link already handled",
    //   );
    //   return;
    // }

    // _paymentLinkHandled = true;

    // --------------------------------------------------------
    // GET STRIPE SESSION ID
    // --------------------------------------------------------

    final String? sessionId =
        uri.queryParameters["session_id"];

    print(
      "💳 Stripe Session ID: $sessionId",
    );

    // --------------------------------------------------------
    // WAIT UNTIL FLUTTER NAVIGATOR IS READY
    // --------------------------------------------------------

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        _openSuccessScreen(sessionId);
      },
    );
  }


  // ==========================================================
  // OPEN SUCCESS SCREEN
  // ==========================================================

  void _openSuccessScreen(String? sessionId) {
    final BuildContext? context =
        navigatorKey.currentState?.overlay?.context;

    if (context == null) {
      print(
        "❌ Navigator context is null",
      );

      // _paymentLinkHandled = false;
      return;
    }

    print(
      "✅ Opening SuccessScreen",
    );

    /*
     * IMPORTANT:
     *
     * Your SuccessScreen currently requires:
     *
     * selectedPlan
     * paymentMethod
     * cardNumber
     *
     * Those values are NOT available here.
     *
     * Therefore, this root-level handler should ideally
     * verify the Stripe session with your backend and then
     * obtain the actual plan/payment information.
     *
     * For now, DO NOT create fake payment information here.
     */

    print(
      "💳 Payment callback received.",
    );

    // --------------------------------------------------------
    // TEMPORARY:
    // If you want to continue using PaymentScreen's own
    // _handlePaymentCallback(), REMOVE the navigation code
    // here and let PaymentScreen handle it.
    //
    // OR we can modify SuccessScreen to accept only sessionId.
    // --------------------------------------------------------
  }


  // ==========================================================
  // APP RESUMED
  // ==========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      print(
        "🔄 APP RESUMED",
      );
      Repository().readDoctorEntitlement();
    }
  }


  // ==========================================================
  // CHECK LOGIN SESSION
  // ==========================================================

  // void _handleResume() {
  //   final token = HiveStorage.getToken();

  //   if (token == null || token.isEmpty) {
  //     Future.delayed(
  //       const Duration(milliseconds: 200),
  //       () {
  //         navigatorKey.currentState
  //             ?.pushNamedAndRemoveUntil(
  //           RouteNames.splash1,
  //           (route) => false,
  //         );
  //       },
  //     );
  //   }
  // }


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // _linkSubscription?.cancel();

    super.dispose();
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}