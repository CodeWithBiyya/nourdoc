import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/app/routes/routs_name.dart';
import 'package:medicalai/features/consultation/consultation_selection.dart';
import 'package:medicalai/features/auth/login_with_email.dart';
import 'package:medicalai/features/auth/opt_screen.dart';
import 'package:medicalai/features/dashboard/dashboard.dart';
import 'package:medicalai/features/feedback/feedback_collection.dart';
import 'package:medicalai/features/feedback/freeTrial.dart';
import 'package:medicalai/features/feedback/upgrade.dart';
import 'package:medicalai/features/profile/doctor_profile_screen.dart';
import 'package:medicalai/features/outbox/manualuploadScreen.dart';
import 'package:medicalai/features/recorder/acknowledgment_screen/acknowledgmentscreen.dart';
import 'package:medicalai/features/auth/RegisterScreen.dart';
import 'package:medicalai/features/splash/splashscreen1.dart';
import 'package:medicalai/features/subscription/Subscription_screen_1.dart';
import 'package:medicalai/features/subscription/current_plan_screen.dart';


import '../../features/consultation/NewEncounterInformationScreen.dart';
import '../../features/findings/ClinicalFindingsScreen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/consultation/my_encounters.dart';
import '../../features/outbox/queue_list.dart';
import '../../features/recorder/audio_recorder_screen.dart';
import '../../features/splash/splashscreen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (BuildContext context) => splashscreen());
      case RouteNames.splash1:
        return MaterialPageRoute(builder: (_) => SingleSplashScreen());
      // case RouteNames.free_trial:
      //   return MaterialPageRoute(builder: (_) => FreeTrialLimitScreen());
      // case RouteNames.feedback_collection:
      //   return MaterialPageRoute(builder: (_) => FeedbackCollectionScreen());
    // Inside Routes.generateRoute
      case RouteNames.free_trial:
        return MaterialPageRoute(builder: (_) => const FreeTrialLimitScreen());
      case RouteNames.manualUploadScreen:
        return MaterialPageRoute(
          builder: (_) => const ManualUploadProgressScreen(),
          settings: settings, // 🚩 CRITICAL: This allows the screen to see the 'hiveKey'
        );

      case RouteNames.queuelist:
        return MaterialPageRoute(
          builder: (_) => const OutboxListScreen(),
          settings: settings,
        );


      case RouteNames.feedback_collection:
        return MaterialPageRoute(builder: (_) => const FeedbackCollectionScreen());

      case RouteNames.upgrade:
        return MaterialPageRoute(builder: (_) => UpgradeScreen());
      case RouteNames.subscription_screen:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen1());
      case RouteNames.current_plan:
        return MaterialPageRoute(builder: (_) => const CurrentPlanScreen());
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case RouteNames.logInScreen:
        return MaterialPageRoute(builder: (BuildContext context) => LoginScreen());
      case RouteNames.audioRecorderScreen:
        return MaterialPageRoute(builder: (BuildContext context) => AudioRecorderScreen(), settings: settings);
      case RouteNames.RegisterScreen:
        return MaterialPageRoute(builder: (BuildContext context) => RegisterScreen());
      case RouteNames.consultationSelection:
        return MaterialPageRoute(builder: (BuildContext context) => ConsultationSelectionScreen());

      case RouteNames.ClinicalFindingsScreen:
        return MaterialPageRoute(builder: (BuildContext context) => ClinicalFindingsScreen(), settings: settings);
      case RouteNames.MyEncountersScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => MyEncountersScreen(),
          settings: settings,  // ✅ Important! Pass the settings here
        );

      case RouteNames.NewEncounterInformationScreen:
        return MaterialPageRoute(builder: (BuildContext context) => NewEncounterInformationScreen());
      case RouteNames.login_with_email:
        return MaterialPageRoute(builder: (BuildContext context) => LoginWithEmail(),settings: settings);
      case RouteNames.opt_authenticationscreen:
        return MaterialPageRoute(builder: (BuildContext context) => AuthenticationScreen(),settings: settings);

      case RouteNames.acknowledgment_screen:
        return MaterialPageRoute(builder: (BuildContext context) => AcknowledgmentScreen(),settings: settings);
      case RouteNames.doctor_profile_screen:
        return MaterialPageRoute(builder: (BuildContext context) => DoctorProfileScreen(),settings: settings);



      default:
  debugPrint('⚠️ UNKNOWN ROUTE: ${settings.name}');

  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    ),
  );
    }
  }
}
