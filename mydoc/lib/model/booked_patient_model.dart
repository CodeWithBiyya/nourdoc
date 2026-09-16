import 'dart:convert';

import 'BookedPatientData.dart';

class BookedPatientListModel {
  final int customStatus;
  final String message;
  final List<BookedPatientData>? data;

  BookedPatientListModel({
    required this.customStatus,
    required this.message,
    this.data,
  });

  factory BookedPatientListModel.fromJson(Map<String, dynamic> json) {
    return BookedPatientListModel(
      customStatus: json['custom_status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List).map((i) => BookedPatientData.fromJson(i)).toList()
          : null,
    );
  }
}
