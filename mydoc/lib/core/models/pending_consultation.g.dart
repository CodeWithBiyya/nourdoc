// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_consultation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingConsultationAdapter extends TypeAdapter<PendingConsultation> {
  @override
  final int typeId = 1;

  @override
  PendingConsultation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingConsultation(
      patientName: fields[1] as String,
      gender: fields[2] as String,
      age: fields[3] as String,
      dob: fields[4] as String,
      visitType: fields[5] as String,
      audioPath: fields[6] as String,
      startTime: fields[7] as DateTime,
      endTime: fields[8] as DateTime,
      temp: fields[9] as String,
      pulse: fields[10] as String,
      resp: fields[11] as String,
      bp: fields[12] as String,
      sugar: fields[13] as String,
      token: fields[14] as String,
      patientPhone: fields[0] as String,
      isSyncing: fields[15] as bool,
      patientId: fields[16] as String?,
      bookingId: fields[18] as String?,
    )..s3Headers = (fields[17] as Map?)?.cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, PendingConsultation obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.patientPhone)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.dob)
      ..writeByte(5)
      ..write(obj.visitType)
      ..writeByte(6)
      ..write(obj.audioPath)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.endTime)
      ..writeByte(9)
      ..write(obj.temp)
      ..writeByte(10)
      ..write(obj.pulse)
      ..writeByte(11)
      ..write(obj.resp)
      ..writeByte(12)
      ..write(obj.bp)
      ..writeByte(13)
      ..write(obj.sugar)
      ..writeByte(14)
      ..write(obj.token)
      ..writeByte(15)
      ..write(obj.isSyncing)
      ..writeByte(16)
      ..write(obj.patientId)
      ..writeByte(17)
      ..write(obj.s3Headers)
      ..writeByte(18)
      ..write(obj.bookingId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingConsultationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
