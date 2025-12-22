import 'dart:io';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final int id;
  final String text;
  final String icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  final double height;
  final double width;

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double borderRadius;
  final double iconRadius;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.id,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.height = 120,
    this.width = 300,
    this.backgroundColor = Colors.black,
    this.borderColor = Colors.deepPurpleAccent,
    this.textColor = Colors.white,
    this.borderRadius = 5,
    this.iconRadius = 10,
    this.fontSize = 18,
  });

  Widget _buildIcon() {
    // jeśli ścieżka zaczyna się od assets – ładujemy asseta
    if (icon.startsWith("assets/")) {
      return Image.asset(
        icon,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }
    // w innym przypadku ładujemy plik z urządzenia
    return Image.file(
      File(icon),
      height: 60,
      width: 60,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        onLongPress: onLongPress,
        splashColor: borderColor.withAlpha((255 * 0.3).round()),
        highlightColor: borderColor.withAlpha((255 * 0.1).round()),
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(iconRadius),
                child: _buildIcon(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
