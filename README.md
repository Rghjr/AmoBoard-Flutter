# 🎵 Custom Soundboard App (Flutter)

Advanced, fully customizable soundboard application built with **Flutter**.  
The app allows users to create dynamic soundboards with custom sounds, icons, layouts, and real-time audio control.

Project created as a larger, modular mobile application — most writen manually, a little bit help from AI

---

## 🚀 Features

- 🎛️ Customizable soundboard buttons (label, icon, colors)
- 🔊 Advanced audio engine with volume boosting (earrape mode 😈)
- 🖼️ Icons from assets or user-selected images
- 🎚️ Individual volume control per sound (0–200%+)
- 📐 Configurable grid layout (columns, rounding, font size)
- 🔄 Drag & drop reordering (menu + soundboard)
- 💾 Persistent data storage using SharedPreferences
- 📱 Android-ready (permissions, file system, audio)

---

## 🧠 Architecture Overview

- Flutter (Dart)
- Custom widgets for reusable UI components
- Singleton-based audio engine
- Page-based navigation
- Local persistence via SharedPreferences
- Asset + file-based media handling

---

## 🔊 Audio Engine

The app uses **just_audio** with a custom playback engine that:

- Supports volume levels above 100%
- Dynamically spawns multiple audio players
- Allows global stop of all active sounds
- Includes optional global volume boost mode

---

## 📦 Dependencies

Key packages used in the project:

- just_audio
- shared_preferences
- image_picker
- file_picker
- permission_handler
- audioplayers

See `pubspec.yaml` for the full list.

---

## 🛠️ Setup & Run

flutter pub get  
flutter run

Make sure you run the app on a real device or emulator with audio support.

---

## 📸 Screenshots

(To be added)

---

## 👤 Author

Krystian Strzępek  
Flutter / Mobile Developer

---

## 📄 License

This project is for educational and portfolio purposes.
