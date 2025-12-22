import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Pages/menu.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, requests required runtime permissions,
/// and launches the root widget of the application.
Future<void> main() async {
  // Required to use async code before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary system permissions before UI is rendered
  await _requestPermissions();

  // Launch application
  runApp(const MyApp());
}

/// Requests all permissions required by the application.
///
/// Permissions are requested at startup to avoid runtime interruptions
/// during audio playback, file access, or media selection.
Future<void> _requestPermissions() async {
  final List<Permission> permissions = [
    Permission.photos,
    Permission.storage,
    Permission.audio,
    Permission.microphone,
    Permission.camera,
  ];

  for (final permission in permissions) {
    final status = await permission.request();

    // Log denied permissions for debugging purposes
    if (!status.isGranted) {
      debugPrint(
        'Permission denied: ${permission.toString()}',
      );
    }
  }
}

/// Root widget of the application.
///
/// Configures the MaterialApp and defines the initial screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      /// Initial application screen
      home: Menu(),
    );
  }
}
