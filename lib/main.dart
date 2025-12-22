
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Pages/menu.dart';

/// Entry point of the app.
/// Ensures Flutter bindings are initialized, requests runtime permissions,
/// and then launches the root widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  runApp(const MyApp());
}

/// Requests a set of runtime permissions needed by the app:
/// - photos/storage: for loading/saving images and files
/// - audio/microphone: for audio playback/recording (if used)
/// - camera: for picking/taking pictures (if used)
/// Logs a message for any permission that is not granted.
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
/// Disables the debug banner and sets `Menu` as the home screen.
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
