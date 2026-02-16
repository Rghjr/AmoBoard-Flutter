// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../Utils/color_utils.dart';
import 'soundboard_button.dart';
import '../Services/sound_engine.dart';
import '../Services/database_service.dart';
import '../Models/menu_button.dart' as models;

/// Soundboard screen:
/// 
/// Provides complete soundboard functionality:
/// - Grid display of sound buttons
/// - Drag-and-drop reordering support
/// - Real-time settings adjustment
/// - Earrape mode toggle
/// - Immediate persistence to database
/// - Renders a grid of sound buttons based on `menuData['sounds']`.
/// - Supports reordering via long-press drag mode.
/// - Persists edits back to the parent via `Navigator.pop` when leaving.
/// - Includes quick actions in AppBar: stop all, toggle reorder, add sound, and earrape toggle.
/// 
class SoundboardPage extends StatefulWidget {
  final Map<String, dynamic> menuData;

  const SoundboardPage({super.key, required this.menuData});

  @override
  State<SoundboardPage> createState() => _SoundboardPageState();
}

class _SoundboardPageState extends State<SoundboardPage> {
  // Working copy of incoming menu data and its 'sounds' list.
  late Map<String, dynamic> currentData;
  late List<dynamic> sounds;

  // UI configuration (columns, corner radius, font size).
  int gridColumns = 2;
  double buttonRadius = 10.0;
  double fontSize = 14.0;

  // Interaction flags.
  bool isReordering = false;   // when true, grid supports drag & drop reordering
  bool earrapeEnabled = false; // global amplification toggle shown in AppBar

  @override
  void initState() {
    super.initState();
    try {
      // Create a mutable copy of menuData and initialize defaults.
      currentData = Map<String, dynamic>.from(widget.menuData);
      if (currentData['sounds'] == null) {
        currentData['sounds'] = [];
      }
      sounds = List.from(currentData['sounds']);
      gridColumns = (currentData['gridColumns'] ?? 2).toInt();
      buttonRadius = (currentData['buttonRadius'] ?? 10.0).toDouble();
      fontSize = (currentData['fontSize'] ?? 14.0).toDouble();
      earrapeEnabled = currentData['earrapeEnabled'] ?? false;
      
      // Set earrape state in sound engine
      SoundEngine().setEarrape(earrapeEnabled);
    } catch (e) {
      debugPrint('❌ Error in initState: $e');
      // Initialize with safe defaults
      currentData = Map<String, dynamic>.from(widget.menuData);
      currentData['sounds'] = [];
      sounds = [];
      gridColumns = 2;
      buttonRadius = 10.0;
      fontSize = 14.0;
      earrapeEnabled = false;
    }
  }

  /// Save changes immediately to persistent storage via Hive
  Future<void> _saveChangesImmediately() async {
    try {
      // Update sounds with sequential IDs
      for (int i = 0; i < sounds.length; i++) {
        sounds[i]['id'] = i;
      }
      
      // Update currentData with latest values
      currentData['sounds'] = sounds;
      currentData['gridColumns'] = gridColumns;
      currentData['buttonRadius'] = buttonRadius;
      currentData['fontSize'] = fontSize;
      currentData['earrapeEnabled'] = earrapeEnabled;
      
      // Convert to MenuButton and save to Hive
      final menuButton = models.MenuButton.fromMap(currentData);
      final success = await DatabaseService.updateButton(menuButton.id, menuButton);
      
      if (!success) {
        debugPrint('⚠️ Failed to save changes');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie udało się zapisać zmian'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas zapisywania'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// Add a new placeholder sound entry to the grid.
  void _addNewSound() async {
    try {
      setState(() {
        int newId = sounds.isEmpty ? 0 : sounds.length;
        sounds.add({
          "id": newId,
          "label": "Nowy Dźwięk",
          "iconPath": "assets/xd.png",
          "soundPath": "",
          "volume": 1.0,
          "borderColor": "#FFFFFF",
          "borderColor_lightness": 0,
          "backgroundColor": "#000000",
          "backgroundColor_lightness": 0,
          "textColor": "#FFFFFF",
          "textColor_lightness": 0,
        });
      });
      await _saveChangesImmediately();
    } catch (e) {
      debugPrint('❌ Error adding new sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się dodać dźwięku'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// Swap positions of two sounds in the list (used by drag & drop).
  void _swapSounds(int oldIndex, int newIndex) async {
    try {
      setState(() {
        final temp = sounds[oldIndex];
        sounds[oldIndex] = sounds[newIndex];
        sounds[newIndex] = temp;
      });
      await _saveChangesImmediately();
    } catch (e) {
      debugPrint('❌ Error swapping sounds: $e');
    }
  }

  /// Bottom sheet with board-level settings (columns, corner radius, text size).
  /// Uses `StatefulBuilder` so sliders update live within the modal.
  void _showSettingsModal() {
    try {
      // Compute colors with lightness offset
      final borderColor = applyLightnessOffset(
        colorFromHex(currentData['borderColor'], Colors.deepPurpleAccent),
        currentData['borderColor_lightness'] ?? 0
      );
      final textColor = applyLightnessOffset(
        colorFromHex(currentData['textColor'], Colors.white),
        currentData['textColor_lightness'] ?? 0
      );

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ustawienia Soundboardu",
                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Grid columns slider (1–5)
                    Text("Kolumny: $gridColumns", style: TextStyle(color: textColor)),
                    Slider(
                      value: gridColumns.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: borderColor,
                      onChanged: (val) {
                        setModalState(() => gridColumns = val.toInt());
                        setState(() => gridColumns = val.toInt());
                      },
                      onChangeEnd: (val) async {
                        await _saveChangesImmediately();
                      },
                    ),
                    // Corner radius slider
                    Text("Zaokrąglenie: ${buttonRadius.toInt()}", style: TextStyle(color: textColor)),
                    Slider(
                      value: buttonRadius,
                      min: 0,
                      max: 50,
                      activeColor: borderColor,
                      onChanged: (val) {
                        setModalState(() => buttonRadius = val);
                        setState(() => buttonRadius = val);
                      },
                      onChangeEnd: (val) async {
                        await _saveChangesImmediately();
                      },
                    ),
                    // Font size slider
                    Text("Rozmiar tekstu: ${fontSize.toInt()}", style: TextStyle(color: textColor)),
                    Slider(
                      value: fontSize,
                      min: 8,
                      max: 30,
                      activeColor: borderColor,
                      onChanged: (val) {
                        setModalState(() => fontSize = val);
                        setState(() => fontSize = val);
                      },
                      onChangeEnd: (val) async {
                        await _saveChangesImmediately();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Error showing settings modal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background and text colors with lightness offsets applied
    Color bgColor = applyLightnessOffset(
      colorFromHex(currentData['backgroundColor'], Colors.black),
      currentData['backgroundColor_lightness'] ?? 0
    );
    Color textColor = applyLightnessOffset(
      colorFromHex(currentData['textColor'], Colors.white),
      currentData['textColor_lightness'] ?? 0
    );

    return WillPopScope(
      // Intercept back navigation: persist changes and return updated data to caller.
      onWillPop: () async {
        try {
          await _saveChangesImmediately();
          Navigator.pop(context, currentData);
        } catch (e) {
          debugPrint('❌ Error during WillPopScope: $e');
          Navigator.pop(context, currentData);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Back button: save, then return data to previous screen.
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () async {
              try {
                await _saveChangesImmediately();
                Navigator.pop(context, currentData);
              } catch (e) {
                debugPrint('❌ Error during back: $e');
                Navigator.pop(context, currentData);
              }
            },
          ),
          titleSpacing: 0, // title sits right next to the back button
          title: Text(
            currentData['text'],
            style: TextStyle(color: textColor),
          ),
          centerTitle: false, // left-aligned title
          // Center overlay area in the AppBar: earrape toggle with an icon
          flexibleSpace: Stack(
            children: [
              Align(
                alignment: Alignment.center, // exact center of the AppBar
                child: GestureDetector(
                  onTap: () {
                    try {
                      setState(() {
                        earrapeEnabled = !earrapeEnabled;
                        SoundEngine().setEarrape(earrapeEnabled);
                      });
                      _saveChangesImmediately();
                    } catch (e) {
                      debugPrint('❌ Error toggling earrape: $e');
                    }
                  },
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: Image.asset(
                        'assets/earrape_icon.png',
                        width: 60,
                        height: 60,
                        // Tint red when enabled, preserving transparency via blend mode
                        color: earrapeEnabled ? Colors.red.withAlpha((0.9 * 255).round()) : null,
                        colorBlendMode: earrapeEnabled ? BlendMode.modulate : null,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('⚠️ Failed to load earrape icon');
                          return Icon(
                            Icons.volume_up,
                            color: earrapeEnabled ? Colors.red : textColor,
                            size: 40,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Stop all sounds
            IconButton(
              icon: Icon(Icons.pause, color: textColor),
              tooltip: "STOP WSZYSTKO",
              onPressed: () {
                try {
                  SoundEngine().stopAll();
                } catch (e) {
                  debugPrint('❌ Error stopping sounds: $e');
                }
              },
            ),
            // Toggle reorder mode
            IconButton(
              icon: Icon(
                isReordering ? Icons.check : Icons.drag_indicator,
                color: isReordering ? Colors.green : textColor,
              ),
              onPressed: () {
                setState(() {
                  isReordering = !isReordering;
                });
              },
            ),
            // Add new sound entry
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: _addNewSound,
            ),
          ],
        ),

        // Long-press anywhere on body to open settings modal
        body: GestureDetector(
          onLongPress: _showSettingsModal,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              itemCount: sounds.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                try {
                  final sound = sounds[index];
                  // Build a sound button with current configuration
                  Widget buttonWidget = SoundboardButton(
                    key: ValueKey(sound['id']),
                    data: sound,
                    borderRadius: buttonRadius,
                    fontSize: fontSize,
                    interactionsEnabled: !isReordering, // disable play/edit while reordering
                    onUpdate: (updatedSound) async {
                      try {
                        setState(() {
                          sounds[index] = updatedSound;
                        });
                        await _saveChangesImmediately(); // Save to Hive immediately
                      } catch (e) {
                        debugPrint('❌ Error updating sound: $e');
                      }
                    },
                    onDelete: () async {
                      try {
                        setState(() {
                          sounds.removeAt(index);
                        });
                        await _saveChangesImmediately(); // Save to Hive immediately
                        
                        // Clean up unused files
                        await DatabaseService.cleanUnusedFiles();
                      } catch (e) {
                        debugPrint('❌ Error deleting sound: $e');
                      }
                    },
                  );

                  // Reordering mode: wrap with draggable & drag target behavior
                  if (isReordering) {
                    return LongPressDraggable<int>(
                      data: index,
                      feedback: SizedBox(
                        width: 100,
                        height: 100,
                        child: Opacity(opacity: 0.7, child: buttonWidget),
                      ),
                      child: DragTarget<int>(
                        onAcceptWithDetails: (details) {
                          final receivedIndex = details.data;
                          _swapSounds(receivedIndex, index);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Opacity(
                            opacity: candidateData.isNotEmpty ? 0.5 : 1.0,
                            child: buttonWidget,
                          );
                        },
                      ),
                    );
                  }

                  // Normal mode: render the button as-is
                  return buttonWidget;
                } catch (e) {
                  debugPrint('❌ Error building button at index $index: $e');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(buttonRadius),
                    ),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}