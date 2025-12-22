import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'menu.dart'; // for colorFromHex and colorToHex
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'sound_engine.dart';



class SoundboardButton extends StatefulWidget {
  final Map<String, dynamic> data;
  final double borderRadius;
  final double fontSize;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;
  final bool interactionsEnabled;


  const SoundboardButton({
    super.key,
    required this.data,
    required this.borderRadius,
    required this.fontSize,
    required this.onUpdate,
    required this.onDelete,
    required this.interactionsEnabled,
  });

  @override
  State<SoundboardButton> createState() => _SoundboardButtonState();
}

class _SoundboardButtonState extends State<SoundboardButton> {
  void _playSound() {
    final path = widget.data['soundPath'];

    if (path != null && path.toString().isNotEmpty) {
      SoundEngine().play(
        path: path,
        volume: (widget.data['volume'] != null ? (widget.data['volume'] as num).toDouble() : 1.0),
        
      );
      debugPrint("Playing sound: $path");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Odtwarzanie: ${widget.data['label']}"), duration: const Duration(milliseconds: 500)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Brak przypisanego dźwięku! Przytrzymaj, aby edytować."), duration: Duration(milliseconds: 1000)),
      );
    }
  }

  void _showEditor() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent, // 👈 WAŻNE
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withAlpha((0.4 * 255).round()),
              ),
            ),
            _SoundEditorOverlay(
              data: widget.data,
              onSave: widget.onUpdate,
              onDelete: widget.onDelete,
            ),
          ],
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = colorFromHex(widget.data['borderColor'], Colors.deepPurpleAccent);
    Color backgroundColor = colorFromHex(widget.data['backgroundColor'], Colors.black);
    Color textColor = colorFromHex(widget.data['textColor'], Colors.white);
    String iconPath = widget.data['iconPath'] ?? 'assets/xd.png';
    bool isAsset = !(iconPath.startsWith('/') || iconPath.contains('storage'));
    double textSize = widget.data['textSize'] != null ? (widget.data['textSize'] as num).toDouble() : widget.fontSize;

    return GestureDetector(
      onTap: widget.interactionsEnabled ? _playSound : null,
      onLongPress: widget.interactionsEnabled ? _showEditor : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha((0.4 * 255).round()),
              blurRadius: 5,
              spreadRadius: 3,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Hero(
                  tag: 'sound_icon_${widget.data['id']}_${DateTime.now().millisecondsSinceEpoch}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius / 1.5),
                    child: isAsset
                        ? Image.asset(iconPath, fit: BoxFit.cover)
                        : Image.file(File(iconPath), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  widget.data['label'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundEditorOverlay extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onDelete;

  const _SoundEditorOverlay({required this.data, required this.onSave, required this.onDelete});

  @override
  State<_SoundEditorOverlay> createState() => _SoundEditorOverlayState();
}

class _SoundEditorOverlayState extends State<_SoundEditorOverlay> {
  late TextEditingController _nameController;
  late String _currentIconPath;
  late String _currentSoundPath;
  late Color _borderColor;
  late Color _backgroundColor;
  late Color _textColor;
  late double _volume;
  late double _textSize;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['label']);
    _currentIconPath = widget.data['iconPath'] ?? 'assets/xd.png';
    _currentSoundPath = widget.data['soundPath'] ?? '';
    _borderColor = colorFromHex(widget.data['borderColor'], Colors.white);
    _backgroundColor = colorFromHex(widget.data['backgroundColor'], Colors.black);
    _textColor = colorFromHex(widget.data['textColor'], Colors.white);
    _volume = (widget.data['volume'] != null ? (widget.data['volume'] as num).toDouble() : 1.0);
    _textSize = widget.data['textSize'] != null ? (widget.data['textSize'] as num).toDouble() : 16.0;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _currentIconPath = image.path;
      });
    }
  }

  Future<void> _pickSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      final selectedPath = result.files.single.path!;
      setState(() {
        _currentSoundPath = selectedPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Wybrano: ${selectedPath.split('/').last}"),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      // anulowane – wyjebane, nic nie robimy
    }
  }

  void _save() {
    final updated = Map<String, dynamic>.from(widget.data);
    updated['label'] = _nameController.text;
    updated['iconPath'] = _currentIconPath;
    updated['soundPath'] = _currentSoundPath;
    updated['borderColor'] = '#${colorToHex(_borderColor)}';
    updated['backgroundColor'] = '#${colorToHex(_backgroundColor)}';
    updated['textColor'] = '#${colorToHex(_textColor)}';
    updated['volume'] = _volume;
    updated['textSize'] = _textSize.round();

    widget.onSave(updated);
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    bool isAsset = !(_currentIconPath.startsWith('/') || _currentIconPath.contains('storage'));

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edytuj Dźwięk", style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 80, width: 80,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                  child: isAsset
                      ? Image.asset(_currentIconPath, fit: BoxFit.cover)
                      : Image.file(File(_currentIconPath), fit: BoxFit.cover),
                ),
              ),
              const Text("Kliknij obrazek by zmienić", style: TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nazwa",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),

              // Background color picker
              Align(alignment: Alignment.centerLeft, child: Text("Kolor tła", style: TextStyle(color: Colors.white))),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: [
                    Color(0xFF000000),
                    Color.fromARGB(255, 231, 166, 0),
                    Color.fromARGB(255, 0, 60, 151),
                    Color.fromARGB(255, 182, 0, 136),
                    Color.fromARGB(255, 0, 112, 7),
                    Color.fromARGB(255, 77, 77, 77),
                    Color.fromARGB(255, 96, 0, 175),
                    ].map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: c,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                              bottom: Radius.circular(8),
                            ),
                            side: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => _backgroundColor = c),
                            child: const SizedBox(
                              width: 35,
                              height: 35,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 10),
              // Border color picker
              Align(alignment: Alignment.centerLeft, child: Text("Kolor border", style: TextStyle(color: Colors.white))),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.deepPurpleAccent,
                    Color.fromARGB(255, 255, 255, 0),
                    Color.fromARGB(255, 0, 94, 255),
                    Color.fromARGB(255, 217, 0, 255),
                    Color.fromARGB(255, 0, 255, 0),
                    Color.fromARGB(255, 156, 156, 156),
                    Color.fromARGB(255, 132, 0, 255),
                  ].map((c) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: c,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                              bottom: Radius.circular(8),
                            ),
                            side: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => _borderColor = c),
                            child: const SizedBox(
                              width: 35,
                              height: 35,
                            ),
                          ),
                        ),
                      );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),
              // Text color picker
              Align(alignment: Alignment.centerLeft, child: Text("Kolor tekstu", style: TextStyle(color: Colors.white))),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.white,
                    Color.fromARGB(255, 255, 255, 76),
                    Color.fromARGB(255, 60, 135, 255),
                    Color.fromARGB(255, 233, 110, 255),
                    Color.fromARGB(255, 49, 255, 94),
                    Color.fromARGB(255, 192, 192, 192),
                    Color.fromARGB(255, 158, 85, 255),
                  ].map((c) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: c,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                              bottom: Radius.circular(8),
                            ),
                            side: BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => _textColor = c),
                            child: const SizedBox(
                              width: 35,
                              height: 35,
                            ),
                          ),
                        ),
                      );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text("Rozmiar tekstu", style: TextStyle(color: Colors.white))),
                      Text(_textSize.round().toString(), style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _borderColor,
                      inactiveTrackColor: _borderColor.withAlpha((0.3 * 255).round()),
                      thumbColor: _borderColor,
                      overlayColor: _borderColor.withAlpha((0.2 * 255).round()),
                      valueIndicatorColor: _borderColor,
                    ),
                    child: Slider(
                      min: 8,
                      max: 36,
                      divisions: 28,
                      value: _textSize,
                      label: _textSize.round().toString(),
                      onChanged: (v) => setState(() => _textSize = v),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: Text("Głośność", style: TextStyle(color: Colors.white))),
                      Text("${(_volume * 100).round()}%", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _borderColor,
                      inactiveTrackColor: _borderColor.withAlpha((0.3 * 255).round()),
                      thumbColor: _borderColor,
                      overlayColor: _borderColor.withAlpha((0.2 * 255).round()),
                      valueIndicatorColor: _borderColor,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: 2.0,
                      divisions: 40,
                      value: _volume,
                      label: "${(_volume * 100).round()}%",
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _pickSound,
                icon: const Icon(Icons.audiotrack),
                label: Text(_currentSoundPath.isEmpty ? "Wybierz dźwięk" : "Zmień plik"),
              ),
              if (_currentSoundPath.isNotEmpty)
                Text(_currentSoundPath.split('/').last, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onDelete();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Usuń", style: TextStyle(color: Colors.red)),
                  ),
                  Row(children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anuluj")),
                    ElevatedButton(onPressed: _save, child: const Text("Zapisz")),
                  ])
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
