// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import '../Widgets/custom_button.dart';
import '../Utils/color_utils.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'soundboard_page.dart';
import '../Services/database_service.dart';
import '../Models/menu_button.dart' as models;

/// Main menu screen displaying list of soundboard panels.
/// 
/// Provides panel management with drag-and-drop reordering,
/// comprehensive customization through modal overlay editor,
/// and persistent storage of all settings.
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
    int gridColumns = buttonData?['gridColumns'] ?? 2;
    if (_editorOverlay != null) return;
    final overlay = Overlay.of(context);

    // Base colors (bez lightness offset)
    Color baseBackgroundColor = buttonData != null
      ? colorFromHex(buttonData['backgroundColor'], Colors.black)
      : Colors.black;
    Color baseBorderColor = buttonData != null
      ? colorFromHex(buttonData['borderColor'], Colors.deepPurpleAccent)
      : Colors.deepPurpleAccent;
    Color baseTextColor = buttonData != null
      ? colorFromHex(buttonData['textColor'], Colors.white)
      : Colors.white;

    // Lightness offsets
    int backgroundLightness = buttonData?['backgroundColor_lightness'] ?? 0;
    int borderLightness = buttonData?['borderColor_lightness'] ?? 0;
    int textLightness = buttonData?['textColor_lightness'] ?? 0;

    final TextEditingController nameController =
        TextEditingController(text: buttonData?['text'] ?? '');
    String imagePath = buttonData != null && buttonData['icon'] != null
        ? buttonData['icon']
        : 'assets/xd.png';
    File? pickedImage;

    _editorOverlay = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) {
          // Compute final colors with lightness applied
          final backgroundColor = applyLightnessOffset(baseBackgroundColor, backgroundLightness);
          final borderColor = applyLightnessOffset(baseBorderColor, borderLightness);
          final textColor = applyLightnessOffset(baseTextColor, textLightness);

          return Stack(
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
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
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
                          const SizedBox(height: 6),
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image == null) return;

                                  // Validate picked file
                                  final imageFile = File(image.path);
                                  if (!await imageFile.exists()) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Wybrany plik nie istnieje')),
                                      );
                                    }
                                    return;
                                  }

                                  final CroppedFile? croppedFile = await ImageCropper().cropImage(
                                    sourcePath: image.path,
                                    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                                    uiSettings: [
                                      AndroidUiSettings(
                                        toolbarTitle: 'Przytnij zdjęcie',
                                        toolbarColor: Colors.deepPurple,
                                        toolbarWidgetColor: Colors.white,
                                        lockAspectRatio: true,
                                        aspectRatioPresets: [
                                          CropAspectRatioPreset.square,
                                        ],
                                      ),
                                      IOSUiSettings(
                                        title: 'Przytnij zdjęcie',
                                        aspectRatioPresets: [
                                          CropAspectRatioPreset.square,
                                        ],
                                      ),
                                    ],
                                  );

                                  if (croppedFile != null) {
                                    // Copy file to app directory for safe storage
                                    final copiedPath = await DatabaseService.copyFileToAppDir(croppedFile.path);
                                    
                                    if (copiedPath != null) {
                                      pickedImage = File(copiedPath);
                                      imagePath = copiedPath;
                                      setStateOverlay(() {});
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Nie udało się zapisać obrazka')),
                                        );
                                      }
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('❌ Error picking image: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Błąd podczas wybierania obrazka')),
                                    );
                                  }
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Builder(
                                  builder: (context) {
                                    try {
                                      if (pickedImage != null) {
                                        return Image.file(
                                          pickedImage!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return _buildErrorIcon();
                                          },
                                        );
                                      }
                                      if (isAsset(imagePath)) {
                                        return Image.asset(
                                          imagePath,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return _buildErrorIcon();
                                          },
                                        );
                                      }
                                      return Image.file(
                                        File(imagePath),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildErrorIcon();
                                        },
                                      );
                                    } catch (e) {
                                      debugPrint('⚠️ Error loading image: $e');
                                      return _buildErrorIcon();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const Text("Kliknij by zmienić", style: TextStyle(color: Colors.grey, fontSize: 9)),
                          const SizedBox(height: 8),
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

                          const SizedBox(height: 8),
                          Text("Kolumny: $gridColumns", style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Slider(
                            value: gridColumns.toDouble(),
                            min: 1,
                            max: 4,
                            divisions: 3,
                            activeColor: borderColor,
                            onChanged: (val) {
                              setStateOverlay(() => gridColumns = val.toInt());
                            },
                          ),

                          const SizedBox(height: 6),
                          const Text("Kolor tła", style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: 340,
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 4,
                              runSpacing: 6,
                              children: [
                                _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) {
                                  baseBackgroundColor = c;
                                  setStateOverlay(() {});
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Jasność tła: ${backgroundLightness > 0 ? '+' : ''}$backgroundLightness%", 
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Slider(
                            value: backgroundLightness.toDouble(),
                            min: -25,
                            max: 25,
                            divisions: 50,
                            activeColor: backgroundColor,
                            onChanged: (val) {
                              setStateOverlay(() => backgroundLightness = val.toInt());
                            },
                          ),

                          const SizedBox(height: 6),
                          const Text("Kolor border", style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: 340,
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 4,
                              runSpacing: 6,
                              children: [
                                _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) {
                                  baseBorderColor = c;
                                  setStateOverlay(() {});
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Jasność border: ${borderLightness > 0 ? '+' : ''}$borderLightness%", 
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Slider(
                            value: borderLightness.toDouble(),
                            min: -25,
                            max: 25,
                            divisions: 50,
                            activeColor: borderColor,
                            onChanged: (val) {
                              setStateOverlay(() => borderLightness = val.toInt());
                            },
                          ),

                          const SizedBox(height: 6),
                          const Text("Kolor tekstu", style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: 340,
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 4,
                              runSpacing: 6,
                              children: [
                                _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                                _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) {
                                  baseTextColor = c;
                                  setStateOverlay(() {});
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Jasność tekstu: ${textLightness > 0 ? '+' : ''}$textLightness%", 
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Slider(
                            value: textLightness.toDouble(),
                            min: -25,
                            max: 25,
                            divisions: 50,
                            activeColor: textColor,
                            onChanged: (val) {
                              setStateOverlay(() => textLightness = val.toInt());
                            },
                          ),

                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (buttonData != null)
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      final success = await DatabaseService.deleteButton(buttonData['id']);
                                      
                                      if (!success) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Nie udało się usunąć przycisku')),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Clean up panel files
                                      await DatabaseService.cleanUnusedFiles();
                                      
                                      loadButtons();
                                      _editorOverlay?.remove();
                                      _editorOverlay = null;
                                      setState(() {});
                                    } catch (e) {
                                      debugPrint('❌ Error deleting button: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Błąd podczas usuwania')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Usuń", style: TextStyle(color: Colors.red)),
                                ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        // Clean up any copied files that weren't saved
                                        await DatabaseService.cleanUnusedFiles();
                                        
                                        _editorOverlay?.remove();
                                        _editorOverlay = null;
                                        setState(() {});
                                      } catch (e) {
                                        debugPrint('❌ Error during cancel: $e');
                                        _editorOverlay?.remove();
                                        _editorOverlay = null;
                                        setState(() {});
                                      }
                                    },
                                    child: Text("Anuluj", style: TextStyle(color: textColor)),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        final newName = nameController.text.trim();
                                        if (buttonData != null) {
                                          // Edit existing
                                          final menuButton = models.MenuButton.fromMap(buttonData);
                                          menuButton.text = newName.isNotEmpty ? newName : "nazwa";
                                          menuButton.icon = imagePath;
                                          menuButton.gridColumns = gridColumns;
                                          menuButton.backgroundColor = '#${colorToHex(baseBackgroundColor)}';
                                          menuButton.backgroundColorLightness = backgroundLightness;
                                          menuButton.borderColor = '#${colorToHex(baseBorderColor)}';
                                          menuButton.borderColorLightness = borderLightness;
                                          menuButton.textColor = '#${colorToHex(baseTextColor)}';
                                          menuButton.textColorLightness = textLightness;
                                          
                                          final success = await DatabaseService.updateButton(menuButton.id, menuButton);
                                          if (!success && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Nie udało się zapisać zmian')),
                                            );
                                            return;
                                          }
                                        } else {
                                          // Add new
                                          final allButtons = DatabaseService.getAllButtons();
                                          final newId = allButtons.isEmpty ? 0 : allButtons.last.id + 1;
                                          
                                          final menuButton = models.MenuButton(
                                            id: newId,
                                            text: newName.isNotEmpty ? newName : "nazwa",
                                            icon: imagePath,
                                            gridColumns: gridColumns,
                                            backgroundColor: '#${colorToHex(baseBackgroundColor)}',
                                            backgroundColorLightness: backgroundLightness,
                                            borderColor: '#${colorToHex(baseBorderColor)}',
                                            borderColorLightness: borderLightness,
                                            textColor: '#${colorToHex(baseTextColor)}',
                                            textColorLightness: textLightness,
                                            sounds: [],
                                            buttonRadius: 10.0,
                                            fontSize: 14.0,
                                            earrapeEnabled: false,
                                          );
                                          
                                          final success = await DatabaseService.saveButton(menuButton);
                                          if (!success && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Nie udało się dodać przycisku')),
                                            );
                                            return;
                                          }
                                        }
                                        
                                        // Clean up old icon if it was changed
                                        await DatabaseService.cleanUnusedFiles();
                                        
                                        loadButtons();
                                        _editorOverlay?.remove();
                                        _editorOverlay = null;
                                        setState(() {});
                                      } catch (e) {
                                        debugPrint('❌ Error saving button: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Błąd podczas zapisywania')),
                                          );
                                        }
                                      }
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
          );
        },
      ),
    );

    overlay.insert(_editorOverlay!);
  }

  Widget _colorButton(Color color, Function(Color) onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onTap(color),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 25),
    );
  }

  void handlePress(int id) async {
    try {
      final menuButton = DatabaseService.getButton(id);
      if (menuButton == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie znaleziono przycisku')),
          );
        }
        return;
      }

      final btnData = menuButton.toMap();

      final updatedData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SoundboardPage(menuData: btnData),
        ),
      );

      if (updatedData != null) {
        final updatedMenuButton = models.MenuButton.fromMap(updatedData);
        final success = await DatabaseService.updateButton(id, updatedMenuButton);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie udało się zapisać zmian')),
          );
        }
        loadButtons();
      }
    } catch (e) {
      debugPrint('❌ Error in handlePress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas otwierania')),
        );
      }
    }
  }

  void handleLongPress(int id) {
    try {
      final menuButton = DatabaseService.getButton(id);
      if (menuButton == null) return;
      _showEditorOverlay(buttonData: menuButton.toMap());
    } catch (e) {
      debugPrint('❌ Error in handleLongPress: $e');
    }
  }

  void handleAddPress() {
    _showEditorOverlay();
  }

  void loadButtons() {
    try {
      final menuButtons = DatabaseService.getAllButtons();
      setState(() {
        buttons = menuButtons.map((b) => b.toMap()).toList();
      });
    } catch (e) {
      debugPrint('❌ Error loading buttons: $e');
    }
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
            try {
              if (oldIndex == buttons.length || newIndex > buttons.length) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = buttons.removeAt(oldIndex);
                buttons.insert(newIndex, item);
              });
              
              // Save reordered buttons to Hive
              final menuButtons = buttons.map((b) => models.MenuButton.fromMap(b)).toList();
              final success = await DatabaseService.saveAllButtons(menuButtons);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nie udało się zapisać kolejności')),
                );
              }
            } catch (e) {
              debugPrint('❌ Error reordering: $e');
            }
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
            
            // Apply lightness offsets to display colors
            final displayBackgroundColor = applyLightnessOffset(
              colorFromHex(btn['backgroundColor'], Colors.black),
              btn['backgroundColor_lightness'] ?? 0
            );
            final displayBorderColor = applyLightnessOffset(
              colorFromHex(btn['borderColor'], Colors.deepPurpleAccent),
              btn['borderColor_lightness'] ?? 0
            );
            final displayTextColor = applyLightnessOffset(
              colorFromHex(btn['textColor'], Colors.white),
              btn['textColor_lightness'] ?? 0
            );
            
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
                      backgroundColor: displayBackgroundColor,
                      borderColor: displayBorderColor,
                      textColor: displayTextColor,
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
                        color: displayBorderColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.drag_handle,
                          color: displayTextColor),
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