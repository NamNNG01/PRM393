// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'winning_ticket.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WinningTicketAdapter extends TypeAdapter<WinningTicket> {
  @override
  final int typeId = 10;

  @override
  WinningTicket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WinningTicket(
      ticketId: fields[0] as String,
      customerId: fields[1] as String,
      businessDate: fields[2] as String,
      winningNumber: fields[3] as String,
      ticketType: fields[9] as String,
      orderValue: fields[10] as double,
      payoutAmount: fields[11] as double,
      paid: fields[4] as bool,
      paidAt: fields[5] as DateTime?,
      proofImageBytes: fields[6] as Uint8List?,
      proofFile: fields[8] as String?,
      note: fields[7] as String?,
      multiplier: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WinningTicket obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.ticketId)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.businessDate)
      ..writeByte(3)
      ..write(obj.winningNumber)
      ..writeByte(4)
      ..write(obj.paid)
      ..writeByte(5)
      ..write(obj.paidAt)
      ..writeByte(6)
      ..write(obj.proofImageBytes)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.proofFile)
      ..writeByte(9)
      ..write(obj.ticketType)
      ..writeByte(10)
      ..write(obj.orderValue)
      ..writeByte(11)
      ..write(obj.payoutAmount)
      ..writeByte(12)
      ..write(obj.multiplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WinningTicketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
