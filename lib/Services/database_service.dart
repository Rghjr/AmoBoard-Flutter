import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../Models/menu_button.dart';
import '../Models/sound_data.dart';

/// Hive database service managing persistent storage for soundboard data.
/// 
/// Handles all database operations including:
/// - Initialization and default data creation
/// - CRUD operations for menu buttons
/// - File management for images and audio
/// - Automatic cleanup of orphaned files
/// - File validation to prevent errors
/// 
/// All operations include comprehensive error handling and return status booleans.
class DatabaseService {
  static const String menuButtonsBox = 'menu_buttons';
  
  static Box<MenuButton>? _menuButtonsBox;

  /// Initializes Hive database and creates default data if empty.
  /// 
  /// Performs the following steps:
  /// 1. Initializes Hive for Flutter
  /// 2. Registers type adapters for custom objects
  /// 3. Opens the menu buttons box
  /// 4. Creates default button if database is empty
  /// 5. Cleans up orphaned files from previous sessions
  /// 
  /// Returns: true if initialization succeeded, false otherwise
  static Future<bool> initialize() async {
    try {
      await Hive.initFlutter();
      
      // Register type adapters for custom classes
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MenuButtonAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SoundDataAdapter());
      }
      
      _menuButtonsBox = await Hive.openBox<MenuButton>(menuButtonsBox);
      
      // Create default data for first-time users
      if (_menuButtonsBox!.isEmpty) {
        debugPrint('📂 Baza pusta - tworzę domyślny przycisk');
        final success = await _createDefaultData();
        if (!success) {
          debugPrint('⚠️ Nie udało się utworzyć domyślnych danych');
          return false;
        }
      } else {
        debugPrint('Baza Hive załadowana: ${_menuButtonsBox!.length} przycisków');
      }
      
      // Clean up files from deleted buttons/sounds
      await cleanUnusedFiles();
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas inicjalizacji bazy: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Creates a default menu button for new installations.
  /// 
  /// Returns: true if creation succeeded, false otherwise
  static Future<bool> _createDefaultData() async {
    try {
      final defaultButton = MenuButton(
        id: 0,
        text: "Nowy Panel",
        icon: "assets/xd.png",
        gridColumns: 2,
        backgroundColor: "#000000",
        backgroundColorLightness: 0,
        borderColor: "#7A30FF",
        borderColorLightness: 0,
        textColor: "#FFFFFF",
        textColorLightness: 0,
        sounds: [],
        buttonRadius: 10.0,
        fontSize: 14.0,
        earrapeEnabled: false,
      );
      
      await _menuButtonsBox!.put(0, defaultButton);
      debugPrint('Utworzono domyślny przycisk menu');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas tworzenia domyślnych danych: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Removes files not referenced in the database to free up storage.
  /// 
  /// Scans all buttons and sounds to build a list of used files,
  /// then deletes any files in app_files directory not in that list.
  /// Should be called after deleting buttons/sounds or canceling edits.
  static Future<void> cleanUnusedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/app_files');
      
      if (!await filesDir.exists()) {
        debugPrint('📂 Folder app_files nie istnieje, pomijam czyszczenie');
        return;
      }
      
      // Collect all file paths currently in use
      Set<String> usedFiles = {};
      final buttons = _menuButtonsBox!.values.toList();
      
      for (var button in buttons) {
        // Add button icon if it's a file (not asset)
        if (!button.icon.startsWith('assets/') && await _fileExists(button.icon)) {
          usedFiles.add(button.icon);
        }
        
        // Add sound files and icons
        for (var sound in button.sounds) {
          if (!sound.iconPath.startsWith('assets/') && await _fileExists(sound.iconPath)) {
            usedFiles.add(sound.iconPath);
          }
          if (!sound.soundPath.startsWith('assets/') && await _fileExists(sound.soundPath)) {
            usedFiles.add(sound.soundPath);
          }
        }
      }
      
      // Delete files not in the used set
      final allFiles = filesDir.listSync();
      int deletedCount = 0;
      
      for (var entity in allFiles) {
        if (entity is File) {
          final filePath = entity.path;
          if (!usedFiles.contains(filePath)) {
            try {
              await entity.delete();
              deletedCount++;
              debugPrint('🗑️ Usunięto nieuż_ywany plik: $filePath');
            } catch (e) {
              debugPrint('⚠️ Nie można usunąć pliku $filePath: $e');
            }
          }
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('Wyczyszczono $deletedCount nieużywanych plików');
      } else {
        debugPrint('Wszystkie pliki są używane, nic do czyszczenia');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Błąd podczas czyszczenia plików: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Checks if a file exists on disk.
  /// 
  /// Asset paths always return true as they're bundled with the app.
  /// 
  /// Returns: true if file exists and is accessible, false otherwise
  static Future<bool> _fileExists(String filePath) async {
    try {
      if (filePath.isEmpty || filePath.startsWith('assets/')) {
        return true;
      }
      
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('⚠️ Błąd podczas sprawdzania pliku $filePath: $e');
      return false;
    }
  }

  /// Validates a file path before using it.
  /// 
  /// Checks:
  /// - Path is not empty
  /// - Asset paths are always valid
  /// - File exists on disk
  /// - File is readable
  /// 
  /// Returns: validated path if valid, null if invalid
  static Future<String?> validateFilePath(String filePath) async {
    try {
      if (filePath.isEmpty) {
        debugPrint('⚠️ Pusta ścieżka pliku');
        return null;
      }
      
      if (filePath.startsWith('assets/')) {
        return filePath;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('⚠️ Plik nie istnieje: $filePath');
        return null;
      }
      
      // Verify file is readable
      try {
        await file.length();
      } catch (e) {
        debugPrint('⚠️ Plik nie jest czytelny: $filePath');
        return null;
      }
      
      return filePath;
    } catch (e) {
      debugPrint('⚠️ Błąd podczas walidacji pliku $filePath: $e');
      return null;
    }
  }

  /// Retrieves all menu buttons sorted by ID.
  /// 
  /// Returns: list of all buttons, or empty list on error
  static List<MenuButton> getAllButtons() {
    try {
      return _menuButtonsBox!.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    } catch (e) {
      debugPrint('❌ Błąd podczas pobierania przycisków: $e');
      return [];
    }
  }

  /// Retrieves a specific menu button by ID.
  /// 
  /// Returns: MenuButton if found, null otherwise
  static MenuButton? getButton(int id) {
    try {
      return _menuButtonsBox!.get(id);
    } catch (e) {
      debugPrint('❌ Błąd podczas pobierania przycisku $id: $e');
      return null;
    }
  }

  /// Saves a menu button to the database.
  /// 
  /// Returns: true if save succeeded, false otherwise
  static Future<bool> saveButton(MenuButton button) async {
    try {
      await _menuButtonsBox!.put(button.id, button);
      debugPrint('Zapisano przycisk ${button.id}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas zapisywania przycisku: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Updates an existing menu button.
  /// 
  /// Ensures button ID matches the provided key before saving.
  /// 
  /// Returns: true if update succeeded, false otherwise
  static Future<bool> updateButton(int id, MenuButton button) async {
    try {
      button.id = id;
      await _menuButtonsBox!.put(id, button);
      debugPrint('Zaktualizowano przycisk $id');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas aktualizacji przycisku: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Deletes a menu button from the database.
  /// 
  /// Note: Associated files should be cleaned up with cleanUnusedFiles().
  /// 
  /// Returns: true if deletion succeeded, false otherwise
  static Future<bool> deleteButton(int id) async {
    try {
      await _menuButtonsBox!.delete(id);
      debugPrint('Usunięto przycisk $id');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas usuwania przycisku: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Saves all buttons with sequential IDs.
  /// 
  /// Clears the database and saves buttons in order with IDs 0, 1, 2, etc.
  /// Useful after reordering buttons.
  /// 
  /// Returns: true if operation succeeded, false otherwise
  static Future<bool> saveAllButtons(List<MenuButton> buttons) async {
    try {
      await _menuButtonsBox!.clear();
      for (int i = 0; i < buttons.length; i++) {
        buttons[i].id = i;
        await _menuButtonsBox!.put(i, buttons[i]);
      }
      debugPrint('Zapisano wszystkie przyciski (${buttons.length})');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas zapisywania wszystkich przycisków: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Copies a file from external storage to the app's private directory.
  /// 
  /// Process:
  /// 1. Validates source file exists and is readable
  /// 2. Checks file size (max 50MB)
  /// 3. Creates app_files directory if needed
  /// 4. Generates unique filename with timestamp
  /// 5. Copies file and validates copy
  /// 
  /// Returns: path to copied file, or null on failure
  static Future<String?> copyFileToAppDir(String sourcePath) async {
    try {
      if (sourcePath.isEmpty) {
        debugPrint('⚠️ Pusta ścieżka źródłowa');
        return null;
      }
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('⚠️ Plik źródłowy nie istnieje: $sourcePath');
        return null;
      }
      
      // Check file size limit (50MB)
      final fileSize = await sourceFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        debugPrint('⚠️ Plik zbyt duży (${fileSize / 1024 / 1024} MB): $sourcePath');
        return null;
      }
      
      // Create target directory
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/app_files');
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final fileName = path.basename(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final targetPath = path.join(filesDir.path, newFileName);
      
      // Copy file
      await sourceFile.copy(targetPath);
      
      // Validate copy succeeded
      final copiedFile = File(targetPath);
      if (!await copiedFile.exists()) {
        debugPrint('❌ Nie udało się skopiować pliku');
        return null;
      }
      
      debugPrint('📄 Skopiowano nowy plik: $sourcePath -> $targetPath');
      return targetPath;
    } catch (e, stackTrace) {
      debugPrint('❌ Błąd podczas kopiowania pliku: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Closes the database connection.
  /// 
  /// Should be called when the app is shutting down.
  static Future<void> close() async {
    try {
      await _menuButtonsBox?.close();
      debugPrint('Zamknięto bazę danych');
    } catch (e) {
      debugPrint('⚠️ Błąd podczas zamykania bazy: $e');
    }
  }
}