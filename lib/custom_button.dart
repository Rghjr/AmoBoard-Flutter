
import 'dart:io';
import 'package:flutter/material.dart';

/// A reusable, stylable button widget that displays an icon and a centered label.
/// - Supports tap and optional long-press callbacks.
/// - Loads icon either from assets (when path starts with "assets/") or device file path.
/// - Exposes customization for size, colors, borders, and typography.
class CustomButton extends StatelessWidget {
  final int id;                 // unique identifier (used by parent lists)
  final String text;            // button label
  final String icon;            // path to icon (asset or file)
  final VoidCallback onPressed; // tap handler
  final VoidCallback? onLongPress; // optional long-press handler

  // Layout sizing
  final double height;
  final double width;

  // Visual styling
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

  /// Builds the icon image:
  /// - If path starts with "assets/", loads from app assets.
  /// - Otherwise, treats it as a device file path and loads via [Image.file].
  Widget _buildIcon() {
    // If the path points to an asset — load asset image
    if (icon.startsWith("assets/")) {
      return Image.asset(
        icon,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }
    // Otherwise, load an image file from device storage
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
      color: Colors.transparent, // let parent/container control background where needed
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        onLongPress: onLongPress,
        // Ripple & highlight colors derived from borderColor for visual consistency
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
              // Icon preview with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(iconRadius),
                child: _buildIcon(),
              ),
              const SizedBox(width: 8),
              // Centered text that expands to fill remaining horizontal space
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
