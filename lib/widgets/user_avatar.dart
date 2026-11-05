import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user.dart';

/// Model preset avatar profil
class AvatarPreset {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AvatarPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

/// Daftar pilihan preset avatar profil Duitin
class AvatarPresets {
  static const List<AvatarPreset> list = [
    AvatarPreset(
      id: 'avatar_student',
      label: 'Mahasiswa',
      icon: Icons.school_rounded,
      backgroundColor: Color(0xFFE8EAF6),
      iconColor: Color(0xFF3F51B5),
    ),
    AvatarPreset(
      id: 'avatar_developer',
      label: 'Tech Enthusiast',
      icon: Icons.terminal_rounded,
      backgroundColor: Color(0xFFE0F2F1),
      iconColor: Color(0xFF00796B),
    ),
    AvatarPreset(
      id: 'avatar_savings',
      label: 'Pejuang Hemat',
      icon: Icons.savings_rounded,
      backgroundColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
    ),
    AvatarPreset(
      id: 'avatar_cool',
      label: 'Gaya Santai',
      icon: Icons.sentiment_very_satisfied_rounded,
      backgroundColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
    ),
    AvatarPreset(
      id: 'avatar_rocket',
      label: 'Ambisius',
      icon: Icons.rocket_launch_rounded,
      backgroundColor: Color(0xFFF3E5F5),
      iconColor: Color(0xFF7B1FA2),
    ),
    AvatarPreset(
      id: 'avatar_star',
      label: 'Juara Finansial',
      icon: Icons.star_rounded,
      backgroundColor: Color(0xFFFFFDE7),
      iconColor: Color(0xFFF57F17),
    ),
    AvatarPreset(
      id: 'avatar_coffee',
      label: 'Pecinta Kopi',
      icon: Icons.coffee_rounded,
      backgroundColor: Color(0xFFEFEBE9),
      iconColor: Color(0xFF5D4037),
    ),
    AvatarPreset(
      id: 'avatar_investor',
      label: 'Investor Cerdas',
      icon: Icons.trending_up_rounded,
      backgroundColor: Color(0xFFE1F5FE),
      iconColor: Color(0xFF0277BD),
    ),
  ];

  static AvatarPreset? getById(String? id) {
    if (id == null) return null;
    try {
      return list.firstWhere((preset) => preset.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Widget Avatar Pengguna yang konsisten di seluruh aplikasi.
class UserAvatar extends StatelessWidget {
  final User? user;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.user,
    this.radius = 24,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarValue = user?.avatar;
    final preset = AvatarPresets.getById(avatarValue);

    Widget avatarContent;
    if (avatarValue != null &&
        avatarValue.isNotEmpty &&
        preset == null &&
        File(avatarValue).existsSync()) {
      // Foto kustom dari galeri/kamera pengguna
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: FileImage(File(avatarValue)),
      );
    } else if (preset != null) {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: preset.backgroundColor,
        child: Icon(preset.icon, size: radius * 1.1, color: preset.iconColor),
      );
    } else {
      // Default: Inisial nama dengan background container
      final initial = user?.name.isNotEmpty == true
          ? user!.name[0].toUpperCase()
          : 'U';
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    if (!showEditBadge && onTap == null) {
      return avatarContent;
    }

    return Stack(
      children: [
        GestureDetector(onTap: onTap, child: avatarContent),
        if (showEditBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
