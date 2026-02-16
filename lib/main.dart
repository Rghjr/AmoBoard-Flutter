import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Pages/menu.dart';
import 'Services/database_service.dart';

/// Application entry point.
/// 
/// Initializes Flutter bindings, sets up the Hive database, requests
/// necessary runtime permissions, and launches the root widget.
Future<void> main() async {
  // Initialize Flutter bindings before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database and create default data if needed
  await DatabaseService.initialize();

  // Request runtime permissions for media access
  await _requestPermissions();

  // Launch the application
  runApp(const MyApp());
}

/// Requests runtime permissions needed by the app.
/// 
/// Permissions requested:
/// - photos/storage: For loading and saving images and audio files
/// - audio/microphone: For audio playback and potential recording
/// - camera: For taking pictures within the app
/// 
/// Logs a debug message if any permission is denied but continues execution.
Future<void> _requestPermissions() async {
  final permissions = [
    Permission.photos,
    Permission.storage,
    Permission.audio,
    Permission.microphone,
    Permission.camera,
  ];

  for (var perm in permissions) {
    final status = await perm.request();
    if (!status.isGranted) {
      debugPrint("Brak dostępu do: ${perm.toString()}");
    }
  }
}

/// Root widget of the application.
/// 
/// Configures the MaterialApp with debug banner disabled and
/// sets Menu as the home screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Menu(),
    );
  }
}