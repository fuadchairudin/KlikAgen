import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ═══════════════════════════════════════
///  APP DROPDOWN — Styled Dropdown Atom
/// ═══════════════════════════════════════
/// Dengan label, focus management, dan consistent styling.

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final FocusNode? focusNode;
  final bool hasFocus;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.focusNode,
    this.hasFocus = false,
  });

  @override
  Widget build(BuildContext context) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasFocus ? AppTheme.accent : AppTheme.dividerColor,
              width: hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              focusNode: focusNode,
              value: value,
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
