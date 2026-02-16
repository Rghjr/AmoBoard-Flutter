// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_button.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuButtonAdapter extends TypeAdapter<MenuButton> {
  @override
  final int typeId = 0;

  @override
  MenuButton read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuButton(
      id: fields[0] as int,
      text: fields[1] as String,
      icon: fields[2] as String,
      gridColumns: fields[3] as int,
      backgroundColor: fields[4] as String,
      backgroundColorLightness: fields[5] as int,
      borderColor: fields[6] as String,
      borderColorLightness: fields[7] as int,
      textColor: fields[8] as String,
      textColorLightness: fields[9] as int,
      sounds: (fields[10] as List).cast<SoundData>(),
      buttonRadius: fields[11] as double?,
      fontSize: fields[12] as double?,
      earrapeEnabled: fields[13] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MenuButton obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.gridColumns)
      ..writeByte(4)
      ..write(obj.backgroundColor)
      ..writeByte(5)
      ..write(obj.backgroundColorLightness)
      ..writeByte(6)
      ..write(obj.borderColor)
      ..writeByte(7)
      ..write(obj.borderColorLightness)
      ..writeByte(8)
      ..write(obj.textColor)
      ..writeByte(9)
      ..write(obj.textColorLightness)
      ..writeByte(10)
      ..write(obj.sounds)
      ..writeByte(11)
      ..write(obj.buttonRadius)
      ..writeByte(12)
      ..write(obj.fontSize)
      ..writeByte(13)
      ..write(obj.earrapeEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuButtonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
