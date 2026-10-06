// // import 'package:flutter/material.dart';
// // import 'package:medicalai/routes/route.dart';
// // import 'package:medicalai/routes/routs_name.dart';
// // import 'package:medicalai/utils/hive_storage.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// //
// // // 1. GLOBAL KEY DEFINITION
// // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   try {
// //     await Hive.initFlutter();
// //     await HiveStorage.init();
// //   } catch (e) {
// //     debugPrint("❌ Hive Init Error: $e");
// //   }
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'NourDoc',
// //
// //       // 2. CRITICAL FIX: Pass the navigatorKey here
// //       navigatorKey: navigatorKey,
// //
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //       ),
// //
// //       // Doctor app uses splash1
// //       initialRoute: RouteNames.splash1,
// //       onGenerateRoute: Routes.generateRoute,
// //
// //       // 3. CRITICAL FIX: Wrap with the handler
// //       builder: (context, child) {
// //         return AppLifecycleHandler(child: child!);
// //       },
// //     );
// //   }
// // }
// //
// // class AppLifecycleHandler extends StatefulWidget {
// //   final Widget child;
// //   const AppLifecycleHandler({super.key, required this.child});
// //
// //   @override
// //   State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
// // }
// //
// // class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
// //     with WidgetsBindingObserver {
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //   }
// //
// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     super.dispose();
// //   }
// //
// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     // This catches the app waking up from background
// //     if (state == AppLifecycleState.resumed) {
// //       _handleResume();
// //     }
// //   }
// //
// //   void _handleResume() {
// //     final token = HiveStorage.getToken();
// //
// //     // If session is lost while app was in background
// //     if (token == null || token.isEmpty) {
// //       Future.delayed(const Duration(milliseconds: 200), () {
// //         // Redirect to Doctor App Splash
// //         navigatorKey.currentState?.pushNamedAndRemoveUntil(
// //           RouteNames.splash1,
// //               (route) => false,
// //         );
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return widget.child;
// //   }
// // }


// // this is perfect instead of white screen isssue
// import 'package:flutter/material.dart';
// import 'package:medicalai/routes/route.dart';
// import 'package:medicalai/routes/routs_name.dart';
// import 'package:medicalai/utils/hive_storage.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../../main.dart'; // Ensure this points to your root MyApp class


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Screen orientation ko fix kar dein (Optional but helps in performance)
//   // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//   print("🟢 MAIN STARTED");

//   try {
//     // 1. Initialize Hive (Fast)
//     await Hive.initFlutter();

//     // 2. Open Boxes (Necessary for Auth)
//     // Ab ye fast ho jayega kyunki humne cleanup background mein bhej diya hai
//     await HiveStorage.init();

//     print("✅ Hive Basic Init Done");
//   } catch (e) {
//     print("❌ CRITICAL ERROR: $e");
//   }

//   runApp(const MyApp());
// }

// // Future<void> main() async {
// //   // Ensure Flutter is ready for async calls
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //
// //   print("🟢 MAIN STARTED - MANUAL SYNC MODE");
// //
// //   try {
// //     // 1. Initialize Hive Engine
// //     print("🟢 Initializing Hive Flutter...");
// //     await Hive.initFlutter();
// //
// //     print("🟢 Opening Hive Storage...");
// //     await HiveStorage.init();
// //
// //     print("✅ Hive initialization successful and outbox cleaned.");
// //   } catch (e) {
// //     print("❌ CRITICAL ERROR during Hive Init: $e");
// //     // In manual mode, this will only fail if the disk is 100% full.
// //   }
// //
// //   // 3. Launch UI
// //   print("🚀 Launching App UI...");
// //   runApp(const MyApp());
// // }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'NourDoc',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       initialRoute: RouteNames.splash1,
//       onGenerateRoute: Routes.generateRoute,
//       // home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }


import 'dart:async';

// import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/routes/route.dart';
import 'package:medicalai/routes/routs_name.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  runApp(const MyApp());
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

      // _handleResume();
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