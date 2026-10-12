// import 'dart:convert';
//
// class EncounterListModel {
//   final int customStatus;
//   final String message;
//   final List<EncounterData>? data;
//
//   EncounterListModel({
//     required this.customStatus,
//     required this.message,
//     required this.data,
//   });
//
//   // 🚩 OLD Format (Map: {"data": [...]}) ke liye
//   factory EncounterListModel.fromJson(Map<String, dynamic> json) {
//     return EncounterListModel(
//       customStatus: json['custom_status'] ?? json['status'] ?? 0,
//       message: json['message'] ?? '',
//       data: json['data'] != null && json['data'].toString().length > 5
//           ? (json['data'] as List<dynamic>).map((item) => EncounterData.fromJson(item)).toList()
//           : null,
//     );
//   }
//
//   // 🚩 NEW AWS Format (Direct List: [...]) ke liye
//   factory EncounterListModel.fromRawJsonList(List<dynamic> jsonList) {
//     return EncounterListModel(
//       customStatus: 200, // AWS direct list Success hoti hai
//       message: 'Success',
//       data: jsonList.map((item) => EncounterData.fromJson(item)).toList(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "custom_status": customStatus,
//       "message": message,
//       "data": data?.map((e) => e.toJson()).toList(),
//     };
//   }
// }
//
// class EncounterData {
//   final int sessionId;
//   final String patientName;
//   final String status; // 👈 Changed from 'processing' to 'status'
//   final String patientPhone;
//   final String visitType;
//   final String date;
//   final String age;
//   final String gender;
//   final Map<String, dynamic>? vitals;
//
//   EncounterData({
//     required this.sessionId,
//     required this.patientName,
//     required this.status, // 👈 Update this
//     required this.patientPhone,
//     required this.visitType,
//     required this.date,
//     required this.age,
//     required this.gender,
//     this.vitals,
//   });
//
//   factory EncounterData.fromJson(Map<String, dynamic> json) {
//     return EncounterData(
//       sessionId: json['ID'] ?? json['consultation_id'] ?? 0,
//       patientName: json['patient'] ?? json['patient_name'] ?? '',
//
//       // 🚩 CHANGE HERE: Look for 'status' (as shown in Postman)
//       status: json['status'] ?? json['processing'] ?? 'FINISHED',
//
//       patientPhone: json['patient_phone'] ?? '',
//       visitType: json['visit_type'] ?? 'New',
//       date: json['date'] ?? '',
//       age: (json['patient_age'] ?? json['age'] ?? 'N/A').toString(),
//       gender: json['patient_gender'] ?? json['gender'] ?? 'N/A',
//       vitals: json['vitals'] is Map ? json['vitals'] : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "consultation_id": sessionId,
//       "patient_name": patientName,
//       "status": status, // 👈 Update this
//       "patient_phone": patientPhone,
//       "visit_type": visitType,
//       "date": date,
//       "age": age,
//       "gender": gender,
//       "vitals": vitals,
//     };
//   }
// }
//
//
//
//
// // class EncounterListModel {
// //   final int customStatus;
// //   final String message;
// //   final List<EncounterData>? data;
// //
// //   EncounterListModel({
// //     required this.customStatus,
// //     required this.message,
// //     required this.data,
// //   });
// //
// //   factory EncounterListModel.fromJson(Map<String, dynamic> json) {
// //     return EncounterListModel(
// //       customStatus: json['custom_status'] ?? 0,
// //       message: json['message'] ?? '',
// //       data:   json['data'].toString().length>5 ? (json['data'] as List<dynamic>)
// //           .map((item) => EncounterData.fromJson(item))
// //           .toList():null ,
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       "custom_status": customStatus,
// //       "message": message,
// //       "data": data?.map((e) => e.toJson()).toList(),
// //     };
// //   }
// //
// //   /// Parse from raw string
// //   static EncounterListModel fromRawJson(Map<String, dynamic> str) =>
// //       EncounterListModel.fromJson(str);
// //
// //   /// Convert back to raw JSON string
// //   String toRawJson() => json.encode(toJson());
// // }
// //
// //
// // class EncounterData {
// //   final int sessionId;
// //   final String patientName;
// //   final String processing;
// //   final String visitType;
// //   final String date;
// //   final String age;
// //   final String gender;
// //   final Map<String, dynamic>? vitals; // 🔹 ADD THIS
// //
// //   EncounterData({
// //     required this.sessionId,
// //     required this.patientName,
// //     required this.processing,
// //     required this.visitType,
// //     required this.date,
// //     required this.age,
// //     required this.gender,
// //     this.vitals, // 🔹 ADD THIS
// //   });
// //
// //   factory EncounterData.fromJson(Map<String, dynamic> json) {
// //     return EncounterData(
// //       sessionId: json['consultation_id'] ?? 0,
// //       patientName: json['patient_name'] ?? '',
// //       processing: json['processing'] ?? '',
// //       visitType: json['visit_type'] ?? 'New',
// //       date: json['date'] ?? '',
// //       age: json['age']?.toString() ?? 'N/A', // Handle null age
// //       gender: json['gender'] ?? 'N/A',       // Handle null gender
// //       vitals: json['vitals'] is Map ? json['vitals'] : null, // 🔹 PARSE VITALS
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       "consultation_id": sessionId,
// //       "patient_name": patientName,
// //       "processing": processing,
// //       "visit_type": visitType,
// //       "date": date,
// //       "age": age,
// //       "gender": gender,
// //       "vitals": vitals,
// //     };
// //   }
// // }

import 'dart:convert';

class EncounterListModel {
  final int customStatus;
  final String message;
  final List<EncounterData>? data;

  EncounterListModel({
    required this.customStatus,
    required this.message,
    required this.data,
  });

  factory EncounterListModel.fromJson(Map<String, dynamic> json) {
    return EncounterListModel(
      customStatus: json['custom_status'] ?? json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List<dynamic>).map((item) => EncounterData.fromJson(item)).toList()
          : null,
    );
  }

  // AWS direct list parsing ke liye
  factory EncounterListModel.fromRawJsonList(List<dynamic> jsonList) {
    return EncounterListModel(
      customStatus: 200,
      message: 'Success',
      data: jsonList.map((item) => EncounterData.fromJson(item)).toList(),
    );
  }
}

class EncounterData {
  final int sessionId;
  final String patientName;
  final String status;
  final String patientPhone;
  final String visitType;
  final String date;
  final String age;
  final String gender;
  final Map<String, dynamic>? vitals;

  EncounterData({
    required this.sessionId,
    required this.patientName,
    required this.status,
    required this.patientPhone,
    required this.visitType,
    required this.date,
    required this.age,
    required this.gender,
    this.vitals,
  });

  factory EncounterData.fromJson(Map<String, dynamic> json) {
    // 🚩 SMART DETECTION LOGIC
    // Check karein ke 'patient' key aik Map hai (New API) ya String (Old API)
    final patientRaw = json['patient'];

    String name = "";
    String pAge = "N/A";
    String pGender = "N/A";

    if (patientRaw is Map) {
      // ✅ NEW NESTED API logic (Production)
      name = (patientRaw['name'] ?? "").toString();
      pAge = (patientRaw['age'] ?? "N/A").toString();
      pGender = (patientRaw['gender'] ?? "N/A").toString();
    } else {
      // ✅ OLD FLAT API logic (Development/AWS)
      name = (patientRaw ?? json['patient_name'] ?? "").toString();
      pAge = (json['patient_age'] ?? json['age'] ?? "N/A").toString();
      pGender = (json['patient_gender'] ?? json['gender'] ?? "N/A").toString();
    }

    return EncounterData(
      // ID dono mein different ho sakta hai
      sessionId: json['ID'] ?? json['consultation_id'] ?? 0,

      patientName: name,

      // Status pehle 'status' check karega phir 'processing' (Production ke liye)
      status: (json['processing'] ?? json['status'] ?? 'FINISHED').toString().toUpperCase(),

      patientPhone: (json['patient_phone'] ?? json['phone_number'] ?? "").toString(),
      visitType: (json['visit_type'] ?? 'New').toString(),
      date: (json['date'] ?? "").toString(),
      age: pAge,
      gender: pGender,
      vitals: json['vitals'] is Map ? json['vitals'] : null,
    );
  }
}
