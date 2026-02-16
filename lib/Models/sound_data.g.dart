// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SoundDataAdapter extends TypeAdapter<SoundData> {
  @override
  final int typeId = 1;

  @override
  SoundData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SoundData(
      id: fields[0] as int,
      label: fields[1] as String,
      iconPath: fields[2] as String,
      soundPath: fields[3] as String,
      volume: fields[4] as double,
      borderColor: fields[5] as String,
      borderColorLightness: fields[6] as int,
      backgroundColor: fields[7] as String,
      backgroundColorLightness: fields[8] as int,
      textColor: fields[9] as String,
      textColorLightness: fields[10] as int,
      textSize: fields[11] as double,
      startTime: fields[12] as double?,
      endTime: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SoundData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.iconPath)
      ..writeByte(3)
      ..write(obj.soundPath)
      ..writeByte(4)
      ..write(obj.volume)
      ..writeByte(5)
      ..write(obj.borderColor)
      ..writeByte(6)
      ..write(obj.borderColorLightness)
      ..writeByte(7)
      ..write(obj.backgroundColor)
      ..writeByte(8)
      ..write(obj.backgroundColorLightness)
      ..writeByte(9)
      ..write(obj.textColor)
      ..writeByte(10)
      ..write(obj.textColorLightness)
      ..writeByte(11)
      ..write(obj.textSize)
      ..writeByte(12)
      ..write(obj.startTime)
      ..writeByte(13)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
