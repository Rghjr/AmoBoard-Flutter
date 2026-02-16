import 'package:hive/hive.dart';
import 'sound_data.dart';

part 'menu_button.g.dart';

/// Data model representing a menu button (soundboard panel).
/// 
/// Each MenuButton represents a complete soundboard with its own visual theme,
/// layout configuration, and collection of sounds. Persisted to Hive local database.
/// 
/// Color system: Each color property has a base hex value and a separate lightness
/// offset field (-25 to +25) to allow fine-tuned brightness adjustments.
@HiveType(typeId: 0)
class MenuButton extends HiveObject {
  /// Unique identifier used as Hive key and for list ordering.
  @HiveField(0)
  int id;

  /// Display text shown on the menu button.
  @HiveField(1)
  String text;

  /// Path to icon image (asset path or device file path).
  @HiveField(2)
  String icon;

  /// Number of columns in the soundboard grid layout (typically 1-5).
  @HiveField(3)
  int gridColumns;

  /// Background color as hex string (e.g., "#000000").
  @HiveField(4)
  String backgroundColor;

  /// Brightness adjustment for background (-25 to +25 percentage points).
  @HiveField(5)
  int backgroundColorLightness;

  /// Border color as hex string (e.g., "#7A30FF").
  @HiveField(6)
  String borderColor;

  /// Brightness adjustment for border (-25 to +25 percentage points).
  @HiveField(7)
  int borderColorLightness;

  /// Text color as hex string (e.g., "#FFFFFF").
  @HiveField(8)
  String textColor;

  /// Brightness adjustment for text (-25 to +25 percentage points).
  @HiveField(9)
  int textColorLightness;

  /// List of sound buttons in this soundboard.
  @HiveField(10)
  List<SoundData> sounds;

  /// Corner radius for sound buttons (optional, default used if null).
  @HiveField(11)
  double? buttonRadius;

  /// Font size for sound button labels (optional, default used if null).
  @HiveField(12)
  double? fontSize;

  /// Whether volume amplification mode is enabled (optional, default false).
  @HiveField(13)
  bool? earrapeEnabled;

  MenuButton({
    required this.id,
    required this.text,
    required this.icon,
    required this.gridColumns,
    required this.backgroundColor,
    required this.backgroundColorLightness,
    required this.borderColor,
    required this.borderColorLightness,
    required this.textColor,
    required this.textColorLightness,
    required this.sounds,
    this.buttonRadius,
    this.fontSize,
    this.earrapeEnabled,
  });

  /// Creates a MenuButton from a Map representation.
  /// 
  /// Handles nested SoundData objects and provides default values
  /// for all fields to ensure safe deserialization.
  factory MenuButton.fromMap(Map<String, dynamic> map) {
    List<SoundData> soundsList = [];
    if (map['sounds'] != null) {
      soundsList = (map['sounds'] as List)
          .map((soundMap) => SoundData.fromMap(soundMap as Map<String, dynamic>))
          .toList();
    }

    return MenuButton(
      id: map['id'] ?? 0,
      text: map['text'] ?? 'Nowy Przycisk',
      icon: map['icon'] ?? 'assets/xd.png',
      gridColumns: map['gridColumns'] ?? 2,
      backgroundColor: map['backgroundColor'] ?? '#000000',
      backgroundColorLightness: map['backgroundColor_lightness'] ?? 0,
      borderColor: map['borderColor'] ?? '#7A30FF',
      borderColorLightness: map['borderColor_lightness'] ?? 0,
      textColor: map['textColor'] ?? '#FFFFFF',
      textColorLightness: map['textColor_lightness'] ?? 0,
      sounds: soundsList,
      buttonRadius: map['buttonRadius']?.toDouble(),
      fontSize: map['fontSize']?.toDouble(),
      earrapeEnabled: map['earrapeEnabled'],
    );
  }

  /// Converts this MenuButton to a Map representation.
  /// 
  /// Recursively converts nested SoundData objects and only includes
  /// optional fields if they have non-null values.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'icon': icon,
      'gridColumns': gridColumns,
      'backgroundColor': backgroundColor,
      'backgroundColor_lightness': backgroundColorLightness,
      'borderColor': borderColor,
      'borderColor_lightness': borderColorLightness,
      'textColor': textColor,
      'textColor_lightness': textColorLightness,
      'sounds': sounds.map((s) => s.toMap()).toList(),
      if (buttonRadius != null) 'buttonRadius': buttonRadius,
      if (fontSize != null) 'fontSize': fontSize,
      if (earrapeEnabled != null) 'earrapeEnabled': earrapeEnabled,
    };
  }
}