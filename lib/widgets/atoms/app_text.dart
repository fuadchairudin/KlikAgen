import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP TEXT — Typography Atom
/// ═══════════════════════════════════════
/// Preset text styles yang konsisten di seluruh app.

class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.body,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  // ── Named Constructors for convenience ──

  const AppText.heading(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.heading;

  const AppText.subheading(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.subheading;

  const AppText.body(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.body;

  const AppText.caption(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.caption;

  const AppText.label(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.label;

  const AppText.currency(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : style = AppTextStyle.currency;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle(context),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  TextStyle _getStyle(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.onSurface;
    switch (style) {
      case AppTextStyle.heading:
        return TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: color ?? defaultColor,
        );
      case AppTextStyle.subheading:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color ?? defaultColor,
        );
      case AppTextStyle.body:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: color ?? defaultColor,
        );
      case AppTextStyle.caption:
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color ?? AppTheme.textSecondary,
        );
      case AppTextStyle.label:
        return TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: color ?? AppTheme.textSecondary.withValues(alpha: 0.5),
        );
      case AppTextStyle.currency:
        return TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: color ?? defaultColor,
        );
    }
  }
}

enum AppTextStyle { heading, subheading, body, caption, label, currency }
