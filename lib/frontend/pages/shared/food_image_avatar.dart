import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Circular avatar that shows a food or recipe image if available.
///
/// [imagePath] can be either a local file path (on mobile) or an http/https URL.
/// Falls back to [fallbackIcon] when no image is set or on loading error.
class FoodImageAvatar extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final Color iconColor;
  final Color backgroundColor;
  final double radius;

  const FoodImageAvatar({
    super.key,
    this.imagePath,
    required this.fallbackIcon,
    this.iconColor = Colors.teal,
    this.backgroundColor = const Color(0xFFE0F2F1), // teal.shade50
    this.radius = 18,
  });

  ImageProvider? _imageProvider() {
    if (imagePath == null) return null;
    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      return NetworkImage(imagePath!);
    }
    if (!kIsWeb) return FileImage(File(imagePath!));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider();
    if (provider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: provider,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(fallbackIcon, color: iconColor, size: radius),
    );
  }
}
