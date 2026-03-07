import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  // ── Filter State ──
  String _activeFilter = 'Hari Ini';

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final _filters = [
    'Hari Ini',
    'Kemarin',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _applyFilter('Hari Ini');
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() => _activeFilter = filter);

    DateTime startDate = today;
    DateTime endDate = today.add(const Duration(days: 1));

    switch (filter) {
      case 'Hari Ini':
        startDate = today;
        endDate = today.add(const Duration(days: 1));
        break;
      case 'Kemarin':
        startDate = today.subtract(const Duration(days: 1));
        endDate = today;
        break;
      case 'Minggu Ini':
        // Monday as start of week
        final weekday = today.weekday;
        startDate = today.subtract(Duration(days: weekday - 1));
        endDate = today.add(const Duration(days: 1));
        break;
      case 'Bulan Ini':
        startDate = DateTime(now.year, now.month, 1);
        endDate = today.add(const Duration(days: 1));
        break;
      case 'Tahun Ini':
        startDate = DateTime(now.year, 1, 1);
        endDate = today.add(const Duration(days: 1));
        break;
      case 'Custom':
        _showDateRangePicker();
        return;
    }

    ref.read(reportProvider.notifier).setDateRange(startDate, endDate);
  }

  Future<void> _showDateRangePicker() async {
    final reportState = ref.read(reportProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: reportState.startDate,
        end: reportState.endDate.subtract(const Duration(days: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final startDate = picked.start;
      final endDate = picked.end.add(const Duration(days: 1));
      ref.read(reportProvider.notifier).setDateRange(startDate, endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Keuangan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analisis laba dan pengeluaran secara detail',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Date Range Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDateRangeLabel(state),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Filter Shortcuts ──
          _buildFilterBar(),

          const SizedBox(height: 24),

          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // ── Summary Cards ──
            _buildSummaryRow(state),

            const SizedBox(height: 24),

            // ── Detail Sections ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Detail
                Expanded(flex: 6, child: _buildTransactionDetail(state)),
                const SizedBox(width: 16),
                // Expense Detail
                Expanded(flex: 4, child: _buildExpenseDetail(state)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  FILTER BAR with shortcuts
  // ═══════════════════════════════════════

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor.withAlpha(128)),
      ),
      child: Row(
        children: _filters.map((filter) {
          final isActive = _activeFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => _applyFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryMid : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryMid.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  SUMMARY CARDS
  // ═══════════════════════════════════════

  Widget _buildSummaryRow(ReportState state) {
    return Row(
      children: [
        // Laba Kotor
        Expanded(
          child: _buildSummaryCard(
            'Laba Kotor',
            _currencyFormat.format(state.totalProfit),
            Icons.trending_up_rounded,
            AppTheme.accentGreen,
            'Dari ${state.transactionCount} transaksi',
          ),
        ),
        const SizedBox(width: 14),
        // Total Pengeluaran
        Expanded(
          child: _buildSummaryCard(
            'Total Pengeluaran',
            _currencyFormat.format(state.totalExpenses),
            Icons.shopping_bag_rounded,
            AppTheme.accentRed,
            '${state.expenses.length} pengeluaran',
          ),
        ),
        const SizedBox(width: 14),
        // Laba Bersih
        Expanded(
          child: _buildSummaryCard(
            'Laba Bersih',
            _currencyFormat.format(state.netProfit),
            Icons.account_balance_wallet_rounded,
            state.netProfit >= 0 ? AppTheme.accent : AppTheme.accentRed,
            'Laba - Pengeluaran',
          ),
        ),
        const SizedBox(width: 14),
        // Jumlah Transaksi
        Expanded(
          child: _buildSummaryCard(
            'Jumlah Transaksi',
            '${state.transactionCount}',
            Icons.receipt_rounded,
            AppTheme.accentOrange,
            _activeFilter,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  TRANSACTION DETAIL TABLE
  // ═══════════════════════════════════════

  Widget _buildTransactionDetail(ReportState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.accent),
              const SizedBox(width: 8),
              const Text(
                'Detail Transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.transactions.length} transaksi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.transactions.isEmpty)
            _buildEmptyState('Tidak ada transaksi pada periode ini')
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1.5),
                  5: FlexColumnWidth(2),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    children: [
                      _th('Tipe'),
                      _th('Nominal'),
                      _th('Admin Bank'),
                      _th('Admin User'),
                      _th('Profit'),
                      _th('Waktu'),
                    ],
                  ),
                  ...state.transactions.map((txn) {
                    final isTransfer = txn.type == 'Transfer';
                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.dividerColor.withAlpha(77),
                          ),
                        ),
                      ),
                      children: [
                        _td(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isTransfer
                                      ? AppTheme.accent
                                      : AppTheme.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                txn.type,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _td(
                          Text(
                            _currencyFormat.format(txn.amount),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        _td(
                          Text(
                            _currencyFormat.format(txn.adminBank),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        _td(
                          Text(
                            _currencyFormat.format(txn.adminUser),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        _td(
                          Text(
                            _currencyFormat.format(txn.profit),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),
                        _td(
                          Text(
                            _formatDateTime(txn.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Total Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withAlpha(15),
                    ),
                    children: [
                      _td(
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _td(
                        Text(
                          _currencyFormat.format(
                            state.transactions.fold(
                              0.0,
                              (sum, t) => sum + t.amount,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _td(
                        Text(
                          _currencyFormat.format(
                            state.transactions.fold(
                              0.0,
                              (sum, t) => sum + t.adminBank,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _td(
                        Text(
                          _currencyFormat.format(
                            state.transactions.fold(
                              0.0,
                              (sum, t) => sum + t.adminUser,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _td(
                        Text(
                          _currencyFormat.format(state.totalProfit),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ),
                      _td(const SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  EXPENSE DETAIL
  // ═══════════════════════════════════════

  Widget _buildExpenseDetail(ReportState state) {
    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (final e in state.expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                size: 18,
                color: AppTheme.accentRed,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pengeluaran per Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.expenses.isEmpty)
            _buildEmptyState('Tidak ada pengeluaran')
          else ...[
            // Category Breakdown
            ...categoryTotals.entries.map((entry) {
              final percentage = state.totalExpenses > 0
                  ? (entry.value / state.totalExpenses * 100)
                  : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(entry.key),
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _currencyFormat.format(entry.value),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentRed.withAlpha(179),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            // Total
            Row(
              children: [
                const Text(
                  'Total Pengeluaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  _currencyFormat.format(state.totalExpenses),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentRed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Net Profit Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    (state.netProfit >= 0
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed)
                        .withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (state.netProfit >= 0
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed)
                          .withAlpha(51),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.netProfit >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: state.netProfit >= 0
                        ? AppTheme.accentGreen
                        : AppTheme.accentRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laba Bersih',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(state.netProfit),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: state.netProfit >= 0
                                ? AppTheme.accentGreen
                                : AppTheme.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _td(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppTheme.textSecondary.withAlpha(77),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    try {
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (_) {
      return date.toString();
    }
  }

  String _getDateRangeLabel(ReportState state) {
    final df = DateFormat('d MMM yyyy', 'id_ID');
    if (_activeFilter == 'Hari Ini') {
      return df.format(state.startDate);
    }
    return '${df.format(state.startDate)} — ${df.format(state.endDate.subtract(const Duration(days: 1)))}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'ATK':
        return Icons.edit_rounded;
      case 'Makan & Minum':
        return Icons.restaurant_rounded;
      case 'Listrik & Internet':
        return Icons.wifi_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}
