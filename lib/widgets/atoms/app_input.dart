import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/thousands_formatter.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP INPUT — TextFormField Atom
/// ═══════════════════════════════════════
/// Styled input dengan label, icon, dan thousands formatter bawaan.

class AppInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? hintText;
  final bool readOnly;
  final bool isCurrency; // Auto-apply thousands formatter
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.prefixIcon,
    this.suffix,
    this.hintText,
    this.readOnly = false,
    this.isCurrency = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (isCurrency) ...[
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      ...?inputFormatters,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          autofocus: autofocus,
          keyboardType: isCurrency ? TextInputType.number : keyboardType,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          inputFormatters: formatters.isNotEmpty ? formatters : null,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: AppTheme.textSecondary)
                : null,
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
