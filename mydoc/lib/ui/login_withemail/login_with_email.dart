import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/utils/colors.dart';

import '../../routes/routs_name.dart';
import '../../utils/utils.dart';
import 'login_with_email_viewmodel.dart';
import '../../utils/hive_storage.dart';

class LoginWithEmail extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _loginwithEmail();
}

class _loginwithEmail extends State<LoginWithEmail> {
  TextEditingController txtusernameController = new TextEditingController();
  bool _isLoading = false;

  // 🔹 State variable for selection
  String _selectedType = "Email";

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOP SECTION: WHITE BACKGROUND ---
              Container(
                width: screenWidth,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Increased top padding for better gap from top
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, left: 24, right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back, Doctor",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colorprimary,
                            ),
                          ),
                          const SizedBox(height: 10), // Space between title and subtitle
                          Text(
                            "Continue your practice with AI-assisted clinical documentation.\n",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Logo section with reduced size
                    const SizedBox(height: 20),
                    Center(
                      child: Image.asset(
                        "assets/icons/black_new.png",
                        width: screenWidth * 0.6, // Reduced from 0.6 to 0.45
                        height: 190, // Constrained height
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // --- BOTTOM SECTION: COLORED BACKGROUND ---
              Container(
                constraints: BoxConstraints(minHeight: screenHeight * 0.60),
                width: screenWidth,
                decoration: BoxDecoration(
                  color: Colorprimary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      const Text(
                        "\nSign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select your preferred login method",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- RADIO BUTTONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRadioOption("Email"),
                          const SizedBox(width: 20),
                          _buildRadioOption("Phone Number"),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // --- INPUT FIELD ---
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: txtusernameController,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: _selectedType == "Email"
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Enter your $_selectedType',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              _selectedType == "Email"
                                  ? Icons.email_outlined
                                  : Icons.phone_android_outlined,
                              color: Colorprimary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // --- CONTINUE BUTTON ---
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            _handleLoginLogic();
                          },
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: Colorprimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60), // Space before footer

                      // --- FOOTER TEXT ---
                      const Text(
                        "\n\n\nSecure • Fast • Trusted by Healthcare Professionals",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Radio Button Helper with "Coming Soon" Logic
  Widget _buildRadioOption(String title) {
    bool isSelected = _selectedType == title;
    bool isPhone = title == "Phone Number";

    return GestureDetector(
      onTap: () {
        if (isPhone) {
          // 🔹 DISABLE PHONE SELECTION
          utils.toastMessage("Phone Number login coming soon!");
        } else {
          setState(() {
            _selectedType = title;
            txtusernameController.clear();
          });
        }
      },
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            // 🔹 Visual feedback: Make phone option look slightly faded
            color: isPhone ? Colors.white54 : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isPhone ? Colors.white54 : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Login Logic
  // Future<void> _handleLoginLogic() async {
  //   String email = txtusernameController.text.trim();
  //
  //   if (email.isEmpty) {
  //     utils.flushBarErrorMessages("Please enter your email", context);
  //     return;
  //   }
  //
  //   if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
  //     utils.flushBarErrorMessages("Enter a valid Email", context);
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     dynamic responses = await LoginViewModelWithEmail().postLogin(email);
  //     if (responses != null) {
  //       if (responses["custom_status"].toString() == "200") {
  //         bool isReg = responses["data"]["Registered"] == true;
  //         Navigator.pushNamed(
  //           context,
  //           RouteNames.opt_authenticationscreen,
  //           arguments: {
  //             "otp": responses["data"]["otp"].toString(),
  //             "is_reg": isReg ? "1" : "0",
  //             "email": email,
  //             "token": isReg ? responses["data"]["token"].toString() : "",
  //           },
  //         );
  //       } else {
  //         utils.toastMessage(responses["message"]);
  //       }
  //     }
  //   } catch (e) {
  //     utils.toastMessage("Something went wrong. Please try again.");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }
  // Future<void> _handleLoginLogic() async {
  //   String email = txtusernameController.text.trim();
  //
  //   // 1. Immediate Validation (No delay)
  //   if (email.isEmpty) {
  //     utils.flushBarErrorMessages("Please enter your email", context);
  //     return;
  //   }
  //
  //   // 2. Start loading
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // 3. API Call ko variable mein store karein
  //     // Tips: ViewModel ka instance baar-baar create karne ki bajaye
  //     // upar class level par ek baar create karlein to aur fast hoga.
  //     final response = await LoginViewModelWithEmail().postLogin(email);
  //
  //     if (response == null) {
  //       if (mounted) setState(() => _isLoading = false);
  //       utils.toastMessage("Server Error");
  //       return;
  //     }
  //
  //     // 4. Data parsing ko fast banayein
  //     final serverData = response is Map && response.containsKey("data")
  //         ? response["data"]
  //         : response;
  //
  //     dynamic regVal = serverData["registered"] ?? serverData["Registered"];
  //     bool isReg = (regVal == true || regVal.toString().toLowerCase() == "true");
  //
  //     // 5. Navigate immediately without waiting for any extra frames
  //     if (mounted) {
  //       Navigator.pushNamed(
  //         context,
  //         RouteNames.opt_authenticationscreen,
  //         arguments: {
  //           "otp": serverData["otp"]?.toString() ?? "",
  //           "registered": isReg,
  //           "email": email,
  //           "token": serverData["token"]?.toString() ?? "",
  //         },
  //       );
  //
  //       // Navigation ke foran baad loading off kar dein (background mein)
  //       Future.delayed(Duration(milliseconds: 500), () {
  //         if (mounted) setState(() => _isLoading = false);
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) setState(() => _isLoading = false);
  //     utils.toastMessage("Error: $e");
  //   }
  // }
  Future<void> _handleLoginLogic() async {
    String email = txtusernameController.text.trim().toLowerCase();

    // 1. Check if empty
    if (email.isEmpty) {
      utils.flushBarErrorMessages("Please enter your email", context);
      return;
    }

    // 2. Email Validation (Check for @ and .)
    // Yeh regex check karega ki email sahi format mein hai ya nahi
    bool isEmailValid = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);

    if (!isEmailValid) {
      utils.flushBarErrorMessages("Enter a valid email address", context);
      return;
    }

    // 3. Start loading if validation passes
    setState(() => _isLoading = true);

    try {
      final response = await LoginViewModelWithEmail().postLogin(email);

      if (response == null) {
        if (mounted) setState(() => _isLoading = false);
        utils.toastMessage("Server Error");
        return;
      }

      final serverData = response is Map && response.containsKey("data")
          ? response["data"]
          : response;

      dynamic regVal = serverData["registered"] ?? serverData["Registered"];
      bool isReg = (regVal == true || regVal.toString().toLowerCase() == "true");

      if (mounted) {
        Navigator.pushNamed(
          context,
          RouteNames.opt_authenticationscreen,
          arguments: {
            "otp": serverData["otp"]?.toString() ?? "",
            "registered": isReg,
            "email": email,
            "token": serverData["token"]?.toString() ?? "",
          },
        );

        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      utils.toastMessage("Error: $e");
    }
  }


  // this one was correct but the login structure changed
  // Future<void> _handleLoginLogic() async {
  //   String email = txtusernameController.text.trim();
  //
  //   if (email.isEmpty) {
  //     utils.flushBarErrorMessages("Please enter your email", context);
  //     return;
  //   }
  //
  //   if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
  //     utils.flushBarErrorMessages("Enter a valid Email", context);
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // Call the ViewModel login
  //     dynamic responses = await LoginViewModelWithEmail().postLogin(email);
  //
  //     if (responses != null) {
  //       // --- SUCCESS CASE ---
  //       if (responses["custom_status"].toString() == "200") {
  //         bool isReg = responses["data"]["Registered"] == true;
  //         Navigator.pushNamed(
  //           context,
  //           RouteNames.opt_authenticationscreen,
  //           arguments: {
  //             "otp": responses["data"]["otp"].toString(),
  //             "is_reg": isReg ? "1" : "0",
  //             "email": email,
  //             "token": isReg ? responses["data"]["token"].toString() : "",
  //           },
  //         );
  //       }
  //       // --- CLEAN ERROR FROM SERVER ---
  //       else {
  //         utils.toastMessage(responses["message"]);
  //       }
  //     }
  //   } on SocketException {
  //     // True no-internet
  //     utils.toastMessage("No internet connection. Please check your connection.");
  //   } on TimeoutException {
  //     // Timeout or slow server
  //     utils.toastMessage("Server took too long to respond. Try again later.");
  //   } catch (e) {
  //     String errorStr = e.toString().toLowerCase();
  //
  //     // Handle server errors explicitly
  //     if (errorStr.contains("timeout") || errorStr.contains("502") || errorStr.contains("server")) {
  //       utils.toastMessage("Service upgrade in progress. Try again later.");
  //     } else {
  //       // Fallback
  //       utils.toastMessage("Something went wrong. Please try again.");
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

}


