import 'package:hive/hive.dart';

part 'sound_data.g.dart';

/// Data model representing a single sound button within a soundboard.
/// 
/// Contains all information needed to display and play a sound: visual appearance,
/// audio file path, playback settings, and optional time-based clipping for playing
/// only a segment of the audio file.
/// 
/// Color system: Same as MenuButton - base hex color + lightness offset for each color property.
@HiveType(typeId: 1)
class SoundData extends HiveObject {
  /// Unique identifier within the parent soundboard.
  @HiveField(0)
  int id;

  /// Display text shown on the sound button.
  @HiveField(1)
  String label;

  /// Path to button icon (asset path or device file path).
  @HiveField(2)
  String iconPath;

  /// Path to audio file to play (asset path or device file path).
  @HiveField(3)
  String soundPath;

  /// Playback volume multiplier (0.0 to 2.0, can go higher with earrape mode).
  @HiveField(4)
  double volume;

  /// Border color as hex string.
  @HiveField(5)
  String borderColor;

  /// Brightness adjustment for border (-25 to +25 percentage points).
  @HiveField(6)
  int borderColorLightness;

  /// Background color as hex string.
  @HiveField(7)
  String backgroundColor;

  /// Brightness adjustment for background (-25 to +25 percentage points).
  @HiveField(8)
  int backgroundColorLightness;

  /// Text color as hex string.
  @HiveField(9)
  String textColor;

  /// Brightness adjustment for text (-25 to +25 percentage points).
  @HiveField(10)
  int textColorLightness;

  /// Font size for button label.
  @HiveField(11)
  double textSize;

  /// Optional start time in seconds for audio clipping (null means start from beginning).
  @HiveField(12)
  double? startTime;

  /// Optional end time in seconds for audio clipping (null means play to end).
  @HiveField(13)
  double? endTime;

  SoundData({
    required this.id,
    required this.label,
    required this.iconPath,
    required this.soundPath,
    required this.volume,
    required this.borderColor,
    required this.borderColorLightness,
    required this.backgroundColor,
    required this.backgroundColorLightness,
    required this.textColor,
    required this.textColorLightness,
    required this.textSize,
    this.startTime,
    this.endTime,
  });

  /// Creates a SoundData from a Map representation.
  /// 
  /// Provides default values for all fields to ensure safe deserialization.
  factory SoundData.fromMap(Map<String, dynamic> map) {
    return SoundData(
      id: map['id'] ?? 0,
      label: map['label'] ?? 'Nowy Dźwięk',
      iconPath: map['iconPath'] ?? 'assets/xd.png',
      soundPath: map['soundPath'] ?? '',
      volume: (map['volume'] ?? 1.0).toDouble(),
      borderColor: map['borderColor'] ?? '#FFFFFF',
      borderColorLightness: map['borderColor_lightness'] ?? 0,
      backgroundColor: map['backgroundColor'] ?? '#000000',
      backgroundColorLightness: map['backgroundColor_lightness'] ?? 0,
      textColor: map['textColor'] ?? '#FFFFFF',
      textColorLightness: map['textColor_lightness'] ?? 0,
      textSize: (map['textSize'] ?? 16.0).toDouble(),
      startTime: map['startTime']?.toDouble(),
      endTime: map['endTime']?.toDouble(),
    );
  }

  /// Converts this SoundData to a Map representation.
  /// 
  /// Only includes optional time clipping fields if they have non-null values.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'iconPath': iconPath,
      'soundPath': soundPath,
      'volume': volume,
      'borderColor': borderColor,
      'borderColor_lightness': borderColorLightness,
      'backgroundColor': backgroundColor,
      'backgroundColor_lightness': backgroundColorLightness,
      'textColor': textColor,
      'textColor_lightness': textColorLightness,
      'textSize': textSize,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
    };
  }
}