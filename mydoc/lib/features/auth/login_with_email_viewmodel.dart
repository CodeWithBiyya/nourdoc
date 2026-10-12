import 'package:flutter/cupertino.dart';
import '../../repository/Repository.dart';
import '../../utils/noInternet.dart';

class LoginViewModelWithEmail with ChangeNotifier {
  final _myRepo = Repository();

  Future<Map<String, dynamic>> postLogin(String username) async {
    try {

         print("=================================");
    print("OTP REQUEST EMAIL: $username");
    print("=================================");

      // 🚩 FIXED: Keys must match Postman exactly (username instead of user)
      // 🚩 FIXED: role should be 'doctor' (lowercase) as seen in your screenshot
      Map<String, String> datamap = {
        'username': username.trim(),
        'role': "doctor"
      };

      

      // 2. Hit API
      final response = await _myRepo.postLoginCall(datamap);

      // 3. SUCCESS CASE
      // We wrap it in a custom status because your UI logic expects this structure
      return {
        "custom_status": 200,
        "message": "Success",
        "data": response, // Contains {registered, otp, token}
      };

    } catch (e) {
      final lower = e.toString().toLowerCase();

      final hasNet = await hasInternet();
      if (!hasNet) {
        return {
          "custom_status": 503,
          "message": "No internet connection. Please check your connection."
        };
      }

      if (lower.contains("timeout") ||
          lower.contains("502") ||
          lower.contains("503") ||
          lower.contains("504") ||
          lower.contains("communication")) {
        return {
          "custom_status": 500,
          "message": "Service upgrade in progress. Try again later."
        };
      }

      return {
        "custom_status": 400,
        "message": "Login Failed: Check your email and try again."
      };
    }
  }
}