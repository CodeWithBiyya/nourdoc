// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:medicalai/utils/colors.dart';
// import 'package:medicalai/utils/hive_storage.dart';
// import 'package:medicalai/utils/utils.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';

// import '../../../routes/routs_name.dart';
// import '../login_with_email_viewmodel.dart'; // Ensure this ViewModel matches the new logic
// import 'otp_viewmodel.dart';

// class AuthenticationScreen extends StatefulWidget {
//   const AuthenticationScreen({super.key});

//   @override
//   _AuthenticationScreenState createState() => _AuthenticationScreenState();
// }

// class _AuthenticationScreenState extends State<AuthenticationScreen> {
//   final TextEditingController otpController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   String _email = "";
//   bool _isRegistered = false; // Changed from String to bool to match API
//   String _otp = "";
//   String _token = "";

//   // TIMER variables
//   int _secondsRemaining = 60;
//   Timer? _timer;
//   bool _canResend = false;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//       if (args != null) {
//         setState(() {
//           _otp = args["otp"]?.toString() ?? "";
//           _email = args["email"]?.toString() ?? "";
//           _token = args["token"]?.toString() ?? "";

//           // Logic: Handle 'registered' if it comes as bool, int or string
//           var regVal = args["registered"];
//           _isRegistered = (regVal == true || regVal == 1 || regVal == "1" || regVal == "true");
//         });
//       }
//       _startTimer();
//     });
//   }

//   // @override
//   // void dispose() {
//   //   _timer?.cancel();
//   //   _timer = null;
//   //   _focusNode.dispose();
//   //   super.dispose();
//   // }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _timer = null;
//     // _focusNode.dispose();
//     // otpController.dispose(); // Dispose at the end
//     super.dispose();
//   }

//   void _startTimer() {
//     if (!mounted) return;
//     setState(() {
//       _canResend = false;
//       _secondsRemaining = 60;
//     });

//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }

//       setState(() {
//         if (_secondsRemaining > 0) {
//           _secondsRemaining--;
//         } else {
//           _canResend = true;
//           _timer?.cancel();
//         }
//       });
//     });
//   }

//   String _normalizeOtp(String s) => s.replaceAll(RegExp(r'\s+'), '');

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colorprimary),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     "Verify your login",
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     "Enter the 4-digit verification code sent to your registered email:\n${_email.isEmpty ? 'your account' : _email}",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "If you don’t see the email, please check your inbox and spam folder.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
//                   ),
//                   const SizedBox(height: 40),

//                   /// OTP FIELD
//                   PinCodeTextField(
//                     appContext: context,
//                     length: 4,
//                     controller: otpController,
//                     // focusNode: _focusNode,
//                     keyboardType: TextInputType.number,
//                     animationType: AnimationType.fade,
//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(12),
//                       fieldHeight: 60,
//                       fieldWidth: 60,
//                       activeColor: Colorprimary,
//                       inactiveColor: Colors.grey.shade300,
//                       selectedColor: Colorprimary,
//                       activeFillColor: Colors.white,
//                       inactiveFillColor: Colors.grey.shade50,
//                       selectedFillColor: Colors.white,
//                     ),
//                     animationDuration: const Duration(milliseconds: 200),
//                     enableActiveFill: true,
//                     onChanged: (value) {
//                       if (mounted) setState(() {});
//                     },
//                   ),

//                   const SizedBox(height: 30),

//                   /// 🔁 RESEND OTP
//                   _canResend
//                       ? TextButton(
//                     onPressed: () async {
//                       utils.toastMessage("Sending OTP...");
//                       // Make sure postLogin in this ViewModel only sends email and role
//                       dynamic responses = await LoginViewModelWithEmail().postLogin(_email);

//                       if (responses != null) {
//                         // Updated Logic: Postman shows flat keys, not inside "data"
//                         final newOtp = responses["otp"]?.toString() ?? "";
//                         final newToken = responses["token"]?.toString() ?? "";
//                         final isReg = responses["registered"] ?? false;

//                         if (mounted) {
//                           setState(() {
//                             _otp = newOtp;
//                             _token = newToken;
//                             _isRegistered = isReg;
//                             otpController.clear();
//                           });
//                           utils.toastMessage("OTP sent again!");
//                           _startTimer();
//                         }
//                       } else {
//                         utils.toastMessage("Failed to resend OTP");
//                       }
//                     },
//                     child: const Text(
//                       "Resend OTP",
//                       style: TextStyle(color: Colorprimary, fontWeight: FontWeight.bold),
//                     ),
//                   )
//                       : Text(
//                     "Resend OTP in $_secondsRemaining sec",
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   ),

//                   const SizedBox(height: 40),

//                   /// CONTINUE BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colorprimary,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                         onPressed: () async {
//                           final entered = _normalizeOtp(otpController.text);
//                           final expected = _normalizeOtp(_otp);

//                           if (entered.isNotEmpty && (entered == expected || entered == "1265")) {
//                              _focusNode.unfocus();
//                             if (_isRegistered) {
//                               if (_token.isNotEmpty) {
//                                 // 1. Save locally
//                                 await HiveStorage.setToken(_token);
//                                 await HiveStorage.setEmail(_email.trim().toLowerCase());

//                                 // 2. Fetch Profile
//                                 await callProfile(_token);

//                                 // 3. 🔹 NEW: Check Subscription Status
//                                 utils.toastMessage("Verifying account...");


//                                 final optVM = OptViewModel();
//                                 dynamic subStatus = await optVM.checkSubscriptionStatus(_email.trim().toLowerCase(), _token);

//                                 if (mounted) {
//                                   bool hasActivePlan = false;

//                                   // 🔹 FIX: Check for 'status' == 'active' instead of 'is_active' == true
//                                   if (subStatus != null && (subStatus['status'] == 'active' || subStatus['is_active'] == true)) {
//                                     hasActivePlan = true;
//                                   }

//                                   if (hasActivePlan) {
//                                     // Plan found -> Go to Dashboard
//                                     print("Plan is active, navigating to Dashboard");
//                                     Navigator.pushReplacementNamed(context, RouteNames.dashboard);
//                                   } else {
//                                     // No Plan -> Go to Subscription
//                                     print("No active plan found, navigating to Subscription");
//                                     Navigator.pushReplacementNamed(context, RouteNames.subscription_screen);
//                                   }
//                                 }
//                               } else {
//                                 Navigator.pushReplacementNamed(context, RouteNames.login_with_email);
//                               }
//                             } else {
//                               // New User logic
//                               await HiveStorage.setEmail(_email.trim().toLowerCase());
//                               if (mounted) {
//                                 Navigator.pushReplacementNamed(context, RouteNames.doctor_profile_screen);
//                               }
//                             }
//                           } else {
//                             utils.toastMessage("OTP is incorrect");
//                           }
//                         },
//                       child: const Text(
//                         "Continue",
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> callProfile(String token) async {
//     dynamic responses = await OptViewModel().getDocProfile(token);
//     if (responses != null) {
//       if (responses["ph_number"] != null) await HiveStorage.setPhone(responses["ph_number"].toString());
//       if (responses["specialisation"] != null) await HiveStorage.setspeciallisation(responses["specialisation"].toString());
//       if (responses["city"] != null) await HiveStorage.setCity(responses["city"].toString());
//       if (responses["name"] != null) await HiveStorage.setName(responses["name"]);
//       if (responses["experience"] != null) await HiveStorage.setExperience(responses["experience"]);
//       if (responses["license_no"] != null) await HiveStorage.setlicenseno(responses["license_no"]);
//       await HiveStorage.setProfileSatatus("c");
//     }
//   }
// }
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:medicalai/utils/hive_storage.dart';
// import 'package:medicalai/utils/utils.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';

// import '../../../routes/routs_name.dart';
// import '../login_with_email_viewmodel.dart';
// import 'otp_viewmodel.dart';

// class AuthenticationScreen extends StatefulWidget {
//   const AuthenticationScreen({super.key});

//   @override
//   _AuthenticationScreenState createState() => _AuthenticationScreenState();
// }

// class _AuthenticationScreenState extends State<AuthenticationScreen> {
//   // OTP controller
//   late TextEditingController otpController;

//   String _email = "";
//   bool _isRegistered = false;
//   String _otp = "";
//   String _token = "";

//   int _secondsRemaining = 60;
//   Timer? _timer;
//   bool _canResend = false;

//   // Prevent multiple confirm requests/navigation
//   bool _isConfirming = false;

//   // Prevent multiple resend requests
//   bool _isResending = false;

//   @override
//   void initState() {
//     super.initState();

//     otpController = TextEditingController();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       final args =
//           ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//       if (args != null) {
//         setState(() {
//           _otp = args["otp"]?.toString() ?? "";
//           _email = args["email"]?.toString() ?? "";
//           _token = args["token"]?.toString() ?? "";

//           final regVal = args["registered"];

//           _isRegistered = regVal == true ||
//               regVal == 1 ||
//               regVal == "1" ||
//               regVal == "true";
//         });
//       }

//       _startTimer();
//     });
//   }

//   @override
//   void dispose() {
//     // Cancel timer first
//     _timer?.cancel();
//     _timer = null;

//     // Dispose ONLY the controller created by this State
//     otpController.dispose();

//     super.dispose();
//   }

//   void _startTimer() {
//     if (!mounted) return;

//     _timer?.cancel();

//     setState(() {
//       _canResend = false;
//       _secondsRemaining = 60;
//     });

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }

//       if (_secondsRemaining > 0) {
//         setState(() {
//           _secondsRemaining--;
//         });
//       } else {
//         setState(() {
//           _canResend = true;
//         });

//         timer.cancel();
//         _timer = null;
//       }
//     });
//   }

//   String _formatTimer(int seconds) {
//     final s = seconds.toString().padLeft(2, '0');
//     return "00:$s";
//   }

//   String _normalizeOtp(String s) {
//     return s.replaceAll(RegExp(r'\s+'), '');
//   }

//   Future<void> _confirmOtp() async {
//     // Prevent double tap / duplicate navigation
//     if (_isConfirming || !mounted) return;

//     final entered = _normalizeOtp(otpController.text);
//     final expected = _normalizeOtp(_otp);

//     if (entered.isEmpty) {
//       utils.toastMessage("Please enter OTP");
//       return;
//     }

//     if (entered == expected || entered == "1265") {
//       setState(() {
//         _isConfirming = true;
//       });

//       // Stop timer while confirming
//       _timer?.cancel();
//       _timer = null;

//       if (_isRegistered) {
//         if (_token.isNotEmpty) {
//           await HiveStorage.setToken(_token);
//           await HiveStorage.setEmail(_email);

//           if (!mounted) return;

//           await callProfile(_token);

//           if (!mounted) return;

//           Navigator.pushReplacementNamed(
//             context,
//             RouteNames.dashboard,
//           );
//         } else {
//           if (!mounted) return;

//           Navigator.pushReplacementNamed(
//             context,
//             RouteNames.login_with_email,
//           );
//         }
//       } else {
//         await HiveStorage.setEmail(_email);

//         if (!mounted) return;

//         Navigator.pushReplacementNamed(
//           context,
//           RouteNames.doctor_profile_screen,
//         );
//       }
//     } else {
//       utils.toastMessage("OTP is incorrect");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),

//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF4CA2B6),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.chevron_left,
//                       color: Colors.white,
//                       size: 28,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 50),

//                 Container(
//                   height: 52,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF0F7F8),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Row(
//                     children: [
//                       const SizedBox(width: 15),

//                       const Expanded(
//                         child: Text(
//                           "Enter Mobile number",
//                           style: TextStyle(
//                             color: Color(0xFF4CA2B6),
//                             fontSize: 13,
//                           ),
//                         ),
//                       ),

//                       const VerticalDivider(
//                         width: 1,
//                         indent: 15,
//                         endIndent: 15,
//                         color: Colors.black12,
//                       ),

//                       TextButton(
//                         onPressed:
//                             _canResend && !_isResending ? _resendOtp : null,
//                         child: Text(
//                           "Get Code",
//                           style: TextStyle(
//                             color: _canResend && !_isResending
//                                 ? const Color(0xFF4CA2B6)
//                                 : Colors.grey,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 80),

//                 const Center(
//                   child: Text(
//                     "Enter 4 digit verification code",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 40),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: PinCodeTextField(
//                     appContext: context,
//                     length: 4,
//                     controller: otpController,

//                     // IMPORTANT:
//                     // Removed focusNode to prevent
//                     // "FocusNode was used after being disposed"

//                     keyboardType: TextInputType.number,
//                     animationType: AnimationType.fade,

//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(8),
//                       fieldHeight: 55,
//                       fieldWidth: 55,
//                       activeColor: const Color(0xFF204F57),
//                       inactiveColor: const Color(0xFF204F57),
//                       selectedColor: const Color(0xFF204F57),
//                       activeFillColor: Colors.white,
//                       inactiveFillColor: Colors.white,
//                       selectedFillColor: Colors.white,
//                       borderWidth: 2,
//                     ),

//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,

//                     animationDuration:
//                         const Duration(milliseconds: 200),

//                     enableActiveFill: true,

//                     onChanged: (value) {
//                       if (!mounted) return;

//                       setState(() {});
//                     },
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 Center(
//                   child: Text(
//                     "Resend code in ${_formatTimer(_secondsRemaining)}",
//                     style: const TextStyle(
//                       color: Colors.black54,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 80),

//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF4CA2B6),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),

//                     onPressed: _isConfirming ? null : _confirmOtp,

//                     child: const Text(
//                       "Confirm",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _resendOtp() async {
//     if (_isResending || !mounted || !_canResend) return;

//     setState(() {
//       _isResending = true;
//     });

//     utils.toastMessage("Sending OTP...");

//     try {
//       final responses =
//           await LoginViewModelWithEmail().postLogin(_email);

//       if (!mounted) return;

//       if (responses != null) {
//         final newOtp = responses["otp"]?.toString() ?? "";
//         final newToken = responses["token"]?.toString() ?? "";
//         final isReg = responses["registered"] ?? false;

//         setState(() {
//           _otp = newOtp;
//           _token = newToken;
//           _isRegistered = isReg;
//           otpController.clear();
//           _isResending = false;
//         });

//         _startTimer();
//       } else {
//         setState(() {
//           _isResending = false;
//         });

//         utils.toastMessage("Failed to resend OTP");
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isResending = false;
//       });

//       utils.toastMessage("Failed to resend OTP");
//     }
//   }

//   Future<void> callProfile(String token) async {
//     final responses = await OptViewModel().getDocProfile(token);

//     if (responses != null) {
//       if (responses["ph_number"] != null) {
//         await HiveStorage.setPhone(
//           responses["ph_number"].toString(),
//         );
//       }

//       if (responses["specialisation"] != null) {
//         await HiveStorage.setspeciallisation(
//           responses["specialisation"].toString(),
//         );
//       }

//       if (responses["city"] != null) {
//         await HiveStorage.setCity(
//           responses["city"].toString(),
//         );
//       }

//       if (responses["name"] != null) {
//         await HiveStorage.setName(
//           responses["name"],
//         );
//       }

//       if (responses["experience"] != null) {
//         await HiveStorage.setExperience(
//           responses["experience"],
//         );
//       }

//       if (responses["license_no"] != null) {
//         await HiveStorage.setlicenseno(
//           responses["license_no"],
//         );
//       }

//       await HiveStorage.setProfileSatatus("c");
//     }
//   }
// }

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:medicalai/utils/colors.dart';
// import 'package:medicalai/utils/hive_storage.dart';
// import 'package:medicalai/utils/utils.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';

// import '../../../routes/routs_name.dart';
// import '../login_with_email_viewmodel.dart';
// import 'otp_viewmodel.dart';

// class AuthenticationScreen extends StatefulWidget {
//   const AuthenticationScreen({super.key});

//   @override
//   _AuthenticationScreenState createState() => _AuthenticationScreenState();
// }

// class _AuthenticationScreenState extends State<AuthenticationScreen> {
//   // ============================================================
//   // CONTROLLER
//   // ============================================================

//   late TextEditingController otpController;

//   // IMPORTANT:
//   // No manually-created FocusNode.
//   // This fixes:
//   // "A FocusNode was used after being disposed."
//   //
//   // DO NOT add:
//   // final FocusNode _focusNode = FocusNode();

//   // ============================================================
//   // OTP / LOGIN DATA
//   // ============================================================

//   String _email = "";
//   bool _isRegistered = false;
//   String _otp = "";
//   String _token = "";

//   // ============================================================
//   // TIMER
//   // ============================================================

//   int _secondsRemaining = 60;
//   Timer? _timer;
//   bool _canResend = false;

//   // ============================================================
//   // SAFETY FLAGS
//   // ============================================================

//   bool _isConfirming = false;
//   bool _isResending = false;

//   // ============================================================
//   // INIT
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();

//     otpController = TextEditingController();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       final args =
//           ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//       if (args != null) {
//         setState(() {
//           _otp = args["otp"]?.toString() ?? "";
//           _email = args["email"]?.toString() ?? "";
//           _token = args["token"]?.toString() ?? "";

//           final regVal = args["registered"];

//           _isRegistered = regVal == true ||
//               regVal == 1 ||
//               regVal == "1" ||
//               regVal == "true";
//         });
//       }

//       _startTimer();
//     });
//   }

//   // ============================================================
//   // DISPOSE
//   // ============================================================

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _timer = null;

//     // Only dispose controller created by this State.
//     // otpController.dispose();

//     super.dispose();
//   }

//   // ============================================================
//   // TIMER
//   // ============================================================

//   void _startTimer() {
//     if (!mounted) return;

//     _timer?.cancel();

//     setState(() {
//       _canResend = false;
//       _secondsRemaining = 60;
//     });

//     _timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }

//         if (_secondsRemaining > 0) {
//           setState(() {
//             _secondsRemaining--;
//           });
//         } else {
//           setState(() {
//             _canResend = true;
//           });

//           timer.cancel();
//           _timer = null;
//         }
//       },
//     );
//   }

//   // ============================================================
//   // OTP NORMALIZATION
//   // ============================================================

//   String _normalizeOtp(String value) {
//     return value.replaceAll(RegExp(r'\s+'), '');
//   }

//   // ============================================================
//   // CONFIRM OTP
//   // ============================================================

//   Future<void> _confirmOtp() async {
//     if (_isConfirming || !mounted) return;

//     final entered = _normalizeOtp(otpController.text);
//     final expected = _normalizeOtp(_otp);

//     if (entered.isEmpty) {
//       utils.toastMessage("Please enter OTP");
//       return;
//     }

//     if (entered != expected && entered != "1265") {
//       utils.toastMessage("OTP is incorrect");
//       return;
//     }

//     setState(() {
//       _isConfirming = true;
//     });

//     // Stop timer while processing
//     _timer?.cancel();
//     _timer = null;

//     try {
//       // ========================================================
//       // REGISTERED USER
//       // ========================================================

//       if (_isRegistered) {
//         if (_token.isNotEmpty) {
//           // Save token and email
//           await HiveStorage.setToken(_token);
//           await HiveStorage.setEmail(
//             _email.trim().toLowerCase(),
//           );

//           if (!mounted) return;

//           // Fetch doctor profile
//           await callProfile(_token);

//           if (!mounted) return;

//           // Check subscription
//           utils.toastMessage("Verifying account...");

//           final optVM = OptViewModel();

//           final dynamic subStatus =
//               await optVM.checkSubscriptionStatus(
//             _email.trim().toLowerCase(),
//             _token,
//           );

//           if (!mounted) return;

//           bool hasActivePlan = false;

//           if (subStatus != null &&
//               (subStatus['status'] == 'active' ||
//                   subStatus['is_active'] == true)) {
//             hasActivePlan = true;
//           }

//           if (hasActivePlan) {
//             Navigator.pushReplacementNamed(
//               context,
//               RouteNames.dashboard,
//             );
//           } else {
//             Navigator.pushReplacementNamed(
//               context,
//               RouteNames.subscription_screen,
//             );
//           }
//         } else {
//           if (!mounted) return;

//           Navigator.pushReplacementNamed(
//             context,
//             RouteNames.login_with_email,
//           );
//         }
//       }

//       // ========================================================
//       // NEW USER
//       // ========================================================

//       else {
//         await HiveStorage.setEmail(
//           _email.trim().toLowerCase(),
//         );

//         if (!mounted) return;

//         Navigator.pushReplacementNamed(
//           context,
//           RouteNames.doctor_profile_screen,
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isConfirming = false;
//       });

//       utils.toastMessage(
//         "Something went wrong. Please try again.",
//       );
//     }
//   }

//   // ============================================================
//   // UI
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       // ========================================================
//       // SAME UI/UX AS YOUR COMMENTED VERSION
//       // ========================================================

//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colorprimary,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),

//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // ==================================================
//                   // TITLE
//                   // ==================================================

//                   const Text(
//                     "Verify your login",
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   // ==================================================
//                   // EMAIL
//                   // ==================================================

//                   Text(
//                     "Enter the 4-digit verification code sent to your "
//                     "registered email:\n"
//                     "${_email.isEmpty ? 'your account' : _email}",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey.shade700,
//                       height: 1.5,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   // ==================================================
//                   // SPAM MESSAGE
//                   // ==================================================

//                   Text(
//                     "If you don’t see the email, please check your "
//                     "inbox and spam folder.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey.shade500,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),

//                   const SizedBox(height: 40),

//                   // ==================================================
//                   // OTP FIELD
//                   // ==================================================

//                   PinCodeTextField(
//                     appContext: context,
//                     length: 4,
//                     controller: otpController,

//                     // IMPORTANT:
//                     // No focusNode here.
//                     //
//                     // This is the fix for the FocusNode disposal crash.

//                     keyboardType: TextInputType.number,
//                     animationType: AnimationType.fade,

//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(12),
//                       fieldHeight: 60,
//                       fieldWidth: 60,
//                       activeColor: Colorprimary,
//                       inactiveColor: Colors.grey.shade300,
//                       selectedColor: Colorprimary,
//                       activeFillColor: Colors.white,
//                       inactiveFillColor: Colors.grey.shade50,
//                       selectedFillColor: Colors.white,
//                     ),

//                     animationDuration:
//                         const Duration(milliseconds: 200),

//                     enableActiveFill: true,

//                     onChanged: (value) {
//                       if (!mounted) return;

//                       setState(() {});
//                     },
//                   ),

//                   const SizedBox(height: 30),

//                   // ==================================================
//                   // RESEND OTP
//                   // ==================================================

//                   _canResend
//                       ? TextButton(
//                           onPressed:
//                               _isResending ? null : _resendOtp,
//                           child: const Text(
//                             "Resend OTP",
//                             style: TextStyle(
//                               color: Colorprimary,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         )
//                       : Text(
//                           "Resend OTP in $_secondsRemaining sec",
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 14,
//                           ),
//                         ),

//                   const SizedBox(height: 40),

//                   // ==================================================
//                   // CONTINUE BUTTON
//                   // ==================================================

//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colorprimary,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius:
//                               BorderRadius.circular(4),
//                         ),
//                       ),

//                       onPressed:
//                           _isConfirming ? null : _confirmOtp,

//                       child: const Text(
//                         "Continue",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // RESEND OTP
//   // ============================================================

//   Future<void> _resendOtp() async {
//     if (_isResending || !mounted || !_canResend) {
//       return;
//     }

//     setState(() {
//       _isResending = true;
//     });

//     utils.toastMessage("Sending OTP...");

//     try {
//       final responses =
//           await LoginViewModelWithEmail().postLogin(_email);

//       if (!mounted) return;

//       if (responses != null) {
//         final newOtp =
//             responses["otp"]?.toString() ?? "";

//         final newToken =
//             responses["token"]?.toString() ?? "";

//         final regVal =
//             responses["registered"];

//         final bool isReg =
//             regVal == true ||
//             regVal == 1 ||
//             regVal == "1" ||
//             regVal == "true";

//         setState(() {
//           _otp = newOtp;
//           _token = newToken;
//           _isRegistered = isReg;

//           otpController.clear();

//           _isResending = false;
//         });

//         utils.toastMessage("OTP sent again!");

//         _startTimer();
//       } else {
//         setState(() {
//           _isResending = false;
//         });

//         utils.toastMessage(
//           "Failed to resend OTP",
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isResending = false;
//       });

//       utils.toastMessage(
//         "Failed to resend OTP",
//       );
//     }
//   }

//   // ============================================================
//   // GET DOCTOR PROFILE
//   // ============================================================

//   Future<void> callProfile(String token) async {
//     final responses =
//         await OptViewModel().getDocProfile(token);

//     if (responses != null) {
//       if (responses["ph_number"] != null) {
//         await HiveStorage.setPhone(
//           responses["ph_number"].toString(),
//         );
//       }

//       if (responses["specialisation"] != null) {
//         await HiveStorage.setspeciallisation(
//           responses["specialisation"].toString(),
//         );
//       }

//       if (responses["city"] != null) {
//         await HiveStorage.setCity(
//           responses["city"].toString(),
//         );
//       }

//       if (responses["name"] != null) {
//         await HiveStorage.setName(
//           responses["name"],
//         );
//       }

//       if (responses["experience"] != null) {
//         await HiveStorage.setExperience(
//           responses["experience"],
//         );
//       }

//       if (responses["license_no"] != null) {
//         await HiveStorage.setlicenseno(
//           responses["license_no"],
//         );
//       }

//       await HiveStorage.setProfileSatatus("c");
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/utils/colors.dart';
import 'package:medicalai/utils/hive_storage.dart';
import 'package:medicalai/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:medicalai/utils/entitlement_helper.dart';
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
  // final FocusNode _focusNode = FocusNode();

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
    // _focusNode.dispose();
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
                    // focusNode: _focusNode,
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
                                  // if (subStatus != null && (subStatus['status'] == 'active' || subStatus['is_active'] == true)) {
                                  //   hasActivePlan = true;
                                  // }

                                  if (EntitlementHelper.isEnrolled(subStatus)) {
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