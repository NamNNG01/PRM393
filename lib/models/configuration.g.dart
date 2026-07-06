// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuration.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfigurationAdapter extends TypeAdapter<Configuration> {
  @override
  final int typeId = 1;

  @override
  Configuration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Configuration(
      ticketPriceA: fields[0] as double,
      refundRateA: fields[1] as double,
      commissionRateA: fields[2] as double,
      ticketPriceB: fields[3] as double,
      refundRateB: fields[4] as double,
      commissionPerPointB: fields[5] as double,
      maxRiskMultiplier: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Configuration obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.ticketPriceA)
      ..writeByte(1)
      ..write(obj.refundRateA)
      ..writeByte(2)
      ..write(obj.commissionRateA)
      ..writeByte(3)
      ..write(obj.ticketPriceB)
      ..writeByte(4)
      ..write(obj.refundRateB)
      ..writeByte(5)
      ..write(obj.commissionPerPointB)
      ..writeByte(6)
      ..write(obj.maxRiskMultiplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigurationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
