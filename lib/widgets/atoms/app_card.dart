import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP CARD — Container/Card Atom
/// ═══════════════════════════════════════
/// Preset styled container untuk menjaga konsistensi di seluruh app.

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useGradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.useGradient = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: useGradient ? null : Theme.of(context).cardColor,
      gradient: useGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).colorScheme.surface,
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? AppTheme.dividerColor.withValues(alpha: 0.5),
      ),
    );

    final container = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: container,
      );
    }

    return container;
  }
}
