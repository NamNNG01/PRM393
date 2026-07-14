// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'winning_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WinningResultAdapter extends TypeAdapter<WinningResult> {
  @override
  final int typeId = 8;

  @override
  WinningResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WinningResult(
      businessDate: fields[0] as String,
      ticketType: fields[1] as String,
      winningNumbers: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WinningResult obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.businessDate)
      ..writeByte(1)
      ..write(obj.ticketType)
      ..writeByte(2)
      ..write(obj.winningNumbers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WinningResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
