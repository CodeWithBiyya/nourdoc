import 'dart:convert';

class EncounterInformationModel {
  final int customStatus;
  final String message;
  final EncounterData data;

  EncounterInformationModel({
    required this.customStatus,
    required this.message,
    required this.data,
  });

  factory EncounterInformationModel.fromJson(Map<String, dynamic> json) {
    // 🚩 CHECK: Agar JSON mein 'data' key nahi hai, to poora JSON hi 'data' hai
    bool isFlatJson = !json.containsKey('data');

    return EncounterInformationModel(
      customStatus: isFlatJson ? 200 : (json['custom_status'] ?? 0),
      message: isFlatJson ? 'Success' : (json['message'] ?? ''),
      // 🚩 Agar flat hai to poora json bhej dein, warna json['data'] bhejein
      data: EncounterData.fromJson(isFlatJson ? json : (json['data'] ?? {})),
    );
  }
}

class EncounterData {
  final String transcription;
  final String soap;
  final String complaint;
  final String date;
  final String patientName;
  final String audioPath;
  final Map<String, dynamic> highlights;
  final Map<String, dynamic> vitals;
  final String duration;
  final String processing;
  final String patientAge;
  final String patientGender;
  final String icd;

  EncounterData({
    required this.transcription,
    required this.soap,
    required this.complaint,
    required this.date,
    required this.patientName,
    required this.audioPath,
    required this.highlights,
    required this.vitals,
    required this.duration,
    required this.processing,
    required this.patientAge,
    required this.patientGender,
    required this.icd,
  });

  factory EncounterData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> highlightsMap = json['highlights'] is Map ? json['highlights'] : {};

    // --- PATIENT DATA EXTRACTION LOGIC ---
    String pName = 'N/A';
    String pAge = 'N/A';
    String pGender = 'N/A';

    // Check if 'patient' is an object (Production API)
    if (json['patient'] is Map) {
      var p = json['patient'];
      pName = p['name']?.toString() ?? 'N/A';
      pAge = p['age']?.toString() ?? 'N/A';
      pGender = p['gender']?.toString() ?? 'N/A';
    }
    // Otherwise check flat fields (AWS/Dev API)
    else {
      pName = json['patient_name']?.toString() ?? json['patient']?.toString() ?? 'N/A';
      pAge = json['patient_age']?.toString() ?? json['age']?.toString() ?? 'N/A';
      pGender = json['patient_gender']?.toString() ?? json['gender']?.toString() ?? 'N/A';
    }

    String extractedComplaint = json['complaint'] ?? '';
    if (extractedComplaint.isEmpty || extractedComplaint == "N/A") {
      extractedComplaint = highlightsMap['Complaint'] ?? highlightsMap['complaint'] ?? 'Not specified';
    }

    return EncounterData(
      transcription: json['transcription']?.toString() ?? '',
      soap: json['soap']?.toString() ?? '',
      complaint: extractedComplaint,
      date: json['date']?.toString() ?? '',
      patientName: pName,
      patientAge: pAge,
      patientGender: pGender,
      audioPath: json['audio_path'] ?? json['audio_url'] ?? '',
      highlights: highlightsMap,
      vitals: json['vitals'] is Map ? json['vitals'] : {},
      duration: json['duration']?.toString() ?? '',
      processing: json['processing']?.toString() ?? 'FINISHED',
      icd: json['icd']?.toString() ?? '',
    );
  }
}

// import 'dart:convert';
//
//
// class EncounterInformationModel {
//   final int customStatus;
//   final String message;
//   final EncounterData data;
//
//   EncounterInformationModel({
//     required this.customStatus,
//     required this.message,
//     required this.data,
//   });
//
//   factory EncounterInformationModel.fromJson(Map<String, dynamic> json) {
//     return EncounterInformationModel(
//       customStatus: json['custom_status'] ?? 0,
//       message: json['message'] ?? '',
//       data: EncounterData.fromJson(json['data'] ?? {}),
//     );
//   }
// }
// class EncounterData {
//   final String transcription;
//   final String soap;
//   final String complaint;
//   final String date;
//   final String patientName;
//   final String audioPath;
//   final Map<String, dynamic> highlights;
//   final Map<String, dynamic> vitals;
//   final String duration;
//   final String processing;
//   // 🔹 New Fields
//   final String patientAge;
//   final String patientGender;
//   final String icd;
//
//   EncounterData({
//     required this.transcription,
//     required this.soap,
//     required this.complaint,
//     required this.date,
//     required this.patientName,
//     required this.audioPath,
//     required this.highlights,
//     required this.vitals,
//     required this.duration,
//     required this.processing,
//     required this.patientAge,
//     required this.patientGender,
//     required this.icd,
//   });
//
//   factory EncounterData.fromJson(Map<String, dynamic> json) {
//     final Map<String, dynamic> highlightsMap = json['highlights'] is Map ? json['highlights'] : {};
//
//     String extractedComplaint = json['complaint'] ?? '';
//     if (extractedComplaint.isEmpty || extractedComplaint == "N/A") {
//       extractedComplaint = highlightsMap['Complaint'] ?? highlightsMap['complaint'] ?? 'Not specified';
//     }
//
//     return EncounterData(
//       transcription: json['transcription'] ?? '',
//       soap: json['soap'] ?? '',
//       complaint: extractedComplaint,
//       date: json['date'] ?? '',
//       patientName: json['patient_name'] ?? '',
//       audioPath: json['audio_path'] ?? json['audio_url'] ?? '',
//       highlights: highlightsMap,
//       vitals: json['vitals'] is Map ? json['vitals'] : {},
//       duration: json['duration'] ?? '',
//       processing: json['processing'] ?? 'FINISHED',
//       // 🔹 Map new fields and handle nulls
//       patientAge: json['patient_age']?.toString() ?? 'N/A',
//       patientGender: json['patient_gender']?.toString() ?? 'N/A',
//       icd: json['icd']?.toString() ?? '',
//     );
//   }
// }
