import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/molecules/stat_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/app_date_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/receivable_provider.dart';
import '../providers/adjustment_provider.dart';
import '../providers/report_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dashboardProvider.notifier).loadDashboardData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ringkasan keuangan Anda hari ini',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Balance Cards ──
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.accentRed),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gagal memuat data: ${state.errorMessage}',
                      style: const TextStyle(
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Terjadi masalah pada database yang gagal bermigrasi. Klik tombol di bawah ini untuk mereset seluruh database aplikasi ke kondisi awal.',
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(databaseProvider)
                              .resetAndSeedDatabase();
                          ref.read(appDateProvider.notifier).resetToToday();
                          ref.read(settingsProvider.notifier).refresh();
                          ref
                              .read(dashboardProvider.notifier)
                              .loadDashboardData();
                          ref
                              .read(transactionProvider.notifier)
                              .loadTransactions(DateTime.now());
                          ref.read(expenseProvider.notifier).loadExpenses();
                          ref
                              .read(receivableProvider.notifier)
                              .loadReceivables();
                          ref
                              .read(adjustmentProvider.notifier)
                              .loadAdjustments();
                          ref.read(reportProvider.notifier).loadReport();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal reset: $e')),
                          );
                        }
                      },
                      child: const Text('Reset Database Sekarang'),
                    ),
                  ],
                ),
              )
            else ...[
              // ── Total Aset Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryMid, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryMid.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Aset',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(state.totalAsset),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Saldo Tunai
                  if (state.tunaiWallet != null)
                    SizedBox(
                      width: 280,
                      child: BalanceCard(
                        title: state.tunaiWallet!.name,
                        balance: state.tunaiWallet!.balance,
                        icon: Icons.payments_rounded,
                        iconColor: AppTheme.accentGreen,
                      ),
                    ),
                  // Saldo Digital
                  ...state.digitalWallets.map(
                    (w) => SizedBox(
                      width: 280,
                      child: BalanceCard(
                        title: w.name,
                        balance: w.balance,
                        icon: Icons.account_balance_rounded,
                        iconColor: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Stat Cards Row ──
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Transaksi Hari Ini',
                      value: '${state.todayTxnCount} Transaksi',
                      icon: Icons.swap_horiz_rounded,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Laba Hari Ini',
                      value: _currencyFormat.format(state.todayProfit),
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Total Piutang',
                      value: _currencyFormat.format(state.totalReceivables),
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Pengeluaran Bulan Ini',
                      value: _currencyFormat.format(state.monthlyExpenses),
                      icon: Icons.shopping_bag_rounded,
                      color: AppTheme.accentRed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Recent Transactions Table ──
              _buildRecentTransactions(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(DashboardState state) {
    final recentTransactions = state.recentTransactions;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(navigationIndexProvider.notifier).state = 1;
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Transaction Table ──
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // Waktu
                  1: FlexColumnWidth(1.5), // Bank (New)
                  2: FlexColumnWidth(1.5), // Tipe
                  3: FlexColumnWidth(2), // Nominal
                  4: FlexColumnWidth(1.2), // Adm B
                  5: FlexColumnWidth(1.2), // Adm P
                  6: FlexColumnWidth(1.5), // Profit
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    children: [
                      _tableHeader('Waktu'),
                      _tableHeader('Bank'),
                      _tableHeader('Tipe'),
                      _tableHeader('Nominal'),
                      _tableHeader('Admin Bank'),
                      _tableHeader('Admin Pelanggan'),
                      _tableHeader('Profit'),
                    ],
                  ),
                  // Data Rows
                  ...recentTransactions.map((txn) {
                    final isTransfer = txn.type == 'Transfer';
                    final wallet = state.digitalWallets.firstWhere(
                      (w) => w.id == txn.walletId,
                      orElse: () => state.digitalWallets.first,
                    );
                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      children: [
                        _tableCell(
                          Text(
                            _formatDate(txn.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        _tableCell(
                          Text(
                            wallet.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _tableCell(
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      (isTransfer
                                              ? AppTheme.accent
                                              : AppTheme.accentOrange)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isTransfer
                                      ? Icons.send_rounded
                                      : Icons.money_rounded,
                                  size: 14,
                                  color: isTransfer
                                      ? AppTheme.accent
                                      : AppTheme.accentOrange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                txn.type,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        _tableCell(
                          Text(
                            _currencyFormat.format(txn.amount),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        _tableCell(
                          Text(
                            _currencyFormat.format(txn.adminBank),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        _tableCell(
                          Text(
                            _currencyFormat.format(txn.adminUser),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        _tableCell(
                          Text(
                            _currencyFormat.format(txn.profit),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (_) {
      return date.toString();
    }
  }
}
