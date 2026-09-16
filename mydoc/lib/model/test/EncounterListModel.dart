/// session_id : 6
/// patient_name : "Osama"
/// processing : "FINISHED"

class EncounterListModel {
  EncounterListModel({
      num? sessionId, 
      String? patientName, 
      String? processing,}){
    _sessionId = sessionId;
    _patientName = patientName;
    _processing = processing;
}

  EncounterListModel.fromJson(dynamic json) {
    _sessionId = json['session_id'];
    _patientName = json['patient_name'];
    _processing = json['processing'];
  }
  num? _sessionId;
  String? _patientName;
  String? _processing;
EncounterListModel copyWith({  num? sessionId,
  String? patientName,
  String? processing,
}) => EncounterListModel(  sessionId: sessionId ?? _sessionId,
  patientName: patientName ?? _patientName,
  processing: processing ?? _processing,
);
  num? get sessionId => _sessionId;
  String? get patientName => _patientName;
  String? get processing => _processing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['session_id'] = _sessionId;
    map['patient_name'] = _patientName;
    map['processing'] = _processing;
    return map;
  }

}