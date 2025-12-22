import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_button.dart';
import 'soundboard_page.dart';

/// =======================
/// 🔧 UTILSY KOLORÓW
/// =======================

/// Zamienia HEX zapisany jako String na Color
/// Jak coś się spierdoli → fallback
Color colorFromHex(dynamic value, Color fallback) {
  if (value == null) return fallback;
  try {
    return Color(
      int.parse(value.toString().replaceFirst("#", "0xff")),
    );
  } catch (_) {
    return fallback;
  }
}

/// Zamienia Color → hex RRGGBB (bez #)
String colorToHex(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$r$g$b';
}

/// =======================
/// 📋 MENU – LISTA SOUNDBOARDÓW
/// =======================

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  /// Lista wszystkich soundboardów (menu buttons)
  List<Map<String, dynamic>> buttons = [];

  /// Overlay do edycji/dodawania
  OverlayEntry? _editorOverlay;

  /// Sprawdza czy ikona jest assetem czy plikiem z telefonu
  bool isAsset(String path) {
    return !(path.startsWith('/') || path.contains('storage'));
  }

  @override
  void initState() {
    super.initState();
    loadButtons();
  }

  /// =======================
  /// ✏️ OVERLAY EDYTORA
  /// =======================

  void _showEditorOverlay({Map<String, dynamic>? buttonData}) {
    if (_editorOverlay != null) return;

    final overlay = Overlay.of(context);

    // Wczytaj dane albo ustaw defaulty
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
              /// Tło + blur
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

              /// Okno edytora
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
                        children: [
                          /// Tytuł
                          Text(
                            buttonData != null
                                ? "Edytuj przycisk"
                                : "Dodaj nowy przycisk",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Ikona
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

                          /// Nazwa
                          TextField(
                            controller: nameController,
                            style: TextStyle(color: textColor),
                            decoration: _inputDecoration(
                                borderColor, textColor),
                          ),

                          const SizedBox(height: 12),

                          /// Kolumny
                          Text("Kolumny: $gridColumns",
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

                          /// Kolory
                          _colorPicker("Kolor tła", (c) {
                            backgroundColor = c;
                          }),
                          _colorPicker("Kolor border", (c) {
                            borderColor = c;
                          }),
                          _colorPicker("Kolor tekstu", (c) {
                            textColor = c;
                          }),

                          const SizedBox(height: 16),

                          /// Akcje
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
                                  child: const Text("Usuń",
                                      style:
                                          TextStyle(color: Colors.red)),
                                ),

                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _closeOverlay,
                                    child: Text("Anuluj",
                                        style:
                                            TextStyle(color: textColor)),
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
                                    child: Text("Zapisz",
                                        style:
                                            TextStyle(color: textColor)),
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

  void _closeOverlay() {
    _editorOverlay?.remove();
    _editorOverlay = null;
    setState(() {});
  }

  /// =======================
  /// 💾 ZAPIS / ODCZYT
  /// =======================

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

    buttons.sort((a, b) => a['id'].compareTo(b['id']));
    setState(() {});
  }

  Future<void> saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buttons', json.encode(buttons));
  }

  /// =======================
  /// ▶️ NAWIGACJA
  /// =======================

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

  /// =======================
  /// 🧱 UI
  /// =======================

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

  /// =======================
  /// 🔁 REORDER
  /// =======================

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex >= buttons.length) return;

    if (newIndex > oldIndex) newIndex--;

    final item = buttons.removeAt(oldIndex);
    buttons.insert(newIndex, item);

    for (int i = 0; i < buttons.length; i++) {
      buttons[i]['id'] = i;
    }

    await saveButtons();
    setState(() {});
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index == buttons.length) {
      return ElevatedButton(
        onPressed: handleAddPress,
        child: const Text("+", style: TextStyle(fontSize: 36)),
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

  void handleAddPress() => _showEditorOverlay();

  /// =======================
  /// 🧠 HELPERKI UI
  /// =======================

  InputDecoration _inputDecoration(
      Color border, Color textColor) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border, width: 2),
      ),
      hintText: "nazwa",
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
    );
  }

  Widget _colorPicker(String label, Function(Color) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Row(
          children: [
            for (final c in [
              Colors.black,
              Colors.deepPurpleAccent,
              Colors.orange,
              Colors.yellow,
              Colors.blue,
              Colors.green,
              Colors.white,
            ])
              _colorButton(c, onPick),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _colorButton(Color c, Function(Color) onTap) {
    return GestureDetector(
      onTap: () => onTap(c),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white),
        ),
      ),
    );
  }

  void _saveButton(
    Map<String, dynamic>? old,
    String name,
    String icon,
    int columns,
    Color bg,
    Color border,
    Color text,
  ) async {
    if (old != null) {
      final i = buttons.indexWhere((b) => b['id'] == old['id']);
      buttons[i] = {
        ...old,
        'text': name.isEmpty ? "nazwa" : name,
        'icon': icon,
        'gridColumns': columns,
        'backgroundColor': '#${colorToHex(bg)}',
        'borderColor': '#${colorToHex(border)}',
        'textColor': '#${colorToHex(text)}',
      };
    } else {
      buttons.add({
        'id': buttons.length,
        'text': name.isEmpty ? "nazwa" : name,
        'icon': icon,
        'gridColumns': columns,
        'backgroundColor': '#${colorToHex(bg)}',
        'borderColor': '#${colorToHex(border)}',
        'textColor': '#${colorToHex(text)}',
      });
    }

    await saveButtons();
    setState(() {});
  }
}
