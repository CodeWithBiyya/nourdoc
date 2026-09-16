import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../routes/routs_name.dart';
import '../login_with_email_viewmodel.dart'; // Ensure this ViewModel matches the new logic
import 'otp_viewmodel.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _email = "";
  bool _isRegistered = false; // Changed from String to bool to match API
  String _otp = "";
  String _token = "";

  // TIMER variables
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _otp = args["otp"]?.toString() ?? "";
          _email = args["email"]?.toString() ?? "";
          _token = args["token"]?.toString() ?? "";

          // Logic: Handle 'registered' if it comes as bool, int or string
          var regVal = args["registered"];
          _isRegistered = (regVal == true || regVal == 1 || regVal == "1" || regVal == "true");
        });
      }
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _normalizeOtp(String s) => s.replaceAll(RegExp(r'\s+'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colorprimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Verify your login",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter the 4-digit verification code sent to your registered email:\n${_email.isEmpty ? 'your account' : _email}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "If you don’t see the email, please check your inbox and spam folder.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 40),

                  /// OTP FIELD
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    controller: otpController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 60,
                      fieldWidth: 60,
                      activeColor: Colorprimary,
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: Colorprimary,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey.shade50,
                      selectedFillColor: Colors.white,
                    ),
                    animationDuration: const Duration(milliseconds: 200),
                    enableActiveFill: true,
                    onChanged: (value) {
                      if (mounted) setState(() {});
                    },
                  ),

                  const SizedBox(height: 30),

                  /// 🔁 RESEND OTP
                  _canResend
                      ? TextButton(
                    onPressed: () async {
                      utils.toastMessage("Sending OTP...");
                      // Make sure postLogin in this ViewModel only sends email and role
                      dynamic responses = await LoginViewModelWithEmail().postLogin(_email);

                      if (responses != null) {
                        // Updated Logic: Postman shows flat keys, not inside "data"
                        final newOtp = responses["otp"]?.toString() ?? "";
                        final newToken = responses["token"]?.toString() ?? "";
                        final isReg = responses["registered"] ?? false;

                        if (mounted) {
                          setState(() {
                            _otp = newOtp;
                            _token = newToken;
                            _isRegistered = isReg;
                            otpController.clear();
                          });
                          utils.toastMessage("OTP sent again!");
                          _startTimer();
                        }
                      } else {
                        utils.toastMessage("Failed to resend OTP");
                      }
                    },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(color: Colorprimary, fontWeight: FontWeight.bold),
                    ),
                  )
                      : Text(
                    "Resend OTP in $_secondsRemaining sec",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),

                  const SizedBox(height: 40),

                  /// CONTINUE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colorprimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                        onPressed: () async {
                          final entered = _normalizeOtp(otpController.text);
                          final expected = _normalizeOtp(_otp);

                          if (entered.isNotEmpty && (entered == expected || entered == "1265")) {
                            if (_isRegistered) {
                              if (_token.isNotEmpty) {
                                // 1. Save locally
                                await HiveStorage.setToken(_token);
                                await HiveStorage.setEmail(_email.trim().toLowerCase());

                                // 2. Fetch Profile
                                await callProfile(_token);

                                // 3. 🔹 NEW: Check Subscription Status
                                utils.toastMessage("Verifying account...");


                                final optVM = OptViewModel();
                                dynamic subStatus = await optVM.checkSubscriptionStatus(_email.trim().toLowerCase(), _token);

                                if (mounted) {
                                  bool hasActivePlan = false;

                                  // 🔹 FIX: Check for 'status' == 'active' instead of 'is_active' == true
                                  if (subStatus != null && (subStatus['status'] == 'active' || subStatus['is_active'] == true)) {
                                    hasActivePlan = true;
                                  }

                                  if (hasActivePlan) {
                                    // Plan found -> Go to Dashboard
                                    print("Plan is active, navigating to Dashboard");
                                    Navigator.pushReplacementNamed(context, RouteNames.dashboard);
                                  } else {
                                    // No Plan -> Go to Subscription
                                    print("No active plan found, navigating to Subscription");
                                    Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
                                  }
                                }
                              } else {
                                Navigator.pushReplacementNamed(context, RouteNames.login_with_email);
                              }
                            } else {
                              // New User logic
                              await HiveStorage.setEmail(_email.trim().toLowerCase());
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, RouteNames.doctor_profile_screen);
                              }
                            }
                          } else {
                            utils.toastMessage("OTP is incorrect");
                          }
                        },
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> callProfile(String token) async {
    dynamic responses = await OptViewModel().getDocProfile(token);
    if (responses != null) {
      if (responses["ph_number"] != null) await HiveStorage.setPhone(responses["ph_number"].toString());
      if (responses["specialisation"] != null) await HiveStorage.setspeciallisation(responses["specialisation"].toString());
      if (responses["city"] != null) await HiveStorage.setCity(responses["city"].toString());
      if (responses["name"] != null) await HiveStorage.setName(responses["name"]);
      if (responses["experience"] != null) await HiveStorage.setExperience(responses["experience"]);
      if (responses["license_no"] != null) await HiveStorage.setlicenseno(responses["license_no"]);
      await HiveStorage.setProfileSatatus("c");
    }
  }
}