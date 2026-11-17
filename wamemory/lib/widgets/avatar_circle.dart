import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.colorHex,
    this.imagePath,
    this.size = 48,
  });

  final String name;
  final String? colorHex;
  final String? imagePath;
  final double size;

  Color get _color {
    if (colorHex == null || colorHex!.isEmpty) return AppColors.accent;
    final hex = colorHex!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final file = path != null && path.isNotEmpty ? File(path) : null;
    final hasImage = file != null && file.existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
        image: hasImage
            ? DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              _initials,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.34,
              ),
            ),
    );
  }
}
