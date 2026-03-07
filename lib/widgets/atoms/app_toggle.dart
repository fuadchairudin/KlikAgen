import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP TOGGLE — Switch Atom
/// ═══════════════════════════════════════
/// Styled toggle untuk Admin Dalam, Piutang, dll.

class AppToggle extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final FocusNode? focusNode;
  final bool hasFocus;
  final Color? activeColor;
  final IconData? icon;

  const AppToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.hasFocus = false,
    this.activeColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.accent;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      focusNode: focusNode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFocus
                ? AppTheme.accent
                : (value
                      ? color.withValues(alpha: 0.3)
                      : AppTheme.dividerColor),
            width: hasFocus ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: value ? color : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? color : AppTheme.textSecondary,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
