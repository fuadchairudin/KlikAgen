import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';

/// Compact horizontal balance strip showing Digital & Tunai balances.
/// Watches [dashboardProvider] so it updates in real-time.
class BalanceStrip extends ConsumerWidget {
  const BalanceStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return SizedBox(
      height: 74,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (dash.tunaiWallet != null)
            Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: _tile(
                context,
                icon: Icons.payments_rounded,
                color: AppTheme.accentGreen,
                label: dash.tunaiWallet!.name,
                value: fmt.format(dash.tunaiWallet!.balance),
              ),
            ),
          ...dash.digitalWallets.map(
            (w) => Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: _tile(
                context,
                icon: Icons.account_balance_rounded,
                color: AppTheme.accent,
                label: w.name,
                value: fmt.format(w.balance),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
