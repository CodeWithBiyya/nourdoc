import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicalai/utils/hive_storage.dart';

import '../../routes/routs_name.dart';
import '../../utils/utils.dart';
import 'LoginViewModel.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController txtusernameController = TextEditingController();
  TextEditingController txtPasswordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NourDoc App',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login your account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                const Text('login with'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: () {}, child: const Text('Google')),
                    ElevatedButton(onPressed: () {}, child: const Text('iOS')),
                    ElevatedButton(onPressed: () {}, child: const Text('Mobile No')),
                  ],
                ),
                const SizedBox(height: 24),
                const Center(child: Text('OR')),
                const SizedBox(height: 24),
                const Text('User Name:'),
                TextField(
                  controller: txtusernameController,
                  decoration: const InputDecoration(
                    hintText: 'Type your username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Password:'),
                TextField(
                  controller: txtPasswordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'Type your password',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                    decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),

                      onPressed: () async {
                        if (txtusernameController.text.isEmpty || txtPasswordController.text.isEmpty) {
                          utils.flushBarErrorMessages("Please fill all inputs", context);
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          // 1. Call the ViewModel
                          dynamic responses = await LoginViewModel().postLogin(
                            txtusernameController.text.trim(),
                            txtPasswordController.text.trim(),
                          );

                          // 2. Check if we got a valid response
                          if (responses != null) {
                            // Check for 'registered' (lowercase) or 'Registered' (uppercase)
                            bool isRegistered = responses['registered'] ?? responses['Registered'] ?? false;
                            String? token = responses['token']?.toString();
                            String? otp = responses['otp']?.toString();
                            String? apiMessage = responses['message']?.toString();

                            // LOGIC: If we have a token, we consider the first step successful
                            if (token != null) {
                              await HiveStorage.setToken(token);

                              if (context.mounted) {
                                // Show the message from API (e.g. "OTP sent to registered email")
                                utils.flushBarErrorMessages(
                                    apiMessage ?? "Check your Gmail for OTP: $otp", context);

                                // IMPORTANT: Navigate to your OTP Verification screen here
                                // For now, I am keeping your MyEncountersScreen as requested
                                Navigator.pushNamed(context, RouteNames.MyEncountersScreen);
                              }
                            } else {
                              if (context.mounted) utils.flushBarErrorMessages("Login Failed: No token received", context);
                            }
                          } else {
                            if (context.mounted) utils.flushBarErrorMessages("Invalid credentials or Server Error", context);
                          }
                        } catch (e) {
                          if (context.mounted) utils.flushBarErrorMessages("Error: ${e.toString()}", context);
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: const Text('Login', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}