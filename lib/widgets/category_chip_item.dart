import 'package:flutter/material.dart';

import '../utils/format_helper.dart';

/// Komponen Card/Chip Kategori yang seragam di seluruh aplikasi
/// (Halaman Riwayat Transaksi dan Form Catat Transaksi).
class CategoryChipItem extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAll;

  const CategoryChipItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.isAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isAll
        ? theme.colorScheme.primary
        : FormatHelper.getCategoryColor(category);
    final icon = isAll
        ? Icons.grid_view_rounded
        : FormatHelper.getCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
