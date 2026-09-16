import 'dart:convert';

class BookedPatientData {
  final String patientId;
  final String bookingId;
  final String patientName;
  final String patientPhone;
  final String age;
  final String gender;
  final String date;

  // Vitals
  final String temp;
  final String pulse;
  final String resp_rate;
  final String bp;
  final String sugar;

  BookedPatientData({
    required this.patientId,
    required this.bookingId,
    required this.patientName,
    required this.patientPhone,
    required this.age,
    required this.gender,
    required this.date,
    required this.temp,
    required this.pulse,
    required this.resp_rate,
    required this.bp,
    required this.sugar,
  });

  factory BookedPatientData.fromJson(Map<String, dynamic> json) {
    // 1. Patient object ko extract karein (Nested Data)
    var patient = json['patient'] ?? {};

    // 2. Vitals object ko extract karein
    var vitals = json['vitals'] ?? {};

    return BookedPatientData(
      // Top level keys
      bookingId: (json['id'] ?? "").toString(),
      date: (json['booked_on'] ?? "").toString(),

      // Nested Patient object keys (Yahan masla tha)
      patientId: (json['patient_id'] ?? "").toString(), // Agar API mein alag hai toh dekh lein
      patientName: (patient['name'] ?? "").toString(),
      age: (patient['age'] ?? "").toString(),
      gender: (patient['gender'] ?? "").toString(),
      patientPhone: (json['patient_phone'] ?? "").toString(), // Check if this is in root or patient object

      // Vitals mapping (Exactly as per your Postman screenshot)
      temp: (vitals['Temperature'] ?? "").toString(),
      pulse: (vitals['Pulse'] ?? "").toString(),
      resp_rate: (vitals['Respiration'] ?? "").toString(),
      bp: (vitals['Blood Pressure'] ?? "").toString(),
      sugar: (vitals['Sugar'] ?? "").toString(),
    );
  }
}