import 'package:flutter/material.dart';

/// ═══════════════════════════════════════
///  INFO BOX — Molecule
/// ═══════════════════════════════════════
/// Alert/info row untuk instruksi ("Terima Uang Tunai", dll).

class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const InfoBox({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
