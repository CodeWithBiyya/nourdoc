import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../repository/Repository.dart';
import '../../utils/utils.dart';

class LoginViewModel with ChangeNotifier {
  final _myRepo = Repository();

  Future<dynamic> postLogin(String username, String password) async {
    print("post login started...");

    // 1. MATCH POSTMAN EXACTLY: Only 'username' and 'role'
    // 2. USE .trim(): Very important to remove spaces from the email
    Map<String, String> datamap = {
      'username': username.trim(),
      'role': 'doctor',
      // Do NOT send 'password' here if Postman works without it.
    };

    try {
      // This calls your Repository
      dynamic response = await _myRepo.postLoginCall(datamap);

      if (kDebugMode) {
        print("API Response: ${response.toString()}");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        print("API Error: ${error.toString()}");
      }
      return null;
    }
  }
}