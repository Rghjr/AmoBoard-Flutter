import 'dart:io';
import 'package:flutter/material.dart';

/// A reusable, customizable button widget with icon and text label.
/// 
/// Supports both asset images and device file paths for the icon.
/// Provides tap and long-press callbacks with Material Design ripple effects.
/// All visual properties are customizable via constructor parameters.
/// 
/// Note: Color parameters should have lightness offsets pre-applied via
/// applyLightnessOffset() from color_utils.dart before being passed to this widget.
class CustomButton extends StatelessWidget {
  final int id;                 // Unique identifier for list management
  final String text;            // Button label text
  final String icon;            // Path to icon (asset or file)
  final VoidCallback onPressed; // Tap handler
  final VoidCallback? onLongPress; // Optional long-press handler

  // Layout dimensions
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

  /// Builds the icon widget from either assets or file system.
  /// 
  /// Handles loading errors gracefully by displaying a fallback icon.
  /// Asset paths are detected by the "assets/" prefix.
  Widget _buildIcon() {
    try {
      if (icon.startsWith("assets/")) {
        return Image.asset(
          icon,
          height: 60,
          width: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ Failed to load asset icon: $icon');
            return _buildErrorIcon();
          },
        );
      }
      
      final file = File(icon);
      return Image.file(
        file,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('⚠️ Failed to load file icon: $icon');
          return _buildErrorIcon();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error loading icon: $e');
      return _buildErrorIcon();
    }
  }

  /// Returns a fallback icon displayed when image loading fails.
  Widget _buildErrorIcon() {
    return Container(
      height: 60,
      width: 60,
      color: Colors.grey[800],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 30,
      ),
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
        // Ripple colors derived from borderColor for visual consistency
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
              // Icon with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(iconRadius),
                child: _buildIcon(),
              ),
              const SizedBox(width: 8),
              // Text label centered in remaining space
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