
import 'package:flutter/material.dart';
import 'menu.dart';
import 'soundboard_button.dart';
import 'sound_engine.dart';
// ignore_for_file: deprecated_member_use

/// Soundboard screen:
/// - Renders a grid of sound buttons based on `menuData['sounds']`.
/// - Supports reordering via long-press drag mode.
/// - Persists edits back to the parent via `Navigator.pop` when leaving.
/// - Includes quick actions in AppBar: stop all, toggle reorder, add sound, and earrape toggle.
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
  }

  /// Collect changes from local UI state back into `currentData`.
  /// Assigns sequential `id`s to sounds to reflect their order in the grid.
  void _saveChanges() {
    for (int i = 0; i < sounds.length; i++) {
      sounds[i]['id'] = i;
    }
    currentData['sounds'] = sounds;
    currentData['gridColumns'] = gridColumns;
    currentData['buttonRadius'] = buttonRadius;
    currentData['fontSize'] = fontSize;
  }

  /// Add a new placeholder sound entry to the grid.
  void _addNewSound() {
    setState(() {
      int newId = sounds.isEmpty ? 0 : sounds.length;
      sounds.add({
        "id": newId,
        "label": "Nowy Dźwięk",
        "iconPath": "assets/xd.png",
        "soundPath": "",
        "volume": 1.0,
        "borderColor": "#FFFFFF"
      });
    });
  }

  /// Swap positions of two sounds in the list (used by drag & drop).
  void _swapSounds(int oldIndex, int newIndex) {
    setState(() {
      final temp = sounds[oldIndex];
      sounds[oldIndex] = sounds[newIndex];
      sounds[newIndex] = temp;
    });
  }

  /// Bottom sheet with board-level settings (columns, corner radius, text size).
  /// Uses `StatefulBuilder` so sliders update live within the modal.
  void _showSettingsModal() {
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
                  const Text("Ustawienia Soundboardu",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // Grid columns slider (1–5)
                  Text("Kolumny: $gridColumns", style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: gridColumns.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: colorFromHex(currentData['borderColor'], Colors.deepPurpleAccent),
                    onChanged: (val) {
                      setModalState(() => gridColumns = val.toInt());
                      setState(() => gridColumns = val.toInt());
                    },
                  ),
                  // Corner radius slider
                  Text("Zaokrąglenie: ${buttonRadius.toInt()}", style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: buttonRadius,
                    min: 0,
                    max: 50,
                    activeColor: colorFromHex(currentData['borderColor'], Colors.deepPurpleAccent),
                    onChanged: (val) {
                      setModalState(() => buttonRadius = val);
                      setState(() => buttonRadius = val);
                    },
                  ),
                  // Font size slider
                  Text("Rozmiar tekstu: ${fontSize.toInt()}", style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: fontSize,
                    min: 8,
                    max: 30,
                    activeColor: colorFromHex(currentData['borderColor'], Colors.deepPurpleAccent),
                    onChanged: (val) {
                      setModalState(() => fontSize = val);
                      setState(() => fontSize = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Background color derived from menu configuration.
    Color bgColor = colorFromHex(currentData['backgroundColor'], Colors.black);

    return WillPopScope(
      // Intercept back navigation: persist changes and return updated data to caller.
      onWillPop: () async {
        _saveChanges();
        Navigator.pop(context, currentData);
        return false;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Back button: save, then return data to previous screen.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _saveChanges();
              Navigator.pop(context, currentData);
            },
          ),
          titleSpacing: 0, // title sits right next to the back button
          title: Text(
            currentData['text'],
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: false, // left-aligned title
          // Center overlay area in the AppBar: earrape toggle with an icon
          flexibleSpace: Stack(
            children: [
              Align(
                alignment: Alignment.center, // exact center of the AppBar
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      earrapeEnabled = !earrapeEnabled;
                      SoundEngine().setEarrape(earrapeEnabled);
                    });
                  },
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: Image.asset(
                        'assets/earrape_icon.png', // your icon
                        width: 60,
                        height: 60,
                        // Tint red when enabled, preserving transparency via blend mode
                        color: earrapeEnabled ? Colors.red.withAlpha((0.9 * 255).round()) : null,
                        colorBlendMode: earrapeEnabled ? BlendMode.modulate : null,
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
              icon: const Icon(Icons.pause, color: Colors.white),
              tooltip: "STOP WSZYSTKO",
              onPressed: () {
                SoundEngine().stopAll();
              },
            ),
            // Toggle reorder mode
            IconButton(
              icon: Icon(
                isReordering ? Icons.check : Icons.drag_indicator,
                color: isReordering ? Colors.green : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isReordering = !isReordering;
                });
              },
            ),
            // Add new sound entry
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
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
                final sound = sounds[index];
                // Build a sound button with current configuration
                Widget buttonWidget = SoundboardButton(
                  key: ValueKey(sound['id']),
                  data: sound,
                  borderRadius: buttonRadius,
                  fontSize: fontSize,
                  interactionsEnabled: !isReordering, // disable play/edit while reordering
                  onUpdate: (updatedSound) {
                    setState(() {
                      sounds[index] = updatedSound;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      sounds.removeAt(index);
                    });
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
              },
            ),
          ),
        ),
      ),
    );
  }
}
