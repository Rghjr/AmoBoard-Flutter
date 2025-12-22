import 'dart:convert';
import 'package:flutter/material.dart';
import '../custom_button.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'soundboard_page.dart';

Color colorFromHex(dynamic value, Color fallback) {
  if (value == null) return fallback;
  try {
    return Color(int.parse(value.toString().replaceFirst("#", "0xff")));
  } catch (e) {
    return fallback;
  }
}

String colorToHex(Color c) {
  // return RRGGBB
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$r$g$b';
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  List<Map<String, dynamic>> buttons = [];
  OverlayEntry? _editorOverlay;

  bool isAsset(String path) {
    return !(path.startsWith('/') || path.contains('storage'));
  }

  @override
  void initState() {
    super.initState();
    loadButtons();
  }

  void _showEditorOverlay({Map<String, dynamic>? buttonData}) {
    int gridColumns = buttonData?['gridColumns'] ?? 2; // domyślnie 2 kolumny
    if (_editorOverlay != null) return;
    final overlay = Overlay.of(context);

    Color backgroundColor = buttonData != null
      ? colorFromHex(buttonData['backgroundColor'], Colors.black)
      : Colors.black;
    Color borderColor = buttonData != null
      ? colorFromHex(buttonData['borderColor'], Colors.deepPurpleAccent)
      : Colors.deepPurpleAccent;
    Color textColor = buttonData != null
      ? colorFromHex(buttonData['textColor'], Colors.white)
      : Colors.white;

    final TextEditingController nameController =
        TextEditingController(text: buttonData?['text'] ?? '');
    String imagePath = buttonData != null && buttonData['icon'] != null
        ? buttonData['icon']
        : 'assets/xd.png';
    File? pickedImage;

    _editorOverlay = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _editorOverlay?.remove();
                  _editorOverlay = null;
                  setState(() {});
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withAlpha((255 * 0.7).round()),
                  ),
                ),
              ),
            ),
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
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          buttonData != null ? "Edytuj przycisk" : "Dodaj nowy przycisk",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final XFile? image =
                                  await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                pickedImage = File(image.path);
                                imagePath = pickedImage!.path;
                                setStateOverlay(() {}); // live update
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Builder(
                                builder: (context) {
                                  if (pickedImage != null) {
                                    return Image.file(
                                      pickedImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  if (isAsset(imagePath)) {
                                    return Image.asset(
                                      imagePath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Image.file(
                                    File(imagePath),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: buttonData == null ? "nazwa" : null,
                            hintStyle: TextStyle(color: textColor.withAlpha((0.5 * 255).round())),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            filled: true,
                            fillColor: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Liczba kolumn
                        Text("Kolumny: $gridColumns", style: TextStyle(color: Colors.white)),
                        Slider(
                          value: gridColumns.toDouble(),
                          min: 1,
                          max: 4,
                          divisions: 3,
                          activeColor: colorFromHex(buttonData?['borderColor'], Colors.deepPurpleAccent),
                          onChanged: (val) {
                            setStateOverlay(() => gridColumns = val.toInt());
                          },
                        ),


                        const SizedBox(height: 12),
                        // Kolory tła
                        Text("Kolor tła", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _colorButton(Color(0xFF000000), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 197, 103, 26), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 231, 166, 0), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 0, 60, 151), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 182, 0, 136), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 0, 112, 7), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 77, 77, 77), (c) => backgroundColor = c),
                            _colorButton(Color.fromARGB(255, 96, 0, 175), (c) => backgroundColor = c),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Kolor border", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _colorButton(Colors.deepPurpleAccent, (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 255, 111, 0), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 255, 255, 0), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 0, 94, 255), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 217, 0, 255), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 0, 255, 0), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 156, 156, 156), (c) => borderColor = c),
                            _colorButton(Color.fromARGB(255, 132, 0, 255), (c) => borderColor = c),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Kolor tekstu", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _colorButton(Colors.white, (c) => textColor = c),
                            _colorButton(Color(0xFFFFAB40), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 255, 255, 76), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 60, 135, 255), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 233, 110, 255), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 49, 255, 94), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 192, 192, 192), (c) => textColor = c),
                            _colorButton(Color.fromARGB(255, 158, 85, 255), (c) => textColor = c),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (buttonData != null)
                              TextButton(
                                onPressed: () {
                                  buttons.removeWhere((b) => b['id'] == buttonData['id']);
                                  saveButtons();
                                  _editorOverlay?.remove();
                                  _editorOverlay = null;
                                  setState(() {});
                                },
                                child: const Text("Usuń", style: TextStyle(color: Colors.red)),
                              ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _editorOverlay?.remove();
                                    _editorOverlay = null;
                                    setState(() {});
                                  },
                                  child: Text("Anuluj", style: TextStyle(color: textColor)),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () async {
                                    final newName = nameController.text.trim();
                                    if (buttonData != null) {
                                      final index = buttons.indexWhere((b) => b['id'] == buttonData['id']);
                                      if (index != -1) {
                                        buttons[index]['text'] =
                                            newName.isNotEmpty ? newName : "nazwa";
                                        buttons[index]['icon'] = imagePath;
                                        buttons[index]['gridColumns'] = gridColumns;
                                        buttons[index]['backgroundColor'] =
                                          '#${colorToHex(backgroundColor)}';
                                        buttons[index]['borderColor'] =
                                          '#${colorToHex(borderColor)}';
                                        buttons[index]['textColor'] =
                                          '#${colorToHex(textColor)}';
                                      }
                                    } else {
                                      final id = buttons.isEmpty ? 0 : buttons.last['id'] + 1;
                                      buttons.add({
                                        'id': id,
                                        'text': newName.isNotEmpty ? newName : "nazwa",
                                        'backgroundColor': '#${colorToHex(backgroundColor)}',
                                        'borderColor': '#${colorToHex(borderColor)}',
                                        'textColor': '#${colorToHex(textColor)}',
                                        'icon': imagePath,
                                        'gridColumns': gridColumns,
                                      });
                                    }
                                    await saveButtons();
                                    _editorOverlay?.remove();
                                    _editorOverlay = null;
                                    setState(() {});
                                  },
                                  child: Text("Zapisz", style: TextStyle(color: textColor)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_editorOverlay!);
  }

  Widget _colorButton(Color color, Function(Color) onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(color),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void handlePress(int id) async {
    final btnIndex = buttons.indexWhere((b) => b['id'] == id);
    if (btnIndex == -1) return;

    final btnData = buttons[btnIndex];

    // Przechodzimy do SoundboardPage i czekamy na wynik (zaktualizowane dane)
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoundboardPage(menuData: btnData),
      ),
    );

    // Jeśli wróciły dane (nie było cofnięcia bez zapisu)
    if (updatedData != null) {
      setState(() {
        buttons[btnIndex] = updatedData;
      });
      await saveButtons(); // Zapis do SharedPreferences
    }
  }

  void handleLongPress(int id) {
    final btn = buttons.firstWhere((b) => b['id'] == id);
    _showEditorOverlay(buttonData: btn);
  }

  void handleAddPress() {
    _showEditorOverlay();
  }

  Future<void> loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('buttons');
    if (savedData != null) {
      final List<dynamic> jsonData = json.decode(savedData);
      setState(() {
        buttons = jsonData.cast<Map<String, dynamic>>();
        buttons.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      });
    } else {
      final String jsonString = await rootBundle.loadString('assets/menu_buttons.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        buttons = jsonData.cast<Map<String, dynamic>>();
        buttons.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      });
      await saveButtons();
    }
  }

  Future<void> saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buttons', json.encode(buttons));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: Align(
          alignment: Alignment.topCenter,
          child: Image.asset('assets/Amongus_Logo_W_Apce.png', height: 70),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: buttons.length + 1,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex == buttons.length || newIndex > buttons.length) return;
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = buttons.removeAt(oldIndex);
              buttons.insert(newIndex, item);
              for (int i = 0; i < buttons.length; i++) {
                buttons[i]['id'] = i;
              }
            });
            await saveButtons();
          },
          proxyDecorator: (child, index, animation) {
            if (index == buttons.length) return child;
            return Material(color: Colors.transparent, child: child);
          },
          itemBuilder: (context, index) {
            if (index == buttons.length) {
              return Padding(
                key: const ValueKey('add_button'),
                padding: const EdgeInsets.only(bottom: 5),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(400, 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: handleAddPress,
                    child: const Text("+",
                        style: TextStyle(fontSize: 36, color: Colors.white)),
                  ),
                ),
              );
            }

            final btn = buttons[index];
            return Padding(
              key: ValueKey(btn['id']),
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      id: btn['id'],
                      text: btn['text'],
                      icon: btn['icon'] ?? 'assets/xd.png',
                      backgroundColor: colorFromHex(btn['backgroundColor'], Colors.black),
                      borderColor: colorFromHex(btn['borderColor'], Colors.deepPurpleAccent),
                      textColor: colorFromHex(btn['textColor'], Colors.white),
                      onPressed: () => handlePress(btn['id']),
                      onLongPress: () => handleLongPress(btn['id']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 40,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorFromHex(btn['borderColor'], Colors.deepPurpleAccent),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.drag_handle,
                          color: colorFromHex(btn['textColor'], Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
