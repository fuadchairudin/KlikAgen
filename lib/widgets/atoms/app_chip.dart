import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP CHIP — Status badge/chip Atom
/// ═══════════════════════════════════════

enum AppChipVariant { info, success, warning, danger, neutral }

class AppChip extends StatelessWidget {
  final String label;
  final AppChipVariant variant;
  final IconData? icon;
  final double fontSize;

  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.info,
    this.icon,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      AppChipVariant.info => AppTheme.accent,
      AppChipVariant.success => AppTheme.accentGreen,
      AppChipVariant.warning => AppTheme.accentOrange,
      AppChipVariant.danger => AppTheme.accentRed,
      AppChipVariant.neutral => AppTheme.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
