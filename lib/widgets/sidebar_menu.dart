import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SidebarMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isAdmin = true,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  bool _isCollapsed = false;
  final String _shopName = 'Klik Agen';

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(Icons.dashboard_rounded, 'Dashboard', 0),
      _MenuItem(Icons.swap_horiz_rounded, 'Kasir (F1)', 1),
      _MenuItem(Icons.receipt_long_rounded, 'Piutang (F6)', 2),
      _MenuItem(Icons.account_balance_wallet_rounded, 'Pengeluaran (F8)', 3),
      _MenuItem(Icons.bar_chart_rounded, 'Laporan', 4),
      _MenuItem(Icons.account_balance_rounded, 'Penyesuaian (F7)', 5),
      if (widget.isAdmin) _MenuItem(Icons.settings_rounded, 'Pengaturan', 6),
    ];

    return ExcludeFocus(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: _isCollapsed ? 80 : 240,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: AppTheme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // ── Header (Logo + Toggle) ──
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 8 : 20,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isCollapsed) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryMid, AppTheme.accent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _shopName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Mini ATM Manager',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        _isCollapsed ? Icons.menu : Icons.menu_open,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: AppTheme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),

            const SizedBox(height: 12),

            // ── Menu Label ──
            if (!_isCollapsed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MENU UTAMA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            if (_isCollapsed) const SizedBox(height: 16),

            // ── Menu Items ──
            ...List.generate(menuItems.length, (i) {
              final item = menuItems[i];
              final isSelected = widget.selectedIndex == item.index;
              return _buildMenuItem(
                item,
                isSelected,
                () => widget.onItemSelected(item.index),
              );
            }),

            const Spacer(),

            // ── Footer ──
            if (!_isCollapsed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMid.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryMid.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'KlikAgen Pro v1.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Tooltip(
            message: _isCollapsed ? item.label : '', // Tooltip when collapsed
            waitDuration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 0 : 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryMid.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryMid.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  _MenuItem(this.icon, this.label, this.index);
}
