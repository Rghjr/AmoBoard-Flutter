import 'package:flutter/material.dart';
import 'menu.dart';
import 'soundboard_button.dart';
import 'sound_engine.dart';
// ignore_for_file: deprecated_member_use

/// Page showing a grid of soundboard buttons with reordering and settings
class SoundboardPage extends StatefulWidget {
  final Map<String, dynamic> menuData;

  const SoundboardPage({super.key, required this.menuData});

  @override
  State<SoundboardPage> createState() => _SoundboardPageState();
}

class _SoundboardPageState extends State<SoundboardPage> {
  late Map<String, dynamic> currentData;
  late List<dynamic> sounds;

  int gridColumns = 2;
  double buttonRadius = 10.0;
  double fontSize = 14.0;
  bool isReordering = false;
  bool earrapeEnabled = false;

  @override
  void initState() {
    super.initState();
    currentData = Map<String, dynamic>.from(widget.menuData);
    sounds = List.from(currentData['sounds'] ?? []);
    gridColumns = (currentData['gridColumns'] ?? 2).toInt();
    buttonRadius = (currentData['buttonRadius'] ?? 10.0).toDouble();
    fontSize = (currentData['fontSize'] ?? 14.0).toDouble();
    earrapeEnabled = currentData['earrapeEnabled'] ?? false;
  }

  /// Save changes back to currentData
  void _saveChanges() {
    for (int i = 0; i < sounds.length; i++) sounds[i]['id'] = i;
    currentData['sounds'] = sounds;
    currentData['gridColumns'] = gridColumns;
    currentData['buttonRadius'] = buttonRadius;
    currentData['fontSize'] = fontSize;
  }

  /// Add a new default sound button
  void _addNewSound() {
    setState(() {
      int newId = sounds.isEmpty ? 0 : sounds.length;
      sounds.add({
        "id": newId,
        "label": "New Sound",
        "iconPath": "assets/xd.png",
        "soundPath": "",
        "volume": 1.0,
        "borderColor": "#FFFFFF"
      });
    });
  }

  /// Swap two sounds in the list for reordering
  void _swapSounds(int oldIndex, int newIndex) {
    setState(() {
      final temp = sounds[oldIndex];
      sounds[oldIndex] = sounds[newIndex];
      sounds[newIndex] = temp;
    });
  }

  /// Show settings modal to adjust grid, radius, font size
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Soundboard Settings", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("Columns: $gridColumns", style: const TextStyle(color: Colors.white)),
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
                Text("Button radius: ${buttonRadius.toInt()}", style: const TextStyle(color: Colors.white)),
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
                Text("Font size: ${fontSize.toInt()}", style: const TextStyle(color: Colors.white)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = colorFromHex(currentData['backgroundColor'], Colors.black);

    return WillPopScope(
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _saveChanges();
              Navigator.pop(context, currentData);
            },
          ),
          titleSpacing: 0,
          title: Text(currentData['text'], style: const TextStyle(color: Colors.white)),
          centerTitle: false,
          flexibleSpace: Stack(
            children: [
              Align(
                alignment: Alignment.center,
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
                        'assets/earrape_icon.png',
                        width: 60,
                        height: 60,
                        color: earrapeEnabled ? Colors.red.withOpacity(0.9) : null,
                        colorBlendMode: earrapeEnabled ? BlendMode.modulate : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              tooltip: "STOP ALL",
              onPressed: () => SoundEngine().stopAll(),
            ),
            IconButton(
              icon: Icon(isReordering ? Icons.check : Icons.drag_indicator, color: isReordering ? Colors.green : Colors.white),
              onPressed: () => setState(() => isReordering = !isReordering),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _addNewSound,
            ),
          ],
        ),
        body: GestureDetector(
          onLongPress: _showSettingsModal,
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.transparent,
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
                Widget buttonWidget = SoundboardButton(
                  key: ValueKey(sound['id']),
                  data: sound,
                  borderRadius: buttonRadius,
                  fontSize: fontSize,
                  interactionsEnabled: !isReordering,
                  onUpdate: (updatedSound) => setState(() => sounds[index] = updatedSound),
                  onDelete: () => setState(() => sounds.removeAt(index)),
                );

                // Wrap button in draggable if reordering is enabled
                if (isReordering) {
                  return LongPressDraggable<int>(
                    data: index,
                    feedback: SizedBox(width: 100, height: 100, child: Opacity(opacity: 0.7, child: buttonWidget)),
                    child: DragTarget<int>(
                      onAcceptWithDetails: (details) => _swapSounds(details.data, index),
                      builder: (context, candidateData, rejectedData) => Opacity(opacity: candidateData.isNotEmpty ? 0.5 : 1.0, child: buttonWidget),
                    ),
                  );
                }

                return buttonWidget;
              },
            ),
          ),
        ),
      ),
    );
  }
}
