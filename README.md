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

### App Logo
![App Logo](screenshots/android_logo.jpg)

### Main Menu
![Main Menu](screenshots/menu.jpg)  
The main menu displays the top icon and soundboard panels. Panels can be opened and edited by long-pressing, and new panels can be added via the plus button.

### Add New Soundboard Page
![Add New Soundboard](screenshots/dodaj_nowy_przycisk.jpg)  
This page allows editing the panel's name, background color, border, text style, number of columns, and changing the icon by tapping on it.

### Soundboard Page
![Soundboard Page](screenshots/dodaj_nowy_przycisk_do_panelu.jpg)  
The soundboard panel includes a central **Earrape** toggle button at the top, a back button and title on the left, stop button on the right, drag & drop button for reordering, and a plus button to add new sounds. Below are the sound buttons, which can be tapped or long-pressed for editing.

### Edit Sound
![Edit Sound](screenshots/edycja_dzwieku.jpg)  
This screen allows editing a specific sound: change the icon, name, background color, border, text style and size, volume, and select an audio file.

---

## 👤 Author

Krystian Strzępek  

---

## 📄 License

This project is for **educational purposes** and **portfolio use only**.  
All assets and code are owned by the author and cannot be used commercially without permission.
