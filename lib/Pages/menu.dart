import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_button.dart';
import 'soundboard_page.dart';

/// =======================================================
/// Color utilities
/// =======================================================

/// Converts a HEX string value to a [Color].
/// If the input is invalid or null, returns [fallback].
Color colorFromHex(dynamic value, Color fallback) {
  if (value == null) return fallback;
  try {
    return Color(
      int.parse(value.toString().replaceFirst('#', '0xff')),
    );
  } catch (_) {
    return fallback;
  }
}

/// Converts a [Color] object to a HEX string in RRGGBB format.
String colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$r$g$b';
}

/// =======================================================
/// Menu screen
/// Displays all soundboards and handles creation/editing
/// =======================================================

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  /// List of all soundboard buttons in the menu.
  /// Each button contains id, text, colors, icon path, and grid configuration.
  List<Map<String, dynamic>> buttons = [];

  /// Overlay used for editing or creating new soundboard buttons.
  OverlayEntry? _editorOverlay;

  /// Returns true if the given [path] is an asset, false if it's a local file path.
  bool isAsset(String path) {
    return !(path.startsWith('/') || path.contains('storage'));
  }

  @override
  void initState() {
    super.initState();
    // Loads buttons from local storage or default JSON asset on app start
    loadButtons();
  }

  /// =======================================================
  /// Editor Overlay
  /// Displays a modal to create or edit soundboard buttons
  /// =======================================================

  void _showEditorOverlay({Map<String, dynamic>? buttonData}) {
    if (_editorOverlay != null) return;

    final overlay = Overlay.of(context);

    // Initialize default or existing values
    int gridColumns = buttonData?['gridColumns'] ?? 2;
    Color backgroundColor =
        colorFromHex(buttonData?['backgroundColor'], Colors.black);
    Color borderColor =
        colorFromHex(buttonData?['borderColor'], Colors.deepPurpleAccent);
    Color textColor =
        colorFromHex(buttonData?['textColor'], Colors.white);

    final nameController = TextEditingController(
      text: buttonData?['text'] ?? '',
    );

    String imagePath = buttonData?['icon'] ?? 'assets/xd.png';
    File? pickedImage;

    _editorOverlay = OverlayEntry(
      builder: (_) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return Stack(
            children: [
              /// Background with blur effect
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeOverlay,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              /// Editor modal container
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: borderColor, width: 4),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          /// Modal title
                          Text(
                            buttonData != null
                                ? 'Edit soundboard'
                                : 'Create soundboard',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          /// Icon selection
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                pickedImage = File(image.path);
                                imagePath = image.path;
                                setOverlayState(() {});
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: pickedImage != null
                                  ? Image.file(pickedImage!,
                                      width: 60, height: 60)
                                  : isAsset(imagePath)
                                      ? Image.asset(imagePath,
                                          width: 60, height: 60)
                                      : Image.file(File(imagePath),
                                          width: 60, height: 60),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Text input for button name
                          TextField(
                            controller: nameController,
                            style: TextStyle(color: textColor),
                            decoration:
                                _inputDecoration(borderColor, textColor),
                          ),

                          const SizedBox(height: 12),

                          /// Grid column selector
                          Text('Grid columns: $gridColumns',
                              style: const TextStyle(color: Colors.white)),
                          Slider(
                            value: gridColumns.toDouble(),
                            min: 1,
                            max: 4,
                            divisions: 3,
                            activeColor: borderColor,
                            onChanged: (v) =>
                                setOverlayState(() => gridColumns = v.toInt()),
                          ),

                          const SizedBox(height: 12),

                          /// Color pickers
                          _colorPicker('Background color', (c) {
                            backgroundColor = c;
                          }),
                          _colorPicker('Border color', (c) {
                            borderColor = c;
                          }),
                          _colorPicker('Text color', (c) {
                            textColor = c;
                          }),

                          const SizedBox(height: 16),

                          /// Actions: delete, cancel, save
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (buttonData != null)
                                TextButton(
                                  onPressed: () {
                                    buttons.removeWhere(
                                        (b) => b['id'] == buttonData['id']);
                                    saveButtons();
                                    _closeOverlay();
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _closeOverlay,
                                    child: Text('Cancel',
                                        style: TextStyle(color: textColor)),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      _saveButton(
                                        buttonData,
                                        nameController.text.trim(),
                                        imagePath,
                                        gridColumns,
                                        backgroundColor,
                                        borderColor,
                                        textColor,
                                      );
                                      _closeOverlay();
                                    },
                                    child: Text('Save',
                                        style: TextStyle(color: textColor)),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    overlay.insert(_editorOverlay!);
  }

  /// Closes the overlay editor and refreshes the menu state.
  void _closeOverlay() {
    _editorOverlay?.remove();
    _editorOverlay = null;
    setState(() {});
  }

  /// =======================================================
  /// Persistence methods
  /// =======================================================

  /// Loads buttons from SharedPreferences. If none exist, loads defaults from JSON asset.
  Future<void> loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('buttons');

    if (saved != null) {
      buttons = List<Map<String, dynamic>>.from(json.decode(saved));
    } else {
      final jsonString =
          await rootBundle.loadString('assets/menu_buttons.json');
      buttons =
          List<Map<String, dynamic>>.from(json.decode(jsonString));
      await saveButtons();
    }

    // Ensure buttons are sorted by ID
    buttons.sort((a, b) => a['id'].compareTo(b['id']));
    setState(() {});
  }

  /// Saves the current list of buttons to SharedPreferences as JSON string.
  Future<void> saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buttons', json.encode(buttons));
  }

  /// =======================================================
  /// Navigation methods
  /// =======================================================

  /// Opens the soundboard page for a given button ID and updates data on return.
  void handlePress(int id) async {
    final index = buttons.indexWhere((b) => b['id'] == id);
    if (index == -1) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoundboardPage(menuData: buttons[index]),
      ),
    );

    if (updated != null) {
      buttons[index] = updated;
      await saveButtons();
      setState(() {});
    }
  }

  /// =======================================================
  /// UI
  /// =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset(
          'assets/Amongus_Logo_W_Apce.png',
          height: 70,
        ),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: buttons.length + 1,
        onReorder: _onReorder,
        itemBuilder: _buildItem,
      ),
    );
  }

  /// Handles reordering of buttons in the list
  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex >= buttons.length) return;
    if (newIndex > oldIndex) newIndex--;
    final item = buttons.removeAt(oldIndex);
    buttons.insert(newIndex, item);

    // Update IDs after reorder
    for (int i = 0; i < buttons.length; i++) {
      buttons[i]['id'] = i;
    }

    await saveButtons();
    setState(() {});
  }

  /// Builds individual items in the ReorderableListView
  Widget _buildItem(BuildContext context, int index) {
    if (index == buttons.length) {
      return ElevatedButton(
        onPressed: handleAddPress,
        child: const Text('+', style: TextStyle(fontSize: 36)),
      );
    }

    final btn = buttons[index];

    return CustomButton(
      id: btn['id'],
      text: btn['text'],
      icon: btn['icon'],
      backgroundColor:
          colorFromHex(btn['backgroundColor'], Colors.black),
      borderColor:
          colorFromHex(btn['borderColor'], Colors.deepPurpleAccent),
      textColor:
          colorFromHex(btn['textColor'], Colors.white),
      onPressed: () => handlePress(btn['id']),
      onLongPress: () => _showEditorOverlay(buttonData: btn),
    );
  }

  /// Opens overlay to add a new button
  void handleAddPress() => _showEditorOverlay();

  /// =======================================================
  /// UI helpers
  /// =======================================================

  InputDecoration _inputDecoration(Color border, Color textColor) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border, width: 2),
      ),
      hintText: 'Name',
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
    );
  }

  /// Renders a color picker row for selecting background, border, or text color.
  Widget _colorPicker(String label, Function(Color) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Row(
          children: [
            for (final color in [
              Colors.black,
              Colors.deepPurpleAccent,
              Colors.orange,
              Colors.yellow,
              Colors.blue,
              Colors.green,
              Colors.white,
            ])
              _colorButton(color, onPick),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Individual color button used inside _colorPicker
  Widget _colorButton(Color color, Function(Color) onTap) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white),
        ),
      ),
    );
  }

  /// Saves a new or existing button configuration
  Future<void> _saveButton(
    Map<String, dynamic>? existing,
    String name,
    String icon,
    int columns,
    Color background,
    Color border,
    Color text,
  ) async {
    final data = {
      'text': name.isEmpty ? 'Name' : name,
      'icon': icon,
      'gridColumns': columns,
      'backgroundColor': '#${colorToHex(background)}',
      'borderColor': '#${colorToHex(border)}',
      'textColor': '#${colorToHex(text)}',
    };

    if (existing != null) {
      final index =
          buttons.indexWhere((b) => b['id'] == existing['id']);
      buttons[index] = {...existing, ...data};
    } else {
      buttons.add({
        'id': buttons.length,
        ...data,
      });
    }

    await saveButtons();
    setState(() {});
  }
}
