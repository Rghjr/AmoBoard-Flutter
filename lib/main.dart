import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Pages/menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  runApp(const MyApp());
}

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
