import 'package:flutter/material.dart';
import 'colors.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  dynamic icon, // 👈 Changed to dynamic to accept IconData or String
  required String title,
  required String content,
  String? primaryText,
  VoidCallback? onPrimary,
  String? secondaryText,
  VoidCallback? onSecondary,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // 🔥 Fixes the pinkish tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Bolder rounding
      ),
      // 🔹 Your specific paddings preserved exactly
      titlePadding: const EdgeInsets.only(top: 10, left: 20, right: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      actionsPadding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),

      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            // 🔹 Logic to handle both IconData and String paths
            if (icon is IconData)
              Icon(icon, size: 55, color: Colorprimary)
            else if (icon is String)
              Image.asset(icon, height: 55, fit: BoxFit.contain),

            const SizedBox(height: 15),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900, // Thick bold as per image
              color: Colorprimary,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
          height: 1.4,
        ),
      ),
      actions: [
        Row(
          children: [
            // 1. PRIMARY BUTTON (Filled - Left Side)
            if (primaryText != null)
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colorprimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: onPrimary,
                  child: Text(
                    primaryText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),

            // Gap only if both buttons exist
            if (primaryText != null && secondaryText != null)
              const SizedBox(width: 10),

            // 2. SECONDARY BUTTON (Outlined - Right Side)
            if (secondaryText != null)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black54, width: 1.2),
                    foregroundColor: Colorprimary,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: onSecondary ?? () => Navigator.pop(context),
                  child: Text(
                    secondaryText,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colorprimary
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class StatusPopups {
  static Future<void> show({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3), // Optional auto-close
  }) {
    // Show the dialog
    final dialog = showDialog(
      context: context,
      barrierDismissible: true, // Dismiss by tapping outside
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75, // Matches the width in image
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Large Brand Icon
                Icon(
                  icon,
                  size: 80,
                  color: Colorprimary, // Uses your teal brand color
                ),
                const SizedBox(height: 20),

                // 2. Bold Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                // 3. Optional Subtitle
                if (subtitle != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return dialog;
  }
}