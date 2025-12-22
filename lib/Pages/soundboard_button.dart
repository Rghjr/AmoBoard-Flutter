import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'menu.dart'; // for colorFromHex and colorToHex
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'sound_engine.dart';

/// Represents a single button in the soundboard with editing & playback capabilities
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
  /// Plays the assigned sound with the volume, applying earrape mode if enabled
  void _playSound() {
    final path = widget.data['soundPath'];
    if (path != null && path.isNotEmpty) {
      SoundEngine().play(
        path: path,
        volume: (widget.data['volume'] != null ? (widget.data['volume'] as num).toDouble() : 1.0),
      );
      debugPrint("Playing sound: $path");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Playing: ${widget.data['label']}"), duration: const Duration(milliseconds: 500)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No sound assigned! Long press to edit."), duration: Duration(milliseconds: 1000)),
      );
    }
  }

  /// Opens the editor overlay for this button
  void _showEditor() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            // Editor overlay
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
    final borderColor = colorFromHex(widget.data['borderColor'], Colors.deepPurpleAccent);
    final backgroundColor = colorFromHex(widget.data['backgroundColor'], Colors.black);
    final textColor = colorFromHex(widget.data['textColor'], Colors.white);
    final iconPath = widget.data['iconPath'] ?? 'assets/xd.png';
    final isAsset = !(iconPath.startsWith('/') || iconPath.contains('storage'));
    final textSize = widget.data['textSize'] != null ? (widget.data['textSize'] as num).toDouble() : widget.fontSize;

    return GestureDetector(
      onTap: widget.interactionsEnabled ? _playSound : null,
      onLongPress: widget.interactionsEnabled ? _showEditor : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 5, spreadRadius: 3)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Hero(
                  tag: 'sound_icon_${widget.data['id']}_${DateTime.now().millisecondsSinceEpoch}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius / 1.5),
                    child: isAsset ? Image.asset(iconPath, fit: BoxFit.cover) : Image.file(File(iconPath), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            // Label
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.data['label'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: textSize, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay editor for a single soundboard button
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

  /// Picks a new image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _currentIconPath = image.path);
  }

  /// Picks a new sound file (mp3)
  Future<void> _pickSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _currentSoundPath = result.files.single.path!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected: ${_currentSoundPath.split('/').last}"), duration: const Duration(milliseconds: 800)),
      );
    }
  }

  /// Saves changes and updates parent state
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
    final isAsset = !(_currentIconPath.startsWith('/') || _currentIconPath.contains('storage'));

    /// Builds a horizontal row of color pickers
    Widget buildColorPicker(List<Color> colors, Color selected, Function(Color) onPick) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: colors.map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: c,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)), side: BorderSide(color: Colors.grey, width: 2)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => onPick(c)),
                  child: const SizedBox(width: 35, height: 35),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15), border: Border.all(color: _borderColor, width: 2)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Sound", style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                    child: isAsset ? Image.asset(_currentIconPath, fit: BoxFit.cover) : Image.file(File(_currentIconPath), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Label",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                buildColorPicker([Colors.black, Colors.deepPurpleAccent, Colors.orange, Colors.yellow, Colors.blue, Colors.green, Colors.white], _backgroundColor, (c) => _backgroundColor = c),
                const SizedBox(height: 10),
                buildColorPicker([Colors.deepPurpleAccent, Colors.yellow, Colors.blue, Colors.purple, Colors.green, Colors.grey, Colors.purpleAccent], _borderColor, (c) => _borderColor = c),
                const SizedBox(height: 10),
                buildColorPicker([Colors.white, Colors.yellow, Colors.blue, Colors.pink, Colors.green, Colors.grey, Colors.purple], _textColor, (c) => _textColor = c),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text("Text Size", style: TextStyle(color: Colors.white))),
                    Text(_textSize.round().toString(), style: TextStyle(color: Colors.white)),
                  ],
                ),
                Slider(min: 8, max: 36, divisions: 28, value: _textSize, label: _textSize.round().toString(), onChanged: (v) => setState(() => _textSize = v)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text("Volume", style: TextStyle(color: Colors.white))),
                    Text("${(_volume * 100).round()}%", style: TextStyle(color: Colors.white)),
                  ],
                ),
                Slider(min: 0, max: 2, divisions: 40, value: _volume, label: "${(_volume * 100).round()}%", onChanged: (v) => setState(() => _volume = v)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickSound,
                  icon: const Icon(Icons.audiotrack),
                  label: Text(_currentSoundPath.isEmpty ? "Select Sound" : "Change File"),
                ),
                if (_currentSoundPath.isNotEmpty)
                  Text(_currentSoundPath.split('/').last, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () { widget.onDelete(); Navigator.of(context).pop(); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                    Row(
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(onPressed: _save, child: const Text("Save")),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
