import 'dart:io';
import 'package:flutter/material.dart';

/// Custom button widget with icon (asset or file), text, and tap/long press
class CustomButton extends StatelessWidget {
  final int id; // button id, useful for tracking
  final String text; // text label
  final String icon; // path to icon, can be asset or file
  final VoidCallback onPressed; // tap callback
  final VoidCallback? onLongPress; // optional long press callback

  final double height; // button height
  final double width; // button width
  final Color backgroundColor; // button background
  final Color borderColor; // border color
  final Color textColor; // text color
  final double borderRadius; // button corners
  final double iconRadius; // icon corners
  final double fontSize; // text size

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

  /// Builds the icon widget depending on whether it's an asset or file
  Widget _buildIcon() {
    if (icon.startsWith("assets/")) {
      return Image.asset(
        icon,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }
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
        onTap: onPressed, // call onPressed on tap
        onLongPress: onLongPress, // call onLongPress if provided
        splashColor: borderColor.withAlpha((255 * 0.3).round()), // ripple effect
        highlightColor: borderColor.withAlpha((255 * 0.1).round()), // highlight effect
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
