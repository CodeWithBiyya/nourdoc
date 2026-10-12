import 'package:flutter/foundation.dart';
import 'package:medicalai/utils/hive_storage.dart';

import '../../repository/Repository.dart';
import '../../utils/utils.dart';

class DoctorProfileViewModel {
  final _myRepo = Repository();

  Future<dynamic> postRegisterUser(dynamic datamap) async {
    // The token might be null for new registration, and that's okay
    String token = HiveStorage.getToken() ?? "";

    return await _myRepo.postRegisterCall(datamap, token);
  }
  // doctor_profile_viewmodel.dart mein add karein
  Future<dynamic> updateDoctorProfile(String email, dynamic datamap) async {
    String token = HiveStorage.getToken() ?? "";
    return await _myRepo.putUpdateDoctorProfile(email, datamap, token);
  }
}