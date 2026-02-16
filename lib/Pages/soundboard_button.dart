// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../Utils/color_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../Services/sound_engine.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:just_audio/just_audio.dart';
import '../Services/database_service.dart';

/// Interactive sound button widget for soundboard grids.
/// 
/// Features:
/// - Tap to play sound with configurable volume and clipping
/// - Long-press to open editor overlay for customization
/// - Custom colors with lightness adjustments
/// - Icon and label display with error handling
/// - Real-time preview of changes
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
  /// Plays the sound associated with this button.
  /// 
  /// Handles time-based clipping if start/end times are set.
  /// Shows feedback snackbar on success or error.
  void _playSound() async {
    try {
      final path = widget.data['soundPath'];

      if (path != null && path.toString().isNotEmpty) {
        // Get clip times in seconds
        final startSeconds = widget.data['startTime'] ?? 0.0;
        final endSeconds = widget.data['endTime'];
        
        final success = await SoundEngine().play(
          path: path,
          volume: (widget.data['volume'] != null ? (widget.data['volume'] as num).toDouble() : 1.0),
          startTime: Duration(milliseconds: (startSeconds * 1000).round()),
          endTime: endSeconds != null ? Duration(milliseconds: (endSeconds * 1000).round()) : null,
        );
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Odtwarzanie: ${widget.data['label']}"), 
              duration: const Duration(milliseconds: 500)
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Brak przypisanego dźwięku! Przytrzymaj, aby edytować."), 
              duration: Duration(milliseconds: 1000)
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Błąd podczas odtwarzania"), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// Opens the editor overlay for customizing this sound button.
  void _showEditor() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
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
    try {
      // Apply lightness offsets to colors
      Color borderColor = applyLightnessOffset(
        colorFromHex(widget.data['borderColor'], Colors.deepPurpleAccent),
        widget.data['borderColor_lightness'] ?? 0
      );
      Color backgroundColor = applyLightnessOffset(
        colorFromHex(widget.data['backgroundColor'], Colors.black),
        widget.data['backgroundColor_lightness'] ?? 0
      );
      Color textColor = applyLightnessOffset(
        colorFromHex(widget.data['textColor'], Colors.white),
        widget.data['textColor_lightness'] ?? 0
      );
      
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
                          ? Image.asset(
                              iconPath, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('⚠️ Failed to load asset: $iconPath');
                                return _buildErrorIcon();
                              },
                            )
                          : Image.file(
                              File(iconPath), 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('⚠️ Failed to load file: $iconPath');
                                return _buildErrorIcon();
                              },
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          widget.data['label'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: textColor,
                            fontSize: textSize,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building SoundboardButton: $e');
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      );
    }
  }

  Widget _buildErrorIcon() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
    );
  }
}

/// Modal overlay for editing sound button settings.
/// 
/// Provides controls for:
/// - Icon and sound file selection
/// - Color customization with lightness sliders
/// - Volume and text size adjustment
/// - Audio clipping (start/end time selection)
/// - Real-time preview of changes
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
  
  // Base colors (without lightness offset)
  late Color _baseBorderColor;
  late Color _baseBackgroundColor;
  late Color _baseTextColor;
  
  // Lightness offsets
  late int _borderLightness;
  late int _backgroundLightness;
  late int _textLightness;
  
  late double _volume;
  late double _textSize;
  
  // Sound clip settings (in seconds)
  double _startTime = 0.0;
  double _endTime = 0.0;
  double _soundDuration = 0.0;
  bool _isLoadingDuration = false;

  @override
  void initState() {
    super.initState();
    try {
      _nameController = TextEditingController(text: widget.data['label']);
      _currentIconPath = widget.data['iconPath'] ?? 'assets/xd.png';
      _currentSoundPath = widget.data['soundPath'] ?? '';
      
      // Load base colors
      _baseBorderColor = colorFromHex(widget.data['borderColor'], Colors.white);
      _baseBackgroundColor = colorFromHex(widget.data['backgroundColor'], Colors.black);
      _baseTextColor = colorFromHex(widget.data['textColor'], Colors.white);
      
      // Load lightness offsets
      _borderLightness = widget.data['borderColor_lightness'] ?? 0;
      _backgroundLightness = widget.data['backgroundColor_lightness'] ?? 0;
      _textLightness = widget.data['textColor_lightness'] ?? 0;
      
      _volume = (widget.data['volume'] != null ? (widget.data['volume'] as num).toDouble() : 1.0);
      _textSize = widget.data['textSize'] != null ? (widget.data['textSize'] as num).toDouble() : 16.0;
      
      // Load sound clip times
      _startTime = (widget.data['startTime'] != null ? (widget.data['startTime'] as num).toDouble() : 0.0);
      _endTime = (widget.data['endTime'] != null ? (widget.data['endTime'] as num).toDouble() : 0.0);
      
      // Load sound duration if sound is already set
      if (_currentSoundPath.isNotEmpty) {
        _loadSoundDuration();
      }
    } catch (e) {
      debugPrint('❌ Error in _SoundEditorOverlay initState: $e');
      // Initialize with safe defaults
      _nameController = TextEditingController(text: 'Błąd');
      _currentIconPath = 'assets/xd.png';
      _currentSoundPath = '';
      _baseBorderColor = Colors.white;
      _baseBackgroundColor = Colors.black;
      _baseTextColor = Colors.white;
      _borderLightness = 0;
      _backgroundLightness = 0;
      _textLightness = 0;
      _volume = 1.0;
      _textSize = 16.0;
    }
  }

  /// Opens image picker and cropper, then saves selected image.
  Future<void> _pickAndCropImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Validate picked file
      final validPath = await DatabaseService.validateFilePath(image.path);
      if (validPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wybrany plik nie istnieje lub jest uszkodzony')),
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
        // Copy file to app directory
        final copiedPath = await DatabaseService.copyFileToAppDir(croppedFile.path);
        
        if (copiedPath != null) {
          setState(() {
            _currentIconPath = copiedPath;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nie udało się zapisać obrazka')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking and cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas wybierania obrazka')),
        );
      }
    }
  }

  /// Opens file picker for MP3 files and saves selected sound.
  Future<void> _pickSound() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        
        // Validate picked file
        final validPath = await DatabaseService.validateFilePath(selectedPath);
        if (validPath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wybrany plik nie istnieje lub jest uszkodzony')),
            );
          }
          return;
        }
        
        // Copy file to app directory
        final copiedPath = await DatabaseService.copyFileToAppDir(selectedPath);
        
        if (copiedPath != null) {
          setState(() {
            _currentSoundPath = copiedPath;
          });
          
          // Load duration of new sound
          await _loadSoundDuration();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Wybrano: ${selectedPath.split('/').last}"),
                duration: const Duration(milliseconds: 800),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nie udało się skopiować pliku dźwiękowego')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas wybierania dźwięku')),
        );
      }
    }
  }
  
  /// Loads sound duration and sets default values for clip slider.
  Future<void> _loadSoundDuration() async {
    if (_currentSoundPath.isEmpty) return;
    
    setState(() {
      _isLoadingDuration = true;
    });
    
    try {
      // Validate sound file before loading
      if (!_currentSoundPath.startsWith('assets/')) {
        final validPath = await DatabaseService.validateFilePath(_currentSoundPath);
        if (validPath == null) {
          debugPrint('⚠️ Sound file is not valid: $_currentSoundPath');
          setState(() {
            _isLoadingDuration = false;
          });
          return;
        }
      }
      
      final player = AudioPlayer();
      
      if (_currentSoundPath.startsWith('assets/')) {
        await player.setAsset(_currentSoundPath);
      } else {
        await player.setFilePath(_currentSoundPath);
      }
      
      final duration = await player.duration;
      
      if (duration != null) {
        setState(() {
          _soundDuration = duration.inMilliseconds / 1000.0;
          // Set default to full sound if no times are set
          if (_endTime == 0.0 || _endTime > _soundDuration) {
            _endTime = _soundDuration;
          }
          if (_startTime >= _endTime) {
            _startTime = 0.0;
          }
        });
      }
      
      await player.dispose();
    } catch (e) {
      debugPrint('❌ Błąd podczas wczytywania długości dźwięku: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się wczytać długości dźwięku')),
        );
      }
    } finally {
      setState(() {
        _isLoadingDuration = false;
      });
    }
  }
  
  /// Tests sound playback with selected clip settings.
  void _testSound() {
    try {
      if (_currentSoundPath.isEmpty) return;
      
      SoundEngine().play(
        path: _currentSoundPath,
        volume: _volume,
        startTime: Duration(milliseconds: (_startTime * 1000).round()),
        endTime: Duration(milliseconds: (_endTime * 1000).round()),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Test: ${_startTime.toStringAsFixed(1)}s - ${_endTime.toStringAsFixed(1)}s"),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error testing sound: $e');
    }
  }

  /// Saves all changes and closes the editor.
  Future<void> _save() async {
    try {
      final updated = Map<String, dynamic>.from(widget.data);
      updated['label'] = _nameController.text;
      updated['iconPath'] = _currentIconPath;
      updated['soundPath'] = _currentSoundPath;
      
      // Save base colors (without lightness)
      updated['borderColor'] = '#${colorToHex(_baseBorderColor)}';
      updated['backgroundColor'] = '#${colorToHex(_baseBackgroundColor)}';
      updated['textColor'] = '#${colorToHex(_baseTextColor)}';
      
      // Save lightness offsets
      updated['borderColor_lightness'] = _borderLightness;
      updated['backgroundColor_lightness'] = _backgroundLightness;
      updated['textColor_lightness'] = _textLightness;
      
      updated['volume'] = _volume;
      updated['textSize'] = _textSize.round();
      
      // Save sound clip times
      updated['startTime'] = _startTime;
      updated['endTime'] = _endTime;

      widget.onSave(updated);
      
      // Clean up old files
      await DatabaseService.cleanUnusedFiles();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error saving sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas zapisywania')),
        );
      }
    }
  }

  /// Creates a color selection button.
  Widget _colorButton(Color color, Function(Color) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(8),
          ),
          side: BorderSide(color: Colors.grey, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(color),
          child: const SizedBox(width: 35, height: 35),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      bool isAsset = !(_currentIconPath.startsWith('/') || _currentIconPath.contains('storage'));
      
      // Compute final colors with lightness applied for preview
      final borderColor = applyLightnessOffset(_baseBorderColor, _borderLightness);
      final backgroundColor = applyLightnessOffset(_baseBackgroundColor, _backgroundLightness);
      final textColor = applyLightnessOffset(_baseTextColor, _textLightness);

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edytuj Dźwięk", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Icon chooser
                  GestureDetector(
                    onTap: _pickAndCropImage,
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                      child: isAsset
                          ? Image.asset(
                              _currentIconPath, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorIcon();
                              },
                            )
                          : Image.file(
                              File(_currentIconPath), 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorIcon();
                              },
                            ),
                    ),
                  ),
                  const Text("Kliknij by zmienić", style: TextStyle(color: Colors.grey, fontSize: 9)),
                  const SizedBox(height: 10),
                  
                  // Label input
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Nazwa",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Background color
                  const Align(alignment: Alignment.centerLeft, child: Text("Kolor tła", style: TextStyle(color: Colors.white, fontSize: 12))),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 340,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      runSpacing: 6,
                      children: [
                        _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) => setState(() => _baseBackgroundColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) => setState(() => _baseBackgroundColor = c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Jasność tła: ${_backgroundLightness > 0 ? '+' : ''}$_backgroundLightness%", 
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Slider(
                    value: _backgroundLightness.toDouble(),
                    min: -25, max: 25, divisions: 50,
                    activeColor: backgroundColor,
                    onChanged: (val) => setState(() => _backgroundLightness = val.toInt()),
                  ),

                  const SizedBox(height: 6),
                  // Border color
                  const Align(alignment: Alignment.centerLeft, child: Text("Kolor border", style: TextStyle(color: Colors.white, fontSize: 12))),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 340,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      runSpacing: 6,
                      children: [
                        _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) => setState(() => _baseBorderColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) => setState(() => _baseBorderColor = c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Jasność border: ${_borderLightness > 0 ? '+' : ''}$_borderLightness%", 
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Slider(
                    value: _borderLightness.toDouble(),
                    min: -25, max: 25, divisions: 50,
                    activeColor: borderColor,
                    onChanged: (val) => setState(() => _borderLightness = val.toInt()),
                  ),

                  const SizedBox(height: 6),
                  // Text color
                  const Align(alignment: Alignment.centerLeft, child: Text("Kolor tekstu", style: TextStyle(color: Colors.white, fontSize: 12))),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 340,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      runSpacing: 6,
                      children: [
                        _colorButton(const Color.fromARGB(255, 0, 0, 0), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 0), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 111, 0), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 0), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 0), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 255, 255), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 0, 94, 255), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 132, 0, 255), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 0, 255), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 75, 54, 33), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 156, 156, 156), (c) => setState(() => _baseTextColor = c)),
                        _colorButton(const Color.fromARGB(255, 255, 255, 255), (c) => setState(() => _baseTextColor = c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Jasność tekstu: ${_textLightness > 0 ? '+' : ''}$_textLightness%", 
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Slider(
                    value: _textLightness.toDouble(),
                    min: -25, max: 25, divisions: 50,
                    activeColor: textColor,
                    onChanged: (val) => setState(() => _textLightness = val.toInt()),
                  ),

                  const SizedBox(height: 10),

                  // Text size slider
                  Row(
                    children: [
                      const Expanded(child: Text("Rozmiar tekstu", style: TextStyle(color: Colors.white, fontSize: 12))),
                      Text(_textSize.round().toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: borderColor,
                      inactiveTrackColor: borderColor.withAlpha((0.3 * 255).round()),
                      thumbColor: borderColor,
                    ),
                    child: Slider(
                      min: 8, max: 36, divisions: 28,
                      value: _textSize,
                      onChanged: (v) => setState(() => _textSize = v),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Volume slider
                  Row(
                    children: [
                      const Expanded(child: Text("Głośność", style: TextStyle(color: Colors.white, fontSize: 12))),
                      Text("${(_volume * 100).round()}%", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: borderColor,
                      inactiveTrackColor: borderColor.withAlpha((0.3 * 255).round()),
                      thumbColor: borderColor,
                    ),
                    child: Slider(
                      min: 0.0, max: 2.0, divisions: 40,
                      value: _volume,
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sound file picker
                  ElevatedButton.icon(
                    onPressed: _pickSound,
                    icon: const Icon(Icons.audiotrack, size: 18),
                    label: Text(_currentSoundPath.isEmpty ? "Wybierz dźwięk" : "Zmień plik", style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                  if (_currentSoundPath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_currentSoundPath.split('/').last, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                    ),
                  
                  // Sound clip section (only shown when sound is selected)
                  if (_currentSoundPath.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Fragment dźwięku", style: TextStyle(color: Colors.white, fontSize: 12)),
                        if (_isLoadingDuration)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_soundDuration > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Od: ${_startTime.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text("Długość: ${(_endTime - _startTime).toStringAsFixed(1)}s", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("Do: ${_endTime.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: borderColor,
                          inactiveTrackColor: borderColor.withAlpha((0.3 * 255).round()),
                          thumbColor: borderColor,
                          overlayColor: borderColor.withAlpha((0.2 * 255).round()),
                          rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                          rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                        ),
                        child: RangeSlider(
                          min: 0.0,
                          max: _soundDuration,
                          divisions: (_soundDuration * 10).round(),
                          values: RangeValues(_startTime, _endTime),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _startTime = values.start;
                              _endTime = values.end;
                            });
                          },
                          labels: RangeLabels(
                            "${_startTime.toStringAsFixed(1)}s",
                            "${_endTime.toStringAsFixed(1)}s",
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Test button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _testSound,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text("Test dźwięku", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: borderColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Footer actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            widget.onDelete();
                            await DatabaseService.cleanUnusedFiles();
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            debugPrint('❌ Error deleting: $e');
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Text("Usuń", style: TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                      Row(children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              await DatabaseService.cleanUnusedFiles();
                              
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              debugPrint('❌ Error during cancel: $e');
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text("Anuluj", style: TextStyle(fontSize: 13)),
                        ),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text("Zapisz", style: TextStyle(fontSize: 13)),
                        ),
                      ])
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building _SoundEditorOverlay: $e');
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.red[900],
          child: const Text('Błąd wyświetlania edytora', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget _buildErrorIcon() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
    );
  }
}