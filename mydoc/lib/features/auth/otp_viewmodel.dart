import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../repository/Repository.dart';
import '../../../utils/utils.dart';

class OptViewModel with ChangeNotifier {
  final _myRepo = Repository();

  Future<dynamic> getDocProfile(String token) async {
    dynamic response;
    response = await _myRepo.getDocProfile(token).then((value) {
      return value;
    }).onError((error, stackTrace) {
      utils.toastMessage(error.toString());
      return null;
    });
    return response;
  }

  // Future<dynamic> checkSubscriptionStatus(String doctorId, String token) async {
  //   dynamic response;
  //   response = await _myRepo.getEntitlementStatusApi(doctorId, token).then((value) {
  //     return value;
  //   }).onError((error, stackTrace) {
  //     if (kDebugMode) print(error.toString());
      
  //     return null;
  //   });
  //   return response;
  // }

  Future<dynamic> checkSubscriptionStatus(
  String doctorId,
  String token,
) async {
  try {
    final response =
        await _myRepo.getEntitlementStatusApi(doctorId, token);

    if (kDebugMode) {
      print("========== SUBSCRIPTION STATUS ==========");
      print("Doctor: $doctorId");
      print("Response: $response");
      print("=========================================");
    }

    return response;
  } catch (e) {
    if (kDebugMode) {
      print("Subscription status error: $e");
    }
    return null;
  }
}
}