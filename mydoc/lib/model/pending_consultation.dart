import 'package:hive/hive.dart';

part 'pending_consultation.g.dart';

@HiveType(typeId: 1)
class PendingConsultation extends HiveObject {

  @HiveField(0)
  final String patientPhone;

  @HiveField(1)
  final String patientName;

  @HiveField(2)
  final String gender;

  @HiveField(3)
  final String age;


  @HiveField(4)
  final String dob;

  @HiveField(5)
  final String visitType;

  @HiveField(6)
  final String audioPath;

  @HiveField(7)
  final DateTime startTime;

  @HiveField(8)
  final DateTime endTime;

  @HiveField(9)
  final String temp;

  @HiveField(10)
  final String pulse;

  @HiveField(11)
  final String resp;

  @HiveField(12)
  final String bp;

  @HiveField(13)
  final String sugar;

  @HiveField(14)
  final String token;

  @HiveField(15)
   bool isSyncing;

  @HiveField(16)
  final String? patientId;

  @HiveField(17)
  Map<String, String>? s3Headers;

  @HiveField(18)
  final String? bookingId;



  PendingConsultation({
    required this.patientName,
    required this.gender,
    required this.age,
    required this.dob,
    required this.visitType,
    required this.audioPath,
    required this.startTime,
    required this.endTime,
    required this.temp,
    required this.pulse,
    required this.resp,
    required this.bp,
    required this.sugar,
    required this.token,
    required this.patientPhone, // 🚩 Added this
    this.isSyncing = false, // 🚩 ADD THIS: Default to false
    this.patientId, // 🚩 Re-added
    this.bookingId,


  });

int get durationSeconds {
    final value =
        endTime.difference(startTime).inSeconds;

    return value > 0 ? value : 1;
  }

  /// 🔹 ADD THIS: Convert Object to Map for sending between Isolates
  Map<String, dynamic> toJson(dynamic hiveKey) {
    return {
      'hiveKey': hiveKey, // We pass the key so the service can tell Main to delete it later
      'patientName': patientName,
      'gender': gender,
      'age': age,

      'dob': dob,
      'visitType': visitType,
      'audioPath': audioPath,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'temp': temp,
      'pulse': pulse,
      'resp': resp,
      'bp': bp,
      'sugar': sugar,
      'token': token,
      'patientPhone': patientPhone, // 🚩 Added this
      'isSyncing': isSyncing, // 🚩 Added for consistency

      'patient_id': patientId, // 🚩 Include in Map
      'booking_id': bookingId,

    };
  }

  /// 🔹 ADD THIS: Create Object from Map (Used by the Background Service)
  factory PendingConsultation.fromJson(Map<String, dynamic> json) {
    return PendingConsultation(
      patientName: json['patientName'] ?? "",
      gender: json['gender'] ?? "",
      age: json['age'] ?? "",
      dob: json['dob'] ?? "",
      visitType: json['visitType'] ?? "",
      audioPath: json['audioPath'] ?? "",
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      temp: json['temp'] ?? "",
      pulse: json['pulse'] ?? "",
      resp: json['resp'] ?? "",
      bp: json['bp'] ?? "",
      sugar: json['sugar'] ?? "",
      token: json['token'] ?? "",
      patientPhone: json['patientPhone'] ?? "", // 🚩 Added this
      isSyncing: json['isSyncing'] ?? false, // 🚩 Added for consistency

      patientId: json['patient_id'],
      bookingId: json['booking_id'], // 🚩 Re-added


    );
  }
}

