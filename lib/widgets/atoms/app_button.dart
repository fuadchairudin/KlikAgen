import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP BUTTON — Button Atom
/// ═══════════════════════════════════════
/// Variants: Primary, Secondary, Danger, Ghost, Icon

enum AppButtonVariant { primary, secondary, danger, ghost }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand; // full width

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.small => 36.0,
      AppButtonSize.medium => 44.0,
      AppButtonSize.large => 52.0,
    };

    final fontSize = switch (size) {
      AppButtonSize.small => 12.0,
      AppButtonSize.medium => 14.0,
      AppButtonSize.large => 16.0,
    };

    final bgColor = switch (variant) {
      AppButtonVariant.primary => AppTheme.primaryMid,
      AppButtonVariant.secondary => Colors.transparent,
      AppButtonVariant.danger => AppTheme.accentRed,
      AppButtonVariant.ghost => Colors.transparent,
    };

    final fgColor = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => AppTheme.accent,
      AppButtonVariant.danger => Colors.white,
      AppButtonVariant.ghost => AppTheme.textSecondary,
    };

    final borderColor = switch (variant) {
      AppButtonVariant.primary => Colors.transparent,
      AppButtonVariant.secondary => AppTheme.accent.withValues(alpha: 0.3),
      AppButtonVariant.danger => Colors.transparent,
      AppButtonVariant.ghost => Colors.transparent,
    };

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: fgColor, strokeWidth: 2),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fgColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: size == AppButtonSize.small ? 12 : 24,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Tombol ikon bulat — untuk header actions, dsb
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 18,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final widget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.primaryMid.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (backgroundColor ?? AppTheme.primaryMid).withValues(
              alpha: 0.2,
            ),
          ),
        ),
        child: Icon(icon, size: size, color: color ?? AppTheme.accent),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }
    return widget;
  }
}
